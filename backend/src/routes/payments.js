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

router.get('/:paymentId', authenticateUser, async (req, res) => {
    const { paymentId } = req.params;

    try {
        const { data, error } = await supabase
            .from('rabt_payments')
            .select('*')
            .eq('id', paymentId)
            .single();

        if (error) return res.status(500).json({ error: error.message });

        res.json({ data });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.patch('/:paymentId/status', authenticateUser, async (req, res) => {
    const { paymentId } = req.params;
    const { status } = req.body;

    const validStatuses = ['pending', 'escrowed', 'released', 'refunded', 'failed'];
    if (!validStatuses.includes(status)) {
        return res.status(400).json({ error: 'Invalid status' });
    }

    try {
        const { data, error } = await supabase
            .from('rabt_payments')
            .update({ status })
            .eq('id', paymentId)
            .select()
            .single();

        if (error) return res.status(500).json({ error: error.message });

        res.json({ data, message: 'Payment status updated' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
