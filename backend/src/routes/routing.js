const express = require('express');
const routingService = require('../services/routing');

const router = express.Router();

// Health check for routing service
router.get('/health', async (req, res) => {
    const isHealthy = await routingService.healthCheck();
    
    if (isHealthy) {
        res.json({ 
            status: 'OK', 
            service: 'GraphHopper',
            url: process.env.GRAPHHOPPER_URL || 'http://localhost:8989'
        });
    } else {
        res.status(503).json({ 
            status: 'ERROR', 
            message: 'GraphHopper service is not available' 
        });
    }
});

// Get route between two points
router.get('/route', async (req, res) => {
    const { startLat, startLng, endLat, endLng, profile = 'car' } = req.query;

    if (!startLat || !startLng || !endLat || !endLng) {
        return res.status(400).json({ 
            error: 'Missing required parameters: startLat, startLng, endLat, endLng' 
        });
    }

    try {
        const route = await routingService.getRoute(
            parseFloat(startLat),
            parseFloat(startLng),
            parseFloat(endLat),
            parseFloat(endLng),
            profile
        );

        res.json(route);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get trip route with fare estimation
router.post('/trip-route', async (req, res) => {
    const { pickup, dropoff, sectorCode } = req.body;

    if (!pickup || !dropoff || !pickup.lat || !pickup.lng || !dropoff.lat || !dropoff.lng) {
        return res.status(400).json({ 
            error: 'Missing required fields: pickup {lat, lng}, dropoff {lat, lng}' 
        });
    }

    try {
        const route = await routingService.getTripRoute(
            { lat: pickup.lat, lng: pickup.lng },
            { lat: dropoff.lat, lng: dropoff.lng },
            sectorCode || 'PASSENGER'
        );

        res.json(route);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get nearest road point
router.get('/nearest', async (req, res) => {
    const { lat, lng } = req.query;

    if (!lat || !lng) {
        return res.status(400).json({ 
            error: 'Missing required parameters: lat, lng' 
        });
    }

    try {
        const point = await routingService.getNearestRoadPoint(
            parseFloat(lat),
            parseFloat(lng)
        );

        res.json(point);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
