const express = require('express');
const supabase = require('../db');
const { authenticateUser } = require('../middleware/auth');

const router = express.Router();

router.post('/', authenticateUser, async (req, res) => {
    const { trip_id, amount } = req.body;

    if (!trip_id || !amount) {
        return res.status(400).json({ error: 'trip_id and amount are required' });
    }

    try {
        const { data: trip, error: tripError } = await supabase
            .from('rabt_trips')
            .select('customer_id')
            .eq('id', trip_id)
            .single();

        if (tripError) return res.status(500).json({ error: tripError.message });

        if (trip.customer_id !== req.user.id) {
            return res.status(403).json({ error: 'Not authorized to create payment for this trip' });
        }

        const { data, error } = await supabase
            .from('rabt_payments')
            .insert({
                trip_id,
                amount,
                status: 'pending',
            })
            .select()
            .single();

        if (error) return res.status(500).json({ error: error.message });

        res.status(201).json({ data, message: 'Payment created' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get a payment — owner (customer/driver) or admin only
router.get('/:paymentId', authenticateUser, async (req, res) => {
    const { paymentId } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    try {
        const { data: payment, error } = await supabase
            .from('rabt_payments')
            .select('id, amount, status, trip_id, rabt_trips(customer_id, driver_id)')
            .eq('id', paymentId)
            .single();

        if (error || !payment) return res.status(404).json({ error: 'Payment not found' });

        const trip = payment.rabt_trips;
        const isOwner = userRole === 'admin' ||
                        userRole === 'super_admin' ||
                        trip?.customer_id === userId ||
                        trip?.driver_id === userId;

        if (!isOwner) {
            return res.status(403).json({ error: 'Forbidden: You do not have access to this payment' });
        }

        res.json({ data: payment });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Update payment status — assigned driver or admin only
router.patch('/:paymentId/status', authenticateUser, async (req, res) => {
    const { paymentId } = req.params;
    const { status } = req.body;
    const userId = req.user.id;
    const userRole = req.user.role;

    const validStatuses = ['pending', 'escrowed', 'released', 'refunded', 'failed'];
    if (!validStatuses.includes(status)) {
        return res.status(400).json({ error: 'Invalid status' });
    }

    try {
        const { data: payment, error } = await supabase
            .from('rabt_payments')
            .select('rabt_trips(driver_id)')
            .eq('id', paymentId)
            .single();

        if (error || !payment) return res.status(404).json({ error: 'Payment not found' });

        const isAuthorized = userRole === 'admin' ||
                             userRole === 'super_admin' ||
                             payment.rabt_trips?.driver_id === userId;

        if (!isAuthorized) {
            return res.status(403).json({ error: 'Forbidden: Only assigned driver or admin can update payment status' });
        }

        const { data: updated, error: updateError } = await supabase
            .from('rabt_payments')
            .update({ status })
            .eq('id', paymentId)
            .select()
            .single();

        if (updateError) return res.status(500).json({ error: updateError.message });

        res.json({ data: updated, message: 'Payment status updated' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
