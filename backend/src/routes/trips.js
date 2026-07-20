const express = require('express');
const supabase = require('../db');
const { authenticateUser, requireRole } = require('../middleware/auth');

const router = express.Router();

// ──────────────────────────────────────────────
// Helper: Calculate fare server-side from sector tariff
// ──────────────────────────────────────────────
async function calculateFare(sectorId, distanceKm) {
    const { data: sector, error } = await supabase
        .from('rabt_sectors')
        .select('base_fare, per_km_rate')
        .eq('id', sectorId)
        .single();

    if (error || !sector) return null;

    const base = parseFloat(sector.base_fare) || 0;
    const perKm = parseFloat(sector.per_km_rate) || 0;
    const dist = parseFloat(distanceKm) || 0;

    return +(base + perKm * dist).toFixed(2);
}

// ──────────────────────────────────────────────
// List user's trips
// ──────────────────────────────────────────────
router.get('/', authenticateUser, async (req, res) => {
    try {
        const { data, error } = await supabase
            .from('rabt_trips')
            .select('*')
            .or(`customer_id.eq.${req.user.id},driver_id.eq.${req.user.id}`)
            .order('created_at', { ascending: false });

        if (error) return res.status(500).json({ error: error.message });

        res.json({ data: data || [] });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ──────────────────────────────────────────────
// Create trip — fare calculated by server, NOT from client
// ──────────────────────────────────────────────
router.post('/', authenticateUser, async (req, res) => {
    const { sector_id, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng, distance_km } = req.body;

    if (!sector_id || !pickup_lat || !pickup_lng || !dropoff_lat || !dropoff_lng) {
        return res.status(400).json({ error: 'sector_id, pickup and dropoff coordinates are required' });
    }

    try {
        // Calculate fare server-side — never trust client-supplied price
        const fare = await calculateFare(sector_id, distance_km);

        const { data, error } = await supabase
            .from('rabt_trips')
            .insert({
                customer_id: req.user.id,
                sector_id,
                pickup_location: `SRID=4326;POINT(${pickup_lng} ${pickup_lat})`,
                dropoff_location: `SRID=4326;POINT(${dropoff_lng} ${dropoff_lat})`,
                distance_km: distance_km || 0,
                fare: fare,
                status: 'pending',
            })
            .select()
            .single();

        if (error) return res.status(500).json({ error: error.message });

        res.status(201).json({ data, message: 'Trip created' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ──────────────────────────────────────────────
// Get single trip — ownership check
// ──────────────────────────────────────────────
router.get('/:tripId', authenticateUser, async (req, res) => {
    const { tripId } = req.params;

    try {
        const { data, error } = await supabase
            .from('rabt_trips')
            .select('*')
            .eq('id', tripId)
            .single();

        if (error) return res.status(500).json({ error: error.message });

        if (data.customer_id !== req.user.id && data.driver_id !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({ error: 'Not authorized to view this trip' });
        }

        res.json({ data });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ──────────────────────────────────────────────
// Accept trip — ATOMIC conditional update prevents race condition
// ──────────────────────────────────────────────
router.post('/:tripId/accept', authenticateUser, requireRole('driver'), async (req, res) => {
    const { tripId } = req.params;
    const driverId = req.user.id;

    try {
        // 1. Fetch trip data (verify sector and pickup location)
        const { data: trip, error: tripError } = await supabase
            .from('rabt_trips')
            .select('sector_id, pickup_location, status')
            .eq('id', tripId)
            .single();

        if (tripError || !trip) {
            return res.status(404).json({ error: 'Trip not found' });
        }

        if (trip.status !== 'pending') {
            return res.status(409).json({ error: 'Trip is no longer available.' });
        }

        // 2. Verify driver is the nearest matching driver via PostGIS RPC
        const { data: matchedDriverId, error: matchError } = await supabase
            .rpc('match_nearest_driver', {
                p_pickup: trip.pickup_location,
                p_sector_id: trip.sector_id
            });

        if (matchError) {
            console.error('[Trips] match_nearest_driver error:', matchError);
            return res.status(500).json({ error: 'Failed to verify driver match' });
        }

        if (!matchedDriverId || matchedDriverId !== driverId) {
            return res.status(403).json({
                error: 'Forbidden: You are not the nearest matching driver for this sector.'
            });
        }

        // 3. Atomic update: only succeeds if trip is still 'pending'
        const { data: updatedTrip, error } = await supabase
            .from('rabt_trips')
            .update({
                driver_id: driverId,
                status: 'accepted',
                accepted_at: new Date().toISOString(),
            })
            .eq('id', tripId)
            .eq('status', 'pending')
            .select()
            .single();

        if (error || !updatedTrip) {
            return res.status(409).json({
                error: 'Trip is no longer available or has been accepted by another driver.',
            });
        }

        res.json({ message: 'Trip accepted successfully', trip: updatedTrip });
    } catch (err) {
        // Unique index violation — driver already has an active trip
        if (err.code === '23505') {
            return res.status(409).json({
                error: 'You already have an active trip. Please complete it first.',
            });
        }
        res.status(500).json({ error: 'Internal server error' });
    }
});

// ──────────────────────────────────────────────
// Complete trip
// ──────────────────────────────────────────────
router.post('/:tripId/complete', authenticateUser, requireRole('driver'), async (req, res) => {
    const { tripId } = req.params;

    try {
        const { error } = await supabase
            .from('rabt_trips')
            .update({ status: 'completed', completed_at: new Date().toISOString() })
            .eq('id', tripId)
            .eq('driver_id', req.user.id);

        if (error) return res.status(500).json({ error: error.message });

        res.json({ message: 'Trip completed' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ──────────────────────────────────────────────
// Cancel trip — customer or driver or admin
// ──────────────────────────────────────────────
router.post('/:tripId/cancel', authenticateUser, async (req, res) => {
    const { tripId } = req.params;

    try {
        const { data: trip, error: tripError } = await supabase
            .from('rabt_trips')
            .select('customer_id, driver_id, status')
            .eq('id', tripId)
            .single();

        if (tripError) return res.status(500).json({ error: tripError.message });

        if (trip.customer_id !== req.user.id && trip.driver_id !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({ error: 'Not authorized to cancel this trip' });
        }

        if (trip.status === 'completed' || trip.status === 'cancelled') {
            return res.status(400).json({ error: 'Trip already finished' });
        }

        const { error } = await supabase
            .from('rabt_trips')
            .update({ status: 'cancelled' })
            .eq('id', tripId);

        if (error) return res.status(500).json({ error: error.message });

        res.json({ message: 'Trip cancelled' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
