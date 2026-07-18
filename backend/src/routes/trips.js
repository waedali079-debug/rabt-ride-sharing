const express = require('express');
const supabase = require('../db');
const { authenticateUser, requireRole } = require('../middleware/auth');

const router = express.Router();

router.get('/', authenticateUser, async (req, res) => {
    try {
        const { data, error } = await supabase
            .from('rabt_trips')
            .select('*')
            .or(`customer_id.eq.${req.user.id},driver_id.eq.${req.user.id}`)
            .order('created_at', { ascending: false });

        if (error) return res.status(500).json({ error: error.message });

        res.json(data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.post('/', authenticateUser, async (req, res) => {
    const { sector_code, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng, estimated_price, estimated_duration_minutes } = req.body;

    if (!sector_code || !pickup_lat || !pickup_lng || !dropoff_lat || !dropoff_lng) {
        return res.status(400).json({ error: 'sector_code, pickup and dropoff coordinates are required' });
    }

    try {
        const { data, error } = await supabase
            .from('rabt_trips')
            .insert({
                customer_id: req.user.id,
                sector_code,
                pickup_location: `SRID=4326;POINT(${pickup_lng} ${pickup_lat})`,
                dropoff_location: `SRID=4326;POINT(${dropoff_lng} ${dropoff_lat})`,
                estimated_price: estimated_price || 0,
                estimated_duration_minutes: estimated_duration_minutes || 30,
                status: 'requested',
            })
            .select()
            .single();

        if (error) return res.status(500).json({ error: error.message });

        res.status(201).json({ message: 'Trip created', trip: data });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.get('/:tripId', authenticateUser, async (req, res) => {
    const { tripId } = req.params;

    try {
        const { data, error } = await supabase
            .from('rabt_trips')
            .select('*')
            .eq('id', tripId)
            .single();

        if (error) return res.status(500).json({ error: error.message });

        if (data.customer_id !== req.user.id && data.driver_id !== req.user.id) {
            return res.status(403).json({ error: 'Not authorized to view this trip' });
        }

        res.json(data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.post('/:tripId/accept', authenticateUser, requireRole('driver'), async (req, res) => {
    const { tripId } = req.params;

    try {
        const { data: trip, error: tripError } = await supabase
            .from('rabt_trips')
            .select('*')
            .eq('id', tripId)
            .single();

        if (tripError) return res.status(500).json({ error: tripError.message });

        if (trip.status !== 'requested') {
            return res.status(400).json({ error: 'Trip is not available for acceptance' });
        }

        const { error } = await supabase
            .from('rabt_trips')
            .update({
                driver_id: req.user.id,
                status: 'accepted',
                accepted_at: new Date().toISOString(),
            })
            .eq('id', tripId);

        if (error) return res.status(500).json({ error: error.message });

        res.json({ message: 'Trip accepted' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.post('/:tripId/complete', authenticateUser, requireRole('driver'), async (req, res) => {
    const { tripId } = req.params;
    const { final_price, actual_duration_minutes } = req.body;

    try {
        const { error } = await supabase
            .from('rabt_trips')
            .update({
                status: 'completed',
                ended_at: new Date().toISOString(),
                final_price: final_price,
                actual_duration_minutes: actual_duration_minutes,
            })
            .eq('id', tripId)
            .eq('driver_id', req.user.id);

        if (error) return res.status(500).json({ error: error.message });

        res.json({ message: 'Trip completed' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.post('/:tripId/cancel', authenticateUser, async (req, res) => {
    const { tripId } = req.params;

    try {
        const { data: trip, error: tripError } = await supabase
            .from('rabt_trips')
            .select('customer_id, driver_id')
            .eq('id', tripId)
            .single();

        if (tripError) return res.status(500).json({ error: tripError.message });

        if (trip.customer_id !== req.user.id && trip.driver_id !== req.user.id) {
            return res.status(403).json({ error: 'Not authorized to cancel this trip' });
        }

        const { error } = await supabase
            .from('rabt_trips')
            .update({ status: 'canceled', ended_at: new Date().toISOString() })
            .eq('id', tripId);

        if (error) return res.status(500).json({ error: error.message });

        res.json({ message: 'Trip canceled' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
