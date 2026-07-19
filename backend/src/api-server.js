require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const jwt = require('jsonwebtoken');
const { createClient } = require('@supabase/supabase-js');

const app = express();
const PORT = process.env.PORT || 8080;

// Security middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// Import routes
const routingRouter = require('./routes/routing');

// ==========================================================
// SUPABASE CLIENT (Server-Side Only - Service Role Key)
// ==========================================================
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SECRET_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
    console.error('Missing SUPABASE_URL or SUPABASE_SECRET_KEY');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

// ==========================================================
// JWT CONFIGURATION
// ==========================================================
const JWT_SECRET = process.env.JWT_SECRET || 'rabt_jwt_secret_v31_production';
const JWT_EXPIRES_IN = '7d';

// ==========================================================
// MIDDLEWARE: JWT VERIFICATION
// ==========================================================
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Access denied. No token provided.' });
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ error: 'Invalid or expired token.' });
        }
        req.user = user;
        next();
    });
};

// Optional auth - doesn't fail if no token
const optionalAuth = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (token) {
        jwt.verify(token, JWT_SECRET, (err, user) => {
            if (!err) {
                req.user = user;
            }
        });
    }
    next();
};

// ==========================================================
// INFOBIP SMS SERVICE
// ==========================================================
const INFOBIP_API_KEY = process.env.INFOBIP_API_KEY;
const INFOBIP_BASE_URL = process.env.INFOBIP_BASE_URL;
const INFOBIP_SENDER_ID = process.env.INFOBIP_SENDER_ID || 'RABT';

async function sendSmsViaInfobip(phone, message) {
    if (!INFOBIP_API_KEY || !INFOBIP_BASE_URL) {
        throw new Error('Infobip configuration missing');
    }

    const formattedPhone = phone.startsWith('+') ? phone.substring(1) : phone;

    const response = await fetch(`${INFOBIP_BASE_URL}/sms/2/text/advanced`, {
        method: 'POST',
        headers: {
            'Authorization': `App ${INFOBIP_API_KEY}`,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        },
        body: JSON.stringify({
            messages: [{
                from: INFOBIP_SENDER_ID,
                destinations: [{ to: formattedPhone }],
                text: message,
            }],
        }),
    });

    const data = await response.json();
    
    if (!response.ok) {
        console.error('Infobip error:', data);
        throw new Error(data.messages?.[0]?.status?.description || 'Failed to send SMS');
    }

    return { success: true, messageId: data.messages?.[0]?.messageId };
}

// Generate random 6-digit OTP
function generateOtp() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

// Sanitize phone number to E.164 format
function sanitizePhone(phone) {
    let cleanPhone = phone.trim().replace(/\s/g, '');
    
    if (!cleanPhone.startsWith('+')) {
        cleanPhone = '+' + cleanPhone;
    }
    
    // Fix Jordan numbers: +962962... -> +962...
    if (cleanPhone.startsWith('+962962')) {
        cleanPhone = '+962' + cleanPhone.substring(7);
    }
    
    // Fix +9620... -> +962...
    if (cleanPhone.startsWith('+9620')) {
        cleanPhone = '+962' + cleanPhone.substring(5);
    }
    
    return cleanPhone;
}

// ==========================================================
// AUTH ENDPOINTS
// ==========================================================

// Send OTP
app.post('/api/v1/auth/send-otp', async (req, res) => {
    const { phone } = req.body;

    if (!phone) {
        return res.status(400).json({ error: 'Phone number is required' });
    }

    const sanitizedPhone = sanitizePhone(phone);

    try {
        // Rate limiting: max 3 OTPs per phone per 10 minutes
        const { count } = await supabase
            .from('rabt_otps')
            .select('*', { count: 'exact', head: true })
            .eq('phone_number', sanitizedPhone)
            .eq('purpose', 'login')
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
                phone_number: sanitizedPhone,
                otp_code: otpCode,
                purpose: 'login',
                expires_at: expiresAt.toISOString(),
            });

        if (dbError) {
            console.error('DB Error:', dbError);
            return res.status(500).json({ error: 'Failed to generate OTP' });
        }

        // Send OTP via Infobip
        const otpMessage = `رمز التحقق من ربط: ${otpCode}\nصالح لمدة 5 دقائق.\nYour RABT verification code: ${otpCode}`;
        await sendSmsViaInfobip(sanitizedPhone, otpMessage);

        res.json({ 
            message: 'OTP sent successfully',
            expiresIn: 300 // 5 minutes in seconds
        });
    } catch (error) {
        console.error('Send OTP error:', error);
        res.status(500).json({ error: error.message || 'Failed to send OTP' });
    }
});

// Verify OTP and issue JWT
app.post('/api/v1/auth/verify-otp', async (req, res) => {
    const { phone, otp } = req.body;

    if (!phone || !otp) {
        return res.status(400).json({ error: 'Phone and OTP are required' });
    }

    const sanitizedPhone = sanitizePhone(phone);

    try {
        // Find valid OTP
        const { data: otpRecord, error: findError } = await supabase
            .from('rabt_otps')
            .select('*')
            .eq('phone_number', sanitizedPhone)
            .eq('otp_code', otp)
            .eq('purpose', 'login')
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
            .eq('phone_number', sanitizedPhone)
            .single();

        let userId;
        let isNewUser = false;

        if (existingUser) {
            userId = existingUser.id;
        } else {
            // Create new user via Supabase Auth
            const { data: authData, error: authError } = await supabase.auth.signUp({
                email: `${sanitizedPhone}@rabt.app`,
                phone: sanitizedPhone,
                password: Math.random().toString(36).slice(-8),
                options: { 
                    data: { 
                        role: 'customer',
                        phone_number: sanitizedPhone 
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
                    phone_number: sanitizedPhone,
                    role: 'customer',
                    full_name: '',
                });

            if (dbError) {
                console.error('DB insert error:', dbError);
            }
        }

        // Get user data
        const { data: userData } = await supabase
            .from('rabt_users')
            .select('*')
            .eq('id', userId)
            .single();

        // Create our own JWT token
        const appToken = jwt.sign(
            { 
                id: userId, 
                role: userData?.role || 'customer', 
                phone: sanitizedPhone,
                full_name: userData?.full_name || ''
            },
            JWT_SECRET,
            { expiresIn: JWT_EXPIRES_IN }
        );

        res.json({
            token: appToken,
            user: {
                id: userId,
                phone_number: userData?.phone_number || sanitizedPhone,
                full_name: userData?.full_name || '',
                role: userData?.role || 'customer',
            },
            is_new_user: isNewUser,
            message: isNewUser ? 'Account created successfully' : 'Login successful',
        });
    } catch (error) {
        console.error('Verify OTP error:', error);
        res.status(500).json({ error: error.message || 'Failed to verify OTP' });
    }
});

// ==========================================================
// SECTORS ENDPOINTS
// ==========================================================

// Get all sectors (Public - no auth required)
app.get('/api/v1/sectors', async (req, res) => {
    try {
        const { data, error } = await supabase
            .from('rabt_sectors')
            .select('*');

        if (error) return res.status(400).json({ error: error.message });
        res.json(data);
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Get sector by code (Public - no auth required)
app.get('/api/v1/sectors/:code', async (req, res) => {
    const { code } = req.params;
    
    try {
        const { data, error } = await supabase
            .from('rabt_sectors')
            .select('*')
            .eq('sector_code', code)
            .single();

        if (error) return res.status(404).json({ error: 'Sector not found' });
        res.json(data);
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});

// ==========================================================
// TRIPS ENDPOINTS
// ==========================================================

// Request a new trip
app.post('/api/v1/trips/request', authenticateToken, async (req, res) => {
    const { sectorId, pickupLat, pickupLng } = req.body;
    const customerId = req.user.id;

    try {
        // 1. Create the trip
        const { data: tripData, error: tripError } = await supabase
            .from('rabt_trips')
            .insert({
                customer_id: customerId,
                sector_id: sectorId,
                pickup_location: `POINT(${pickupLng} ${pickupLat})`,
                status: 'pending'
            })
            .select('id')
            .single();

        if (tripError) return res.status(400).json({ error: tripError.message });

        const tripId = tripData.id;

        // 2. Match nearest driver
        const { data: driverId, error: rpcError } = await supabase
            .rpc('match_nearest_driver', {
                p_pickup: `POINT(${pickupLng} ${pickupLat})`,
                p_sector_id: sectorId
            });

        if (rpcError) return res.status(500).json({ error: 'Failed to match driver' });

        if (driverId) {
            // 3. Update trip with driver
            await supabase
                .from('rabt_trips')
                .update({
                    driver_id: driverId,
                    status: 'accepted',
                    accepted_at: new Date().toISOString()
                })
                .eq('id', tripId);

            res.json({ success: true, trip_id: tripId, driver_id: driverId });
        } else {
            await supabase.from('rabt_trips').update({ status: 'cancelled' }).eq('id', tripId);
            res.json({ success: false, message: 'No drivers available' });
        }
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Get user's trips
app.get('/api/v1/trips', authenticateToken, async (req, res) => {
    const userId = req.user.id;
    
    try {
        const { data, error } = await supabase
            .from('rabt_trips')
            .select('*, rabt_sectors(name, code, icon_name)')
            .or(`customer_id.eq.${userId},driver_id.eq.${userId}`)
            .order('created_at', { ascending: false })
            .limit(20);

        if (error) return res.status(400).json({ error: error.message });
        res.json(data);
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});

// ==========================================================
// USER PROFILE ENDPOINTS
// ==========================================================

// Get current user profile
app.get('/api/v1/user/profile', authenticateToken, async (req, res) => {
    const userId = req.user.id;
    
    try {
        const { data, error } = await supabase
            .from('rabt_users')
            .select('id, phone_number, full_name, role, is_active, created_at')
            .eq('id', userId)
            .single();

        if (error) return res.status(404).json({ error: 'User not found' });
        res.json(data);
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Update user profile
app.put('/api/v1/user/profile', authenticateToken, async (req, res) => {
    const userId = req.user.id;
    const { full_name } = req.body;
    
    try {
        const { data, error } = await supabase
            .from('rabt_users')
            .update({ full_name })
            .eq('id', userId)
            .select('id, phone_number, full_name, role')
            .single();

        if (error) return res.status(400).json({ error: error.message });
        res.json(data);
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});

// ==========================================================
// ROUTING ENDPOINTS (GraphHopper)
// ==========================================================
app.use('/api/v1/routing', authenticateToken, routingRouter);

// ==========================================================
// HEALTH CHECK
// ==========================================================
app.get('/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        service: 'Rabt API Server',
        timestamp: new Date().toISOString() 
    });
});

// ==========================================================
// ERROR HANDLING
// ==========================================================
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

// ==========================================================
// START SERVER
// ==========================================================
app.listen(PORT, () => {
    console.log(`[Rabt API] Server running on port ${PORT}`);
    console.log(`[Rabt API] Health check: http://localhost:${PORT}/health`);
});
