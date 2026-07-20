const express = require('express');
const supabase = require('../db');
const { authenticateUser, requireRole } = require('../middleware/auth');

const router = express.Router();

// Get current user profile
router.get('/profile', authenticateUser, async (req, res) => {
    try {
        const { data, error } = await supabase
            .from('rabt_users')
            .select('*')
            .eq('id', req.user.id)
            .single();

        if (error) return res.status(500).json({ error: error.message });

        res.json({
            data: {
                id: data.id,
                phone_number: data.phone_number,
                full_name: data.full_name,
                email: data.email,
                role: data.role,
            },
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.patch('/:userId/role', authenticateUser, requireRole('admin', 'super_admin'), async (req, res) => {
    const { userId } = req.params;
    const { role } = req.body;

    const validRoles = ['customer', 'driver', 'admin', 'super_admin'];
    if (!validRoles.includes(role)) {
        return res.status(400).json({ error: 'Invalid role' });
    }

    try {
        const { error } = await supabase
            .from('rabt_users')
            .update({ role })
            .eq('id', userId);

        if (error) return res.status(500).json({ error: error.message });

        res.json({ message: 'Role updated successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
