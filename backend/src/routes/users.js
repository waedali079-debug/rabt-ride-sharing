const express = require('express');
const supabase = require('../db');
const { encrypt } = require('../encryption');
const { authenticateUser, requireRole } = require('../middleware/auth');

const router = express.Router();

router.post('/register', async (req, res) => {
    const { phone, email, full_name, national_id, role = 'customer' } = req.body;

    if (!phone || !national_id || !full_name) {
        return res.status(400).json({ error: 'Phone, full_name, and national_id are required' });
    }

    try {
        const nationalIdEncrypted = encrypt(national_id);

        const { data: authData, error: authError } = await supabase.auth.signUp({
            email,
            phone,
            password: national_id.slice(-6),
            options: { data: { role, full_name } },
        });

        if (authError) return res.status(400).json({ error: authError.message });

        const userId = authData.user.id;

        const { error: dbError } = await supabase
            .from('rabt_users')
            .insert({
                id: userId,
                phone_number: phone,
                full_name,
                email,
                role,
                national_id_encrypted: Buffer.from(nationalIdEncrypted),
            });

        if (dbError) return res.status(500).json({ error: dbError.message });

        res.status(201).json({
            message: 'User registered successfully',
            user_id: userId,
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.post('/login', async (req, res) => {
    const { phone, password } = req.body;

    if (!phone) {
        return res.status(400).json({ error: 'Phone is required' });
    }

    try {
        const { data, error } = await supabase.auth.signInWithOtp({ phone });

        if (error) return res.status(400).json({ error: error.message });

        res.json({ message: 'OTP sent to your phone' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.get('/profile', authenticateUser, async (req, res) => {
    try {
        const { data, error } = await supabase
            .from('rabt_users')
            .select('*')
            .eq('id', req.user.id)
            .single();

        if (error) return res.status(500).json({ error: error.message });

        res.json(data);
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
