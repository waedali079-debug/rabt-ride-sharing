require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SECRET_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

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

-- 4. Create RLS policies
-- Allow service_role full access
CREATE POLICY "Service role can do everything" ON rabt_otps
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Allow authenticated to insert and select their own OTPs
CREATE POLICY "Authenticated can insert OTPs" ON rabt_otps
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Authenticated can select OTPs" ON rabt_otps
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Authenticated can update OTPs" ON rabt_otps
    FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- 5. Grant permissions
GRANT ALL ON rabt_otps TO service_role;
GRANT INSERT, SELECT, UPDATE ON rabt_otps TO authenticated;
GRANT SELECT ON rabt_otps TO anon;
`;

async function runMigration() {
    console.log('Starting migration...');
    console.log('Supabase URL:', supabaseUrl);
    
    try {
        // Try using RPC if available
        const { data, error } = await supabase.rpc('exec_sql', { sql: migrationSQL });
        
        if (error) {
            console.log('RPC not available, trying direct query...');
            // If RPC doesn't exist, we need to use the dashboard
            console.log('\nPlease run the following SQL in Supabase Dashboard:');
            console.log('https://supabase.com/dashboard/project/dbrpqtldkjqphyzrxwww/sql/new');
            console.log('\n--- SQL ---');
            console.log(migrationSQL);
            console.log('--- End SQL ---');
        } else {
            console.log('Migration completed successfully!');
        }
    } catch (err) {
        console.log('\nPlease run the following SQL in Supabase Dashboard:');
        console.log('https://supabase.com/dashboard/project/dbrpqtldkjqphyzrxwww/sql/new');
        console.log('\n--- SQL ---');
        console.log(migrationSQL);
        console.log('--- End SQL ---');
    }
}

runMigration();
