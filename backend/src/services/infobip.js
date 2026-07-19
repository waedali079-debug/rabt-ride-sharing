const INFOBIP_API_KEY = process.env.INFOBIP_API_KEY;
const INFOBIP_BASE_URL = process.env.INFOBIP_BASE_URL;
const INFOBIP_SENDER_ID = process.env.INFOBIP_SENDER_ID || 'RABT';

async function sendSms(to, message) {
    if (!INFOBIP_API_KEY || !INFOBIP_BASE_URL) {
        throw new Error('Infobip configuration missing');
    }

    // Format phone number (remove + prefix for Infobip)
    const formattedPhone = to.startsWith('+') ? to.substring(1) : to;

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

    if (!response.ok) {
        console.error('Infobip error:', data);
        throw new Error(data.messages?.[0]?.status?.description || 'Failed to send SMS');
    }

    return {
        success: true,
        messageId: data.messages?.[0]?.messageId,
    };
}

async function sendOtp(phone, otp) {
    const message = `رمز التحقق من ربط: ${otp}\nصالح لمدة 5 دقائق.\nYour RABT verification code: ${otp}`;
    return sendSms(phone, message);
}

module.exports = { sendSms, sendOtp };
