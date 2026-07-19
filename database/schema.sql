-- ==========================================================
-- RABT SYSTEM: UNIFIED DATABASE SCHEMA (HYBRID V31)
-- Engine: PostgreSQL 15+ with PostGIS, pgcrypto
-- ==========================================================

-- 1. Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Custom Enums
CREATE TYPE user_role AS ENUM ('customer', 'driver', 'admin');
CREATE TYPE trip_status AS ENUM ('pending', 'accepted', 'arrived', 'in_progress', 'completed', 'cancelled');
CREATE TYPE payment_method AS ENUM ('cash', 'card', 'wallet');
CREATE TYPE payment_status AS ENUM ('pending', 'success', 'failed');
CREATE TYPE dispute_status AS ENUM ('open', 'investigating', 'resolved', 'rejected');

-- 3. Sectors Table
CREATE TABLE rabt_sectors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(50) NOT NULL,
    color_code VARCHAR(7) NOT NULL,
    icon_name VARCHAR(50) NOT NULL,
    base_fare DECIMAL(10, 2) NOT NULL DEFAULT 0,
    per_km_rate DECIMAL(10, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Users Table (With Encryption)
CREATE TABLE rabt_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    role user_role NOT NULL,
    full_name VARCHAR(100),
    national_id_encrypted BYTEA,
    is_active BOOLEAN DEFAULT TRUE,
    sector_id UUID REFERENCES rabt_sectors(id) ON DELETE SET NULL,
    current_location GEOMETRY(Point, 4326),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_users_location ON rabt_users USING GIST (current_location);
CREATE INDEX idx_users_phone ON rabt_users(phone_number);

-- 5. Driver Profiles & Locations (Retained for Aggregator Logic)
CREATE TABLE rabt_driver_profiles (
    driver_id UUID PRIMARY KEY REFERENCES rabt_users(id) ON DELETE CASCADE,
    vehicle_plate VARCHAR(20) UNIQUE NOT NULL,
    vehicle_model VARCHAR(50),
    is_online BOOLEAN DEFAULT FALSE,
    is_available BOOLEAN DEFAULT FALSE,
    rating DECIMAL(2,1) DEFAULT 5.0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE rabt_driver_locations (
    driver_id UUID PRIMARY KEY REFERENCES rabt_users(id) ON DELETE CASCADE,
    location GEOMETRY(Point, 4326) NOT NULL,
    heading DECIMAL(4,1),
    speed_kmh DECIMAL(5,1),
    last_updated TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_driver_loc_point ON rabt_driver_locations USING GIST (location);

-- 6. Trips Table (With Double-Booking Prevention)
CREATE TABLE rabt_trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES rabt_users(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES rabt_users(id) ON DELETE SET NULL,
    sector_id UUID NOT NULL REFERENCES rabt_sectors(id) ON DELETE RESTRICT,
    status trip_status DEFAULT 'pending',
    pickup_location GEOMETRY(Point, 4326) NOT NULL,
    dropoff_location GEOMETRY(Point, 4326),
    fare DECIMAL(10, 2),
    distance_km DECIMAL(10, 2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    accepted_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);
CREATE INDEX idx_trips_customer ON rabt_trips(customer_id);
CREATE INDEX idx_trips_driver ON rabt_trips(driver_id);
-- CRITICAL: Prevents a driver from having two active trips simultaneously
CREATE UNIQUE INDEX idx_driver_active_trip ON rabt_trips(driver_id) 
WHERE status IN ('accepted', 'arrived', 'in_progress');

-- 7. Payments Table
CREATE TABLE rabt_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES rabt_trips(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    method payment_method NOT NULL,
    status payment_status DEFAULT 'pending',
    transaction_ref VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Advanced User Trees (Gamification)
CREATE TABLE rabt_user_trees (
    user_id UUID PRIMARY KEY REFERENCES rabt_users(id) ON DELETE CASCADE,
    completed_trips INT DEFAULT 0,
    stage INT DEFAULT 0, -- 0:Seedling, 1:Young, 2:Mature, 3:Ancient, 4:Legendary
    season VARCHAR(20) DEFAULT 'spring',
    has_halo BOOLEAN DEFAULT FALSE,
    last_updated TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Audit Logs (With Automation Triggers)
CREATE TABLE rabt_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES rabt_users(id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50),
    entity_id UUID,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_audit_user ON rabt_audit_logs(user_id);

-- 10. Disputes Table (New Addition)
CREATE TABLE rabt_disputes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES rabt_trips(id) ON DELETE CASCADE,
    reported_by UUID NOT NULL REFERENCES rabt_users(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status dispute_status DEFAULT 'open',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. OTPs Table (For Infobip SMS Verification)
CREATE TABLE rabt_otps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) NOT NULL,
    otp_code VARCHAR(6) NOT NULL,
    purpose VARCHAR(20) NOT NULL DEFAULT 'login', -- login, register, reset
    is_used BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_otps_phone ON rabt_otps(phone_number);
CREATE INDEX idx_otps_expires ON rabt_otps(expires_at);

-- Function to cleanup expired OTPs
CREATE OR REPLACE FUNCTION cleanup_expired_otps()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM rabt_otps WHERE expires_at < NOW() - INTERVAL '1 hour';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ==========================================================
-- FUNCTIONS & TRIGGERS
-- ==========================================================

-- Nearest Driver Matching Function (Critical for Aggregator)
CREATE OR REPLACE FUNCTION match_nearest_driver(p_pickup GEOMETRY(Point, 4326), p_sector_id UUID)
RETURNS UUID AS $$
DECLARE
    matched_driver UUID;
BEGIN
    SELECT dl.driver_id INTO matched_driver
    FROM rabt_driver_locations dl
    JOIN rabt_driver_profiles dp ON dl.driver_id = dp.driver_id
    JOIN rabt_users u ON dl.driver_id = u.id
    WHERE u.sector_id = p_sector_id
      AND dp.is_online = TRUE
      AND dp.is_available = TRUE
      AND NOT EXISTS (
          SELECT 1 FROM rabt_trips t 
          WHERE t.driver_id = dl.driver_id 
          AND t.status IN ('accepted', 'arrived', 'in_progress')
      )
    ORDER BY dl.location <-> p_pickup
    LIMIT 1;
    
    RETURN matched_driver;
END;
$$ LANGUAGE plpgsql;

-- Update Timestamp Trigger
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_modtime BEFORE UPDATE ON rabt_users FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER update_driver_loc_modtime BEFORE UPDATE ON rabt_driver_locations FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
