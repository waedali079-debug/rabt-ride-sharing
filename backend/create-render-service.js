require('dotenv').config();

const RENDER_API_KEY = process.env.RENDER_API_KEY;
const RENDER_API_BASE = 'https://api.render.com/v1';
const OWNER_ID = process.env.RENDER_OWNER_ID || 'tea-d8a80rmq1p3s73deka80';

async function createService() {
    if (!RENDER_API_KEY) {
        console.error('Error: RENDER_API_KEY environment variable is required');
        process.exit(1);
    }

    console.log('Creating new Render service...\n');

    const serviceData = {
        type: 'web_service',
        name: 'rabt-api-server',
        ownerId: OWNER_ID,
        repo: 'https://github.com/waedali079-debug/rabt-ride-sharing.git',
        branch: 'main',
        autoDeploy: 'yes',
        serviceDetails: {
            runtime: 'node',
            envSpecificDetails: {
                buildCommand: 'cd backend && npm install',
                startCommand: 'cd backend && npm start'
            },
            plan: 'free',
            region: 'oregon',
        },
        envVars: [
            { key: 'NODE_ENV', value: 'production' },
            { key: 'PORT', value: '10000' },
            { key: 'SUPABASE_URL', value: process.env.SUPABASE_URL },
            { key: 'SUPABASE_SECRET_KEY', value: process.env.SUPABASE_SECRET_KEY },
            { key: 'JWT_SECRET', value: process.env.JWT_SECRET || 'rabt_jwt_secret_v31_production_2026' },
            { key: 'INFOBIP_API_KEY', value: process.env.INFOBIP_API_KEY },
            { key: 'INFOBIP_BASE_URL', value: process.env.INFOBIP_BASE_URL },
            { key: 'INFOBIP_SENDER_ID', value: process.env.INFOBIP_SENDER_ID },
        ],
    };

    try {
        const response = await fetch(`${RENDER_API_BASE}/services`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${RENDER_API_KEY}`,
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
            body: JSON.stringify(serviceData),
        });

        const data = await response.json();

        if (response.ok) {
            console.log('✓ Service created successfully!');
            console.log('Service ID:', data.service?.id);
            console.log('Service Name:', data.service?.name);
            console.log('Dashboard URL:', data.service?.dashboardUrl);
            console.log('Service URL:', data.service?.serviceDetails?.url);
        } else {
            console.error('✗ Failed to create service');
            console.error('Status:', response.status);
            console.error('Response:', JSON.stringify(data, null, 2));
        }
    } catch (error) {
        console.error('Network error:', error.message);
    }
}

createService();
