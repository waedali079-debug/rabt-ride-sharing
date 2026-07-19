const INFOBIP_API_KEY = process.env.INFOBIP_API_KEY;
const INFOBIP_BASE_URL = process.env.INFOBIP_BASE_URL;
const INFOBIP_SENDER_ID = process.env.INFOBIP_SENDER_ID || 'RABT';

async function sendSms(to, message) {
    if (!INFOBIP_API_KEY || !INFOBIP_BASE_URL) {
        console.error('[Infobip] Missing config - API_KEY:', !!INFOBIP_API_KEY, 'BASE_URL:', !!INFOBIP_BASE_URL);
        throw new Error('Infobip configuration missing');
    }

    const formattedPhone = to.startsWith('+') ? to.substring(1) : to;

    console.log(`[Infobip] Sending SMS to +${formattedPhone} from "${INFOBIP_SENDER_ID}"`);

    const response = await fetch(`${INFOBIP_BASE_URL}/sms/3/messages`, {
        method: 'POST',
        headers: {
            'Authorization': `App ${INFOBIP_API_KEY}`,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        },
        body: JSON.stringify({
            messages: [
                {
                    sender: INFOBIP_SENDER_ID,
                    destinations: [{ to: formattedPhone }],
                    content: { text: message },
                },
            ],
        }),
    });

    const data = await response.json();
    const msgStatus = data.messages?.[0]?.status;

    console.log(`[Infobip] Response: ${response.status} | Status: ${msgStatus?.name} | ID: ${data.messages?.[0]?.messageId}`);

    if (!response.ok) {
        console.error('[Infobip] Error:', JSON.stringify(data));
        throw new Error(msgStatus?.description || 'Failed to send SMS');
    }

    return {
        success: true,
        messageId: data.messages?.[0]?.messageId,
        status: msgStatus?.name,
    };
}

async function sendOtp(phone, otp) {
    const message = `رمز التحقق من ربط: ${otp}\nصالح لمدة 5 دقائق.\nYour RABT verification code: ${otp}`;
    return sendSms(phone, message);
}

module.exports = { sendSms, sendOtp };
