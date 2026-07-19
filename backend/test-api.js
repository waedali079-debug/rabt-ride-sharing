const http = require('http');

function testEndpoint(path, method = 'GET', body = null) {
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
    console.log('Testing Backend API...\n');

    // Test 1: Health endpoint
    console.log('1. Testing /health endpoint...');
    try {
        const health = await testEndpoint('/health');
        console.log('   Status:', health.status);
        console.log('   Response:', JSON.stringify(health.data, null, 2));
    } catch (err) {
        console.log('   Error:', err.message);
    }

    // Test 2: Send OTP
    console.log('\n2. Testing /api/v1/otp/send endpoint...');
    try {
        const sendOtp = await testEndpoint('/api/v1/otp/send', 'POST', {
            phone: '+966501234567',
        });
        console.log('   Status:', sendOtp.status);
        console.log('   Response:', JSON.stringify(sendOtp.data, null, 2));
    } catch (err) {
        console.log('   Error:', err.message);
    }

    console.log('\nTests completed!');
}

runTests();
