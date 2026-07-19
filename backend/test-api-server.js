require('dotenv').config();
const http = require('http');

// Start server
const app = require('./src/api-server');

function testEndpoint(path, method = 'GET', body = null, token = null) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'localhost',
            port: 8080,
            path: path,
            method: method,
            headers: {
                'Content-Type': 'application/json',
            },
        };

        if (token) {
            options.headers['Authorization'] = `Bearer ${token}`;
        }

        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => {
                try {
                    resolve({ status: res.statusCode, data: JSON.parse(data) });
                } catch (e) {
                    resolve({ status: res.statusCode, data: data });
                }
            });
        });

        req.on('error', reject);

        if (body) {
            req.write(JSON.stringify(body));
        }
        req.end();
    });
}

async function runTests() {
    console.log('Testing Rabt API Server...\n');

    // Test 1: Health endpoint (no auth required)
    console.log('1. Testing /health endpoint...');
    try {
        const health = await testEndpoint('/health');
        console.log('   Status:', health.status);
        console.log('   Response:', JSON.stringify(health.data, null, 2));
    } catch (err) {
        console.log('   Error:', err.message);
    }

    // Test 2: Send OTP
    console.log('\n2. Testing /api/v1/auth/send-otp endpoint...');
    try {
        const sendOtp = await testEndpoint('/api/v1/auth/send-otp', 'POST', {
            phone: '+966501234567',
        });
        console.log('   Status:', sendOtp.status);
        console.log('   Response:', JSON.stringify(sendOtp.data, null, 2));
    } catch (err) {
        console.log('   Error:', err.message);
    }

    // Test 3: Verify OTP (with test OTP)
    console.log('\n3. Testing /api/v1/auth/verify-otp endpoint...');
    try {
        const verifyOtp = await testEndpoint('/api/v1/auth/verify-otp', 'POST', {
            phone: '+966501234567',
            otp: '123456', // Test OTP
        });
        console.log('   Status:', verifyOtp.status);
        console.log('   Response:', JSON.stringify(verifyOtp.data, null, 2));
        
        // If successful, test protected endpoint
        if (verifyOtp.status === 200 && verifyOtp.data.token) {
            console.log('\n4. Testing protected endpoint /api/v1/user/profile...');
            const profile = await testEndpoint('/api/v1/user/profile', 'GET', null, verifyOtp.data.token);
            console.log('   Status:', profile.status);
            console.log('   Response:', JSON.stringify(profile.data, null, 2));
        }
    } catch (err) {
        console.log('   Error:', err.message);
    }

    console.log('\nTests completed!');
    process.exit(0);
}

// Wait for server to start
setTimeout(runTests, 2000);
