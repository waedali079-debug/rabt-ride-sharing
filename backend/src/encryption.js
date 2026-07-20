const crypto = require('crypto');

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 16;

const ENCRYPTION_SECRET = process.env.ENCRYPTION_SECRET || process.env.ENCRYPTION_KEY;
if (!ENCRYPTION_SECRET) {
    console.error('FATAL ERROR: ENCRYPTION_SECRET (or ENCRYPTION_KEY) is missing in environment variables.');
    process.exit(1);
}

const SALT = process.env.ENCRYPTION_SALT || 'rabt-salt-v1';
const KEY = crypto.scryptSync(ENCRYPTION_SECRET, SALT, 32);

function encrypt(text) {
    const iv = crypto.randomBytes(IV_LENGTH);
    const cipher = crypto.createCipheriv(ALGORITHM, KEY, iv);
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    const authTag = cipher.getAuthTag();
    return `${iv.toString('hex')}:${encrypted}:${authTag.toString('hex')}`;
}

function decrypt(encryptedText) {
    const [ivHex, encrypted, authTagHex] = encryptedText.split(':');
    const iv = Buffer.from(ivHex, 'hex');
    const authTag = Buffer.from(authTagHex, 'hex');
    const decipher = crypto.createDecipheriv(ALGORITHM, KEY, iv);
    decipher.setAuthTag(authTag);
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
}

module.exports = { encrypt, decrypt };
