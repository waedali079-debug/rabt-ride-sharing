const express = require('express');
const supabase = require('../db');
const { encrypt } = require('../encryption');
const { authenticateUser, requireRole } = require('../middleware/auth');

const router = express.Router();

router.post('/register', async (req, res) => {
    const { phone, email, full_name, national_id, password, role = 'customer' } = req.body;

    if (!phone || !full_name) {
        return res.status(400).json({ error: 'Phone and full_name are required' });
    }

    try {
        const nationalIdEncrypted = national_id ? encrypt(national_id) : null;
        const userPassword = password || (national_id ? national_id.slice(-6) : Math.random().toString(36).slice(-8));

        const { data: authData, error: authError } = await supabase.auth.signUp({
            email: email || `${phone}@rabt.app`,
            phone,
            password: userPassword,
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
                email: email || `${phone}@rabt.app`,
                role,
                national_id_encrypted: nationalIdEncrypted ? Buffer.from(nationalIdEncrypted) : null,
            });

        if (dbError) return res.status(500).json({ error: dbError.message });

        res.status(201).json({
            data: {
                id: userId,
                phone_number: phone,
                full_name,
                role,
                token: authData.session?.access_token,
            },
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
        // If password provided, try email/password login
        if (password) {
            const { data, error } = await supabase.auth.signInWithPassword({
                email: `${phone}@rabt.app`,
                password: password,
            });

            if (error) return res.status(400).json({ error: error.message });

            const { data: userData } = await supabase
                .from('rabt_users')
                .select('*')
                .eq('id', data.user.id)
                .single();

            res.json({
                data: {
                    id: data.user.id,
                    phone_number: userData?.phone_number || phone,
                    full_name: userData?.full_name || '',
                    role: userData?.role || 'customer',
                    token: data.session.access_token,
                },
            });
        } else {
            // Send OTP
            const { data, error } = await supabase.auth.signInWithOtp({ phone });

            if (error) return res.status(400).json({ error: error.message });

            res.json({ message: 'OTP sent to your phone' });
        }
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.post('/verify-otp', async (req, res) => {
    const { phone, token } = req.body;

    if (!phone || !token) {
        return res.status(400).json({ error: 'Phone and token are required' });
    }

    try {
        const { data, error } = await supabase.auth.verifyOtp({
            phone,
            token,
            type: 'sms',
        });

        if (error) return res.status(400).json({ error: error.message });

        const { data: userData } = await supabase
            .from('rabt_users')
            .select('*')
            .eq('id', data.user.id)
            .single();

        res.json({
            data: {
                id: data.user.id,
                phone_number: userData?.phone_number || phone,
                full_name: userData?.full_name || '',
                role: userData?.role || 'customer',
                token: data.session.access_token,
            },
        });
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
