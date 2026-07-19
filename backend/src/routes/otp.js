const express = require('express');
const supabase = require('../db');
const { sendOtp } = require('../services/infobip');

const router = express.Router();

// Generate random 6-digit OTP
function generateOtp() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

// Send OTP
router.post('/send', async (req, res) => {
    const { phone, purpose = 'login' } = req.body;

    if (!phone) {
        return res.status(400).json({ error: 'Phone number is required' });
    }

    try {
        // Rate limiting: max 3 OTPs per phone per 10 minutes
        const { count } = await supabase
            .from('rabt_otps')
            .select('*', { count: 'exact', head: true })
            .eq('phone_number', phone)
            .eq('purpose', purpose)
            .eq('is_used', false)
            .gte('created_at', new Date(Date.now() - 10 * 60 * 1000).toISOString());

        if (count >= 3) {
            return res.status(429).json({ 
                error: 'Too many requests. Please wait before requesting another OTP.' 
            });
        }

        // Generate OTP
        const otpCode = generateOtp();
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

        // Store OTP in database
        const { error: dbError } = await supabase
            .from('rabt_otps')
            .insert({
                phone_number: phone,
                otp_code: otpCode,
                purpose,
                expires_at: expiresAt.toISOString(),
            });

        if (dbError) {
            console.error('DB Error:', dbError);
            return res.status(500).json({ error: 'Failed to generate OTP' });
        }

        // Send OTP via Infobip
        await sendOtp(phone, otpCode);

        res.json({ 
            message: 'OTP sent successfully',
            expiresIn: 300 // 5 minutes in seconds
        });
    } catch (error) {
        console.error('Send OTP error:', error);
        res.status(500).json({ error: error.message || 'Failed to send OTP' });
    }
});

// Verify OTP
router.post('/verify', async (req, res) => {
    const { phone, otp, purpose = 'login' } = req.body;

    if (!phone || !otp) {
        return res.status(400).json({ error: 'Phone and OTP are required' });
    }

    try {
        // Find valid OTP
        const { data: otpRecord, error: findError } = await supabase
            .from('rabt_otps')
            .select('*')
            .eq('phone_number', phone)
            .eq('otp_code', otp)
            .eq('purpose', purpose)
            .eq('is_used', false)
            .gt('expires_at', new Date().toISOString())
            .order('created_at', { ascending: false })
            .limit(1)
            .single();

        if (findError || !otpRecord) {
            return res.status(400).json({ error: 'Invalid or expired OTP' });
        }

        // Mark OTP as used
        await supabase
            .from('rabt_otps')
            .update({ is_used: true })
            .eq('id', otpRecord.id);

        // Check if user exists
        const { data: existingUser } = await supabase
            .from('rabt_users')
            .select('*')
            .eq('phone_number', phone)
            .single();

        let userId;
        let isNewUser = false;

        if (existingUser) {
            userId = existingUser.id;
        } else {
            // Create new user via Supabase Auth
            const { data: authData, error: authError } = await supabase.auth.signUp({
                email: `${phone}@rabt.app`,
                phone,
                password: Math.random().toString(36).slice(-8),
                options: { 
                    data: { 
                        role: 'customer',
                        phone_number: phone 
                    } 
                },
            });

            if (authError) {
                console.error('Auth signup error:', authError);
                return res.status(500).json({ error: 'Failed to create user' });
            }

            userId = authData.user.id;
            isNewUser = true;

            // Create user in our database
            const { error: dbError } = await supabase
                .from('rabt_users')
                .insert({
                    id: userId,
                    phone_number: phone,
                    role: 'customer',
                    full_name: '',
                });

            if (dbError) {
                console.error('DB insert error:', dbError);
            }
        }

        // Sign in with Supabase to get session
        const { data: signInData, error: signInError } = await supabase.auth.signInWithOtp({
            phone,
        });

        // Since we already verified OTP, we need to get a session differently
        // Use the admin API to create a session or use magic link
        // For simplicity, let's use the existing Supabase session management
        
        // Get user data
        const { data: userData } = await supabase
            .from('rabt_users')
            .select('*')
            .eq('id', userId)
            .single();

        res.json({
            data: {
                id: userId,
                phone_number: userData?.phone_number || phone,
                full_name: userData?.full_name || '',
                role: userData?.role || 'customer',
                is_new_user: isNewUser,
            },
            message: isNewUser ? 'Account created successfully' : 'Login successful',
        });
    } catch (error) {
        console.error('Verify OTP error:', error);
        res.status(500).json({ error: error.message || 'Failed to verify OTP' });
    }
});

module.exports = router;
