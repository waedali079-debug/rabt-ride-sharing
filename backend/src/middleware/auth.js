const supabase = require('../db');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'rabt_jwt_secret_v31_production';

// Verify our custom JWT (NOT Supabase token) - ensures role comes from DB
async function authenticateUser(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Access denied. No token provided.' });
    }

    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        req.user = {
            id: decoded.id,
            role: decoded.role,
            phone: decoded.phone,
            full_name: decoded.full_name || ''
        };
        next();
    } catch (err) {
        return res.status(403).json({ error: 'Invalid or expired token.' });
    }
}

function requireRole(...roles) {
    return (req, res, next) => {
        const userRole = req.user?.role;
        if (!roles.includes(userRole)) {
            return res.status(403).json({ error: `Requires one of these roles: ${roles.join(', ')}` });
        }
        next();
    };
}

module.exports = { authenticateUser, requireRole };
