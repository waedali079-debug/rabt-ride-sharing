const { createClient } = require('@supabase/supabase-js');

const GRAPHHOPPER_URL = process.env.GRAPHHOPPER_URL || 'http://localhost:8989';
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SECRET_KEY);

class RoutingService {
    constructor() {
        this.baseUrl = GRAPHHOPPER_URL;
        this._fareRates = null;
    }

    async _loadFareRates() {
        if (this._fareRates) return this._fareRates;

        const { data: sectors } = await supabase
            .from('rabt_sectors')
            .select('sector_code, fare_base, fare_per_km');

        if (sectors) {
            this._fareRates = {};
            for (const s of sectors) {
                this._fareRates[s.sector_code] = {
                    base: s.fare_base || 5,
                    perKm: s.fare_per_km || 1.5,
                };
            }
        }

        if (!this._fareRates) {
            this._fareRates = {
                'S-01': { base: 5, perKm: 1.5 },
                'S-02': { base: 7, perKm: 2.0 },
                'S-03': { base: 6.5, perKm: 1.8 },
                'S-04': { base: 8, perKm: 2.2 },
                'S-05': { base: 25, perKm: 5.0 },
                'S-06': { base: 30, perKm: 6.0 },
                'S-07': { base: 50, perKm: 12.0 },
                'S-08': { base: 40, perKm: 8.0 },
                'S-09': { base: 15, perKm: 3.5 },
            };
        }

        return this._fareRates;
    }

    async getRoute(startLat, startLng, endLat, endLng, profile = 'car') {
        const url = `${this.baseUrl}/route?point=${startLat},${startLng}&point=${endLat},${endLng}&profile=${profile}&points_encoded=false&calc_points=true`;

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
            distance: path.distance,
            duration: path.time,
            distanceKm: parseFloat((path.distance / 1000).toFixed(2)),
            durationMinutes: Math.round(path.time / 60000),
            points: path.points.coordinates.map(coord => ({
                lat: coord[1],
                lng: coord[0]
            })),
        };
    }

    async getTripRoute(pickup, dropoff, sectorCode = 'S-01') {
        const profileMap = {
            'S-01': 'car',
            'S-02': 'small_truck',
            'S-03': 'small_truck',
            'S-04': 'small_truck',
            'S-05': 'truck',
            'S-06': 'truck',
            'S-07': 'truck',
            'S-08': 'truck',
            'S-09': 'car',
        };

        const profile = profileMap[sectorCode] || 'car';

        const route = await this.getRoute(
            pickup.lat, pickup.lng,
            dropoff.lat, dropoff.lng,
            profile
        );

        const rates = await this._loadFareRates();
        const rate = rates[sectorCode] || rates['S-01'];
        const fareAmount = rate.base + (route.distanceKm * rate.perKm);

        return {
            distanceKm: route.distanceKm,
            durationMinutes: route.durationMinutes,
            points: route.points,
            fare: {
                amount: parseFloat(fareAmount.toFixed(3)),
                currency: 'JOD',
            },
            sectorCode,
            profile,
        };
    }

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
