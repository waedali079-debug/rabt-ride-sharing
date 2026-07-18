const supabase = require('../db');

async function authenticateUser(req, res, next) {
    const token = req.headers.authorization?.replace('Bearer ', '');
    if (!token) {
        return res.status(401).json({ error: 'Missing authentication token' });
    }

    const { data: { user }, error } = await supabase.auth.getUser(token);
    if (error || !user) {
        return res.status(401).json({ error: 'Invalid token' });
    }

    req.user = user;
    next();
}

function requireRole(...roles) {
    return (req, res, next) => {
        const userRole = req.user?.user_metadata?.role;
        if (!roles.includes(userRole)) {
            return res.status(403).json({ error: `Requires one of these roles: ${roles.join(', ')}` });
        }
        next();
    };
}

module.exports = { authenticateUser, requireRole };
