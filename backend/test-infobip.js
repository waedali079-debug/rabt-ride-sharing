require('dotenv').config();

const INFOBIP_API_KEY = process.env.INFOBIP_API_KEY;
const INFOBIP_BASE_URL = process.env.INFOBIP_BASE_URL;
const INFOBIP_SENDER_ID = process.env.INFOBIP_SENDER_ID;

console.log('Testing Infobip SMS Connection...\n');
console.log('API Key:', INFOBIP_API_KEY ? INFOBIP_API_KEY.substring(0, 20) + '...' : 'NOT SET');
console.log('Base URL:', INFOBIP_BASE_URL || 'NOT SET');
console.log('Sender ID:', INFOBIP_SENDER_ID || 'NOT SET');
console.log('');

async function testSendSms(phoneNumber) {
    if (!INFOBIP_API_KEY || !INFOBIP_BASE_URL) {
        console.error('Error: Infobip configuration missing');
        return;
    }

    // Format phone number (remove + prefix for Infobip)
    const formattedPhone = phoneNumber.startsWith('+') ? phoneNumber.substring(1) : phoneNumber;

    const message = `Test from RABT: Your verification code is 123456. Valid for 5 minutes.`;

    console.log(`Sending SMS to: ${formattedPhone}`);
    console.log(`Message: ${message}\n`);

    try {
        const response = await fetch(`${INFOBIP_BASE_URL}/sms/2/text/advanced`, {
            method: 'POST',
            headers: {
                'Authorization': `App ${INFOBIP_API_KEY}`,
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
            body: JSON.stringify({
                messages: [
                    {
                        from: INFOBIP_SENDER_ID,
                        destinations: [{ to: formattedPhone }],
                        text: message,
                    },
                ],
            }),
        });

        const data = await response.json();

        console.log('Response Status:', response.status);
        console.log('Response Body:', JSON.stringify(data, null, 2));

        if (response.ok) {
            console.log('\n✓ SMS sent successfully!');
            console.log('Message ID:', data.messages?.[0]?.messageId);
        } else {
            console.log('\n✗ Failed to send SMS');
            console.log('Error:', data.messages?.[0]?.status?.description || 'Unknown error');
        }
    } catch (error) {
        console.error('Network error:', error.message);
    }
}

// Test with a sample phone number (replace with your actual test number)
const testPhone = '+966501234567';
testSendSms(testPhone);
