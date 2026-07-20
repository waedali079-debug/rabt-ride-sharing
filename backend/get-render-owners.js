require('dotenv').config();

const RENDER_API_KEY = process.env.RENDER_API_KEY;
const RENDER_API_BASE = 'https://api.render.com/v1';

async function getOwners() {
    if (!RENDER_API_KEY) {
        console.error('Error: RENDER_API_KEY environment variable is required');
        process.exit(1);
    }

    console.log('Fetching Render owners...\n');

    try {
        const response = await fetch(`${RENDER_API_BASE}/owners`, {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${RENDER_API_KEY}`,
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
        });

        const data = await response.json();

        if (response.ok) {
            console.log('✓ Owners fetched successfully!');
            console.log(JSON.stringify(data, null, 2));
        } else {
            console.error('✗ Failed to fetch owners');
            console.error('Status:', response.status);
            console.error('Response:', JSON.stringify(data, null, 2));
        }
    } catch (error) {
        console.error('Network error:', error.message);
    }
}

getOwners();
