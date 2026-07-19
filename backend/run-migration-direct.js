require('dotenv').config();
const { Client } = require('pg');

const client = new Client({
    connectionString: process.env.SUPABASE_DB_DIRECT || process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

const migrationSQL = `
-- 1. Create OTPs table
CREATE TABLE IF NOT EXISTS rabt_otps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) NOT NULL,
    otp_code VARCHAR(6) NOT NULL,
    purpose VARCHAR(20) NOT NULL DEFAULT 'login',
    is_used BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create indexes
CREATE INDEX IF NOT EXISTS idx_otps_phone ON rabt_otps(phone_number);
CREATE INDEX IF NOT EXISTS idx_otps_expires ON rabt_otps(expires_at);

-- 3. Enable RLS
ALTER TABLE rabt_otps ENABLE ROW LEVEL SECURITY;

-- 4. Grant permissions
GRANT ALL ON rabt_otps TO service_role;
GRANT INSERT, SELECT, UPDATE ON rabt_otps TO authenticated;
GRANT SELECT ON rabt_otps TO anon;
`;

async function runMigration() {
    console.log('Connecting to Supabase PostgreSQL...');
    console.log('Connection string:', process.env.SUPABASE_DB_DIRECT ? 'Using DIRECT_URL' : 'Using DATABASE_URL');
    
    try {
        await client.connect();
        console.log('Connected successfully!\n');

        // Run the migration
        console.log('Running migration...');
        const result = await client.query(migrationSQL);
        console.log('Migration completed successfully!');
        
        // Verify table exists
        console.log('\nVerifying table...');
        const verifyResult = await client.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_name = 'rabt_otps'
        `);
        
        if (verifyResult.rows.length > 0) {
            console.log('✓ Table rabt_otps exists');
        } else {
            console.log('✗ Table rabt_otps not found');
        }

        // Check RLS
        console.log('\nChecking RLS...');
        const rlsResult = await client.query(`
            SELECT relname, relrowsecurity 
            FROM pg_class 
            WHERE relname = 'rabt_otps'
        `);
        
        if (rlsResult.rows.length > 0 && rlsResult.rows[0].relrowsecurity) {
            console.log('✓ RLS is enabled');
        } else {
            console.log('✗ RLS is not enabled');
        }

        console.log('\nMigration verification complete!');
    } catch (err) {
        console.error('Migration error:', err.message);
        
        if (err.message.includes('ECONNREFUSED')) {
            console.log('\nCannot connect to database. Please run the SQL manually:');
            console.log('https://supabase.com/dashboard/project/dbrpqtldkjqphyzrxwww/sql/new');
        }
    } finally {
        await client.end();
    }
}

runMigration();
