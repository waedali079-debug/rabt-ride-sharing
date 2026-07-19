const GRAPHHOPPER_URL = process.env.GRAPHHOPPER_URL || 'http://localhost:8989';

class RoutingService {
    constructor() {
        this.baseUrl = GRAPHHOPPER_URL;
    }

    /**
     * Get route between two points
     * @param {number} startLat - Start latitude
     * @param {number} startLng - Start longitude
     * @param {number} endLat - End latitude
     * @param {number} endLng - End longitude
     * @param {string} profile - Vehicle profile (car, small_truck, truck)
     * @returns {Promise<Object>} Route data
     */
    async getRoute(startLat, startLng, endLat, endLng, profile = 'car') {
        const url = `${this.baseUrl}/route?point=${startLat},${startLng}&point=${endLat},${endLng}&profile=${profile}&points_encoded=false&calc_points=true`;

        try {
            const response = await fetch(url);
            
            if (!response.ok) {
                throw new Error(`GraphHopper error: ${response.status}`);
            }

            const data = await response.json();
            
            if (!data.paths || data.paths.length === 0) {
                throw new Error('No route found');
            }

            const path = data.paths[0];
            
            return {
                distance: path.distance, // meters
                duration: path.time, // milliseconds
                distanceKm: (path.distance / 1000).toFixed(2),
                durationMinutes: Math.round(path.time / 60000),
                points: path.points.coordinates.map(coord => ({
                    lat: coord[1],
                    lng: coord[0]
                })),
                instructions: path.instructions || [],
                bbox: path.bbox
            };
        } catch (error) {
            console.error('Routing error:', error.message);
            throw error;
        }
    }

    /**
     * Get route for trip request
     * @param {Object} pickup - Pickup location {lat, lng}
     * @param {Object} dropoff - Dropoff location {lat, lng}
     * @param {string} sectorCode - Sector code (PASSENGER, GAS, etc.)
     * @returns {Promise<Object>} Route data with fare estimation
     */
    async getTripRoute(pickup, dropoff, sectorCode = 'PASSENGER') {
        // Map sector codes to vehicle profiles
        const profileMap = {
            'PASSENGER': 'car',
            'GAS': 'small_truck',
            'WATER': 'small_truck',
            'SMALL_CARGO': 'small_truck',
            'TRUCKS': 'truck',
            'CRANES': 'truck',
            'MECHANICS': 'car',
            'LARGE_CARGO': 'truck',
            'SPECIAL': 'car'
        };

        const profile = profileMap[sectorCode] || 'car';
        
        const route = await this.getRoute(
            pickup.lat, pickup.lng,
            dropoff.lat, dropoff.lng,
            profile
        );

        // Estimate fare based on distance and sector
        const fare = this.estimateFare(route.distanceKm, sectorCode);

        return {
            ...route,
            fare,
            sectorCode,
            profile
        };
    }

    /**
     * Estimate fare based on distance and sector
     * @param {number} distanceKm - Distance in kilometers
     * @param {string} sectorCode - Sector code
     * @returns {Object} Fare breakdown
     */
    estimateFare(distanceKm, sectorCode) {
        // Base rates per km (in JOD - Jordanian Dinar)
        const rates = {
            'PASSENGER': { base: 0.5, perKm: 0.35, minimum: 1.0 },
            'GAS': { base: 1.0, perKm: 0.50, minimum: 2.0 },
            'WATER': { base: 1.0, perKm: 0.50, minimum: 2.0 },
            'SMALL_CARGO': { base: 1.5, perKm: 0.60, minimum: 3.0 },
            'TRUCKS': { base: 2.0, perKm: 0.80, minimum: 5.0 },
            'CRANES': { base: 5.0, perKm: 1.50, minimum: 10.0 },
            'MECHANICS': { base: 1.0, perKm: 0.40, minimum: 2.0 },
            'LARGE_CARGO': { base: 3.0, perKm: 1.00, minimum: 8.0 },
            'SPECIAL': { base: 2.0, perKm: 0.70, minimum: 5.0 }
        };

        const rate = rates[sectorCode] || rates['PASSENGER'];
        const calculatedFare = rate.base + (distanceKm * rate.perKm);
        const finalFare = Math.max(calculatedFare, rate.minimum);

        return {
            amount: parseFloat(finalFare.toFixed(3)),
            currency: 'JOD',
            breakdown: {
                base: rate.base,
                distance: parseFloat((distanceKm * rate.perKm).toFixed(3)),
                total: parseFloat(finalFare.toFixed(3)),
                minimum: rate.minimum
            }
        };
    }

    /**
     * Find nearest road point to given coordinates
     * @param {number} lat - Latitude
     * @param {number} lng - Longitude
     * @returns {Promise<Object>} Nearest point on road
     */
    async getNearestRoadPoint(lat, lng) {
        const url = `${this.baseUrl}/nearest?point=${lat},${lng}&profile=car`;

        try {
            const response = await fetch(url);
            
            if (!response.ok) {
                throw new Error(`GraphHopper nearest error: ${response.status}`);
            }

            const data = await response.json();
            
            return {
                lat: data.location.coordinates[1],
                lng: data.location.coordinates[0],
                distance: data.distance || 0
            };
        } catch (error) {
            console.error('Nearest point error:', error.message);
            throw error;
        }
    }

    /**
     * Health check for GraphHopper service
     * @returns {Promise<boolean>}
     */
    async healthCheck() {
        try {
            const response = await fetch(`${this.baseUrl}/health`);
            return response.ok;
        } catch (error) {
            return false;
        }
    }
}

module.exports = new RoutingService();
