const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
    cors: {
        origin: process.env.CLIENT_URL || "*",
        methods: ["GET", "POST"]
    },
    path: '/tracking'
});

const PORT = process.env.TRACKING_PORT || 8080;
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
    console.error('FATAL ERROR: JWT_SECRET is missing in environment variables.');
    process.exit(1);
}

// ==========================================================
// MIDDLEWARE: AUTHENTICATION
// ==========================================================
io.use((socket, next) => {
    const token = socket.handshake.auth.token;
    if (!token) return next(new Error('Authentication error: Token missing'));

    try {
        const payload = jwt.verify(token, JWT_SECRET);
        socket.userId = payload.id;
        socket.role = payload.role;
        next();
    } catch (err) {
        return next(new Error('Authentication error: Invalid token'));
    }
});

// ==========================================================
// RATE LIMITING & VALIDATION
// ==========================================================
const locationUpdateLimits = new Map();
const RATE_LIMIT_MS = 2000;

function validateLocationPayload(data) {
    if (!data || typeof data !== 'object') return false;
    if (typeof data.tripId !== 'string' || data.tripId.length === 0) return false;
    if (typeof data.lat !== 'number' || data.lat < -90 || data.lat > 90) return false;
    if (typeof data.lng !== 'number' || data.lng < -180 || data.lng > 180) return false;
    return true;
}

// ==========================================================
// CONNECTION HANDLER
// ==========================================================
io.on('connection', (socket) => {
    console.log(`[Tracking] Connected: ${socket.userId} (${socket.role})`);

    socket.on('join_trip', (tripId) => {
        if (typeof tripId !== 'string' || tripId.length === 0) return;
        socket.join(`trip_${tripId}`);
    });

    socket.on('update_location', (data) => {
        if (socket.role !== 'driver') return;

        const now = Date.now();
        const lastUpdate = locationUpdateLimits.get(socket.id) || 0;
        if (now - lastUpdate < RATE_LIMIT_MS) return;
        locationUpdateLimits.set(socket.id, now);

        if (!validateLocationPayload(data)) {
            socket.emit('error', { message: 'Invalid location payload' });
            return;
        }

        io.to(`trip_${data.tripId}`).emit('location_update', {
            tripId: data.tripId,
            driverId: socket.userId,
            lat: data.lat,
            lng: data.lng,
            timestamp: now
        });
    });

    socket.on('update_status', (data) => {
        if (socket.role !== 'driver' || !data.tripId || !data.status) return;
        
        const validStatuses = ['accepted', 'arrived', 'in_progress', 'completed', 'cancelled'];
        if (!validStatuses.includes(data.status)) return;

        io.to(`trip_${data.tripId}`).emit('status_update', {
            tripId: data.tripId,
            status: data.status,
            timestamp: Date.now()
        });
    });

    socket.on('disconnect', () => {
        locationUpdateLimits.delete(socket.id);
    });
});

server.listen(PORT, () => {
    console.log(`[Tracking] WebSocket Server running on port ${PORT}`);
});
