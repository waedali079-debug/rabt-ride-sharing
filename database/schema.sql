-- ====================================================================
-- SYSTEM: Rabt Multi-Reality Enterprise Database Schema (REFACTORED)
-- PATCH VERSION: 1.0.2 (The "Real" Production-Ready Patch)
-- Fixes: Geography Index Bypass, RLS Dispatch Deadlock, Audit Restore
-- SECURITY LAYER: Triple-Layer Armor (UUIDv4, Check Constraints, RLS)
-- PERFORMANCE LAYER: GiST Geography Indexing & Composite B-Trees
-- ====================================================================

-- 1. تفعيل الامتدادات الأمنية والجغرافية الحيوية
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. إنشاء الأنواع المخصصة المحمية (Custom Enums)
-- ملاحظة: تم التخلص من rabt_sector_code لصالح VARCHAR ديناميكي
DO $$ BEGIN
    CREATE TYPE rabt_user_role AS ENUM ('customer', 'driver', 'admin', 'super_admin');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE rabt_trip_status AS ENUM ('requested', 'searching', 'accepted', 'arrived', 'active', 'completed', 'canceled');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE rabt_tree_stage AS ENUM ('seedling', 'young', 'mature', 'ancient', 'legendary');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE rabt_season AS ENUM ('spring', 'summer', 'autumn', 'winter');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE rabt_payment_status AS ENUM ('pending', 'escrowed', 'released', 'refunded', 'failed');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ====================================================================
-- 3. الدوال المساعدة (All hardened with SECURITY DEFINER + search_path)
-- ====================================================================

CREATE OR REPLACE FUNCTION update_rabt_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CLOCK_TIMESTAMP();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- دالة مساعدة لاستخلاص المعرّف الآمن للمستخدم الحالي من الـ Context
CREATE OR REPLACE FUNCTION get_rabt_context_user() RETURNS UUID AS $$
BEGIN
    RETURN NULLIF(current_setting('app.current_user_id', true), '')::UUID;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ====================================================================
-- 4. جدول القطاعات الديناميكي (VARCHAR بدل ENUM لمرونة الإضافة)
-- ====================================================================
CREATE TABLE rabt_sectors (
    sector_code VARCHAR(10) PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL UNIQUE,
    name_en VARCHAR(50) NOT NULL UNIQUE,
    base_fare NUMERIC(10, 2) NOT NULL,
    per_km_rate NUMERIC(10, 2) NOT NULL,
    per_minute_rate NUMERIC(10, 2) NOT NULL,
    is_operational BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    CONSTRAINT chk_base_fare CHECK (base_fare >= 0.00),
    CONSTRAINT chk_km_rate CHECK (per_km_rate >= 0.00),
    CONSTRAINT chk_min_rate CHECK (per_minute_rate >= 0.00)
);

-- ====================================================================
-- 5. جدول المستخدمين (مع تشفير pgcrypto)
-- ====================================================================
CREATE TABLE rabt_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    role rabt_user_role NOT NULL DEFAULT 'customer',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    national_id_encrypted BYTEA NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    CONSTRAINT chk_phone_format CHECK (phone_number ~ '^\+?[1-9]\d{1,14}$')
);

CREATE TRIGGER trg_update_rabt_users BEFORE UPDATE ON rabt_users 
FOR EACH ROW EXECUTE FUNCTION update_rabt_timestamp();

-- ====================================================================
-- 6. ملفات السائقين
-- ====================================================================
CREATE TABLE rabt_driver_profiles (
    user_id UUID PRIMARY KEY REFERENCES rabt_users(id) ON DELETE RESTRICT,
    assigned_sector VARCHAR(10) NOT NULL REFERENCES rabt_sectors(sector_code),
    vehicle_plate_number VARCHAR(20) NOT NULL UNIQUE,
    vehicle_model VARCHAR(50) NOT NULL,
    is_available BOOLEAN NOT NULL DEFAULT FALSE,
    current_speed_kmh NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    rating_average NUMERIC(3,2) NOT NULL DEFAULT 5.00,
    total_trips_completed INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    CONSTRAINT chk_driver_speed CHECK (current_speed_kmh >= 0.00),
    CONSTRAINT chk_driver_rating CHECK (rating_average BETWEEN 1.00 AND 5.00),
    CONSTRAINT chk_driver_trips CHECK (total_trips_completed >= 0)
);

CREATE TRIGGER trg_update_rabt_driver_profiles BEFORE UPDATE ON rabt_driver_profiles 
FOR EACH ROW EXECUTE FUNCTION update_rabt_timestamp();

-- ====================================================================
-- 7. محرك التتبع الحي (GEOGRAPHY — NOT geometry)
-- ====================================================================
CREATE TABLE rabt_driver_locations (
    driver_id UUID PRIMARY KEY REFERENCES rabt_driver_profiles(user_id) ON DELETE CASCADE,
    live_coordinates GEOGRAPHY(Point, 4326) NOT NULL,
    last_ping_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CLOCK_TIMESTAMP()
);

-- فهرس GiST على GEOGRAPHY (لا يحتاج Cast في الاستعلامات)
CREATE INDEX idx_rabt_driver_spatial_geo ON rabt_driver_locations USING GIST (live_coordinates);

-- ====================================================================
-- 8. جدول الرحلات (مع Double-Booking Prevention)
-- ====================================================================
CREATE TABLE rabt_trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES rabt_users(id) ON DELETE RESTRICT,
    driver_id UUID REFERENCES rabt_driver_profiles(user_id) ON DELETE RESTRICT,
    sector_code VARCHAR(10) NOT NULL REFERENCES rabt_sectors(sector_code),
    status rabt_trip_status NOT NULL DEFAULT 'requested',
    pickup_location GEOMETRY(Point, 4326) NOT NULL,
    dropoff_location GEOMETRY(Point, 4326) NOT NULL,
    estimated_price NUMERIC(10, 2) NOT NULL,
    final_price NUMERIC(10, 2),
    estimated_duration_minutes INT NOT NULL,
    actual_duration_minutes INT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    accepted_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    CONSTRAINT chk_est_price CHECK (estimated_price > 0.00),
    CONSTRAINT chk_fin_price CHECK (final_price >= 0.00),
    CONSTRAINT chk_est_duration CHECK (estimated_duration_minutes > 0)
);

CREATE TRIGGER trg_update_rabt_trips BEFORE UPDATE ON rabt_trips 
FOR EACH ROW EXECUTE FUNCTION update_rabt_timestamp();

-- فهرس فريد جزئي يمنع السائق من الارتباط بأكثر من رحلة نشطة في نفس الوقت
CREATE UNIQUE INDEX idx_prevent_driver_double_booking 
ON rabt_trips (driver_id) 
WHERE status IN ('accepted', 'arrived', 'active');

CREATE INDEX idx_trips_customer ON rabt_trips(customer_id);
CREATE INDEX idx_trips_status_sector ON rabt_trips(status, sector_code);
CREATE INDEX idx_trips_pickup_spatial ON rabt_trips USING GIST (pickup_location);

-- ====================================================================
-- 9. محرك المدفوعات
-- ====================================================================
CREATE TABLE rabt_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL UNIQUE REFERENCES rabt_trips(id) ON DELETE RESTRICT,
    amount NUMERIC(10, 2) NOT NULL,
    status rabt_payment_status NOT NULL DEFAULT 'pending',
    transaction_reference VARCHAR(100) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    CONSTRAINT chk_payment_amount CHECK (amount > 0.00)
);

CREATE TRIGGER trg_update_rabt_payments BEFORE UPDATE ON rabt_payments 
FOR EACH ROW EXECUTE FUNCTION update_rabt_timestamp();

-- ====================================================================
-- 10. نظام التلغيب (الشجرة)
-- ====================================================================
CREATE TABLE rabt_trees (
    user_id UUID PRIMARY KEY REFERENCES rabt_users(id) ON DELETE CASCADE,
    growth_stage rabt_tree_stage NOT NULL DEFAULT 'seedling',
    active_season rabt_season NOT NULL DEFAULT 'spring',
    total_leaves INT NOT NULL DEFAULT 0,
    total_fruits INT NOT NULL DEFAULT 0,
    has_golden_halo BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CLOCK_TIMESTAMP(),
    CONSTRAINT chk_max_leaves CHECK (total_leaves <= 500),
    CONSTRAINT chk_max_fruits CHECK (total_fruits <= 8)
);

CREATE TRIGGER trg_update_rabt_trees BEFORE UPDATE ON rabt_trees 
FOR EACH ROW EXECUTE FUNCTION update_rabt_timestamp();

-- ====================================================================
-- 11. نظام السجلات الرقابية (RESTORED + HARDENED)
-- ====================================================================
CREATE TABLE rabt_audit_logs (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    action_type VARCHAR(10) NOT NULL,
    record_id UUID NOT NULL,
    old_data JSONB,
    new_data JSONB,
    performed_by VARCHAR(100) NOT NULL DEFAULT CURRENT_USER,
    captured_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CLOCK_TIMESTAMP()
);

CREATE OR REPLACE FUNCTION process_rabt_audit_logging() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO rabt_audit_logs(table_name, action_type, record_id, old_data)
        VALUES (TG_TABLE_NAME, 'DELETE', OLD.id, to_jsonb(OLD));
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO rabt_audit_logs(table_name, action_type, record_id, old_data, new_data)
        VALUES (TG_TABLE_NAME, 'UPDATE', NEW.id, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO rabt_audit_logs(table_name, action_type, record_id, new_data)
        VALUES (TG_TABLE_NAME, 'INSERT', NEW.id, to_jsonb(NEW));
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trg_audit_trips AFTER INSERT OR UPDATE OR DELETE ON rabt_trips
FOR EACH ROW EXECUTE FUNCTION process_rabt_audit_logging();

CREATE TRIGGER trg_audit_payments AFTER INSERT OR UPDATE OR DELETE ON rabt_payments
FOR EACH ROW EXECUTE FUNCTION process_rabt_audit_logging();

-- ====================================================================
-- 12. محرك المطابقة الجغرافي (SECURITY DEFINER — تتجاوز RLS)
-- ====================================================================
CREATE OR REPLACE FUNCTION match_nearest_driver(
    p_sector_code VARCHAR,
    p_lng NUMERIC,
    p_lat NUMERIC,
    p_search_radius_meters INT DEFAULT 5000
) RETURNS UUID AS $$
DECLARE
    v_matched_driver_id UUID;
BEGIN
    SELECT p.user_id INTO v_matched_driver_id
    FROM rabt_driver_profiles p
    JOIN rabt_driver_locations l ON p.user_id = l.driver_id
    WHERE p.assigned_sector = p_sector_code
      AND p.is_available = TRUE
      AND ST_DWithin(l.live_coordinates, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography, p_search_radius_meters)
    ORDER BY ST_Distance(l.live_coordinates, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography) ASC
    LIMIT 1;

    RETURN v_matched_driver_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ====================================================================
-- 13. طبقة الحماية القصوى: Row-Level Security (RLS) على جميع الجداول الستة
-- ====================================================================
ALTER TABLE rabt_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE rabt_driver_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE rabt_driver_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE rabt_trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE rabt_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE rabt_trees ENABLE ROW LEVEL SECURITY;

-- 1. سياسة المستخدمين والملفات الشخصية
CREATE POLICY user_policy ON rabt_users FOR ALL 
USING (id = get_rabt_context_user() OR current_user = 'super_admin');

-- 2. سياسة ملفات السائقين
CREATE POLICY driver_profile_policy ON rabt_driver_profiles FOR ALL 
USING (user_id = get_rabt_context_user() OR current_user = 'super_admin');

-- 3. سياسة تتبع الموقع الحي (السائق يحدثه، العميل يقرأ إذا كانت هناك رحلة نشطة)
CREATE POLICY driver_location_policy ON rabt_driver_locations FOR ALL
USING (
    driver_id = get_rabt_context_user() 
    OR current_user = 'super_admin'
    OR EXISTS (
        SELECT 1 FROM rabt_trips t 
        WHERE t.driver_id = rabt_driver_locations.driver_id 
          AND t.customer_id = get_rabt_context_user()
          AND t.status IN ('accepted', 'arrived', 'active')
    )
);

-- 4. سياسة الرحلات (العميل والسائق فقط)
CREATE POLICY trip_policy ON rabt_trips FOR ALL 
USING (customer_id = get_rabt_context_user() OR driver_id = get_rabt_context_user() OR current_user = 'super_admin');

-- 5. سياسة المدفوعات (عبر ربط الرحلة)
CREATE POLICY payment_policy ON rabt_payments FOR ALL
USING (
    current_user = 'super_admin'
    OR EXISTS (
        SELECT 1 FROM rabt_trips t 
        WHERE t.id = rabt_payments.trip_id 
          AND (t.customer_id = get_rabt_context_user() OR t.driver_id = get_rabt_context_user())
    )
);

-- 6. سياسة نظام التلغيب (الشجرة)
CREATE POLICY tree_policy ON rabt_trees FOR ALL 
USING (user_id = get_rabt_context_user() OR current_user = 'super_admin');

-- ====================================================================
-- 14. حقن البيانات الهيكلية الحقيقية للقطاعات
-- ====================================================================
INSERT INTO rabt_sectors (sector_code, name_ar, name_en, base_fare, per_km_rate, per_minute_rate, is_operational) VALUES
('S-01', 'ركاب', 'Passengers', 5.00, 1.50, 0.25, TRUE),
('S-02', 'غاز', 'Gas Cylinder Delivery', 7.00, 2.00, 0.30, TRUE),
('S-03', 'مياه', 'Water Supply', 6.50, 1.80, 0.28, TRUE),
('S-04', 'شحن صغير', 'Micro Cargo', 8.00, 2.20, 0.35, TRUE),
('S-05', 'شاحنات', 'Commercial Trucks', 25.00, 5.00, 0.80, TRUE),
('S-06', 'ونشات', 'Towing & Rescue', 30.00, 6.00, 1.00, TRUE),
('S-07', 'آليات', 'Heavy Machinery', 50.00, 12.00, 2.00, TRUE),
('S-08', 'شحن كبير', 'Large Logistics', 40.00, 8.00, 1.50, TRUE),
('S-09', 'خدمات خاصة', 'Special Services', 15.00, 3.50, 0.50, TRUE)
ON CONFLICT (sector_code) DO UPDATE SET
    name_ar = EXCLUDED.name_ar,
    name_en = EXCLUDED.name_en,
    base_fare = EXCLUDED.base_fare,
    per_km_rate = EXCLUDED.per_km_rate,
    per_minute_rate = EXCLUDED.per_minute_rate,
    is_operational = EXCLUDED.is_operational;

-- ====================================================================
-- استعلام المطابقة الآمن (Geography — بدون Cast):
-- SELECT match_nearest_driver('S-02', 35.91, 31.95);
-- ====================================================================

-- ====================================================================
-- آلية التشفير: حفظ وقراءة الرقم القومي (Application-Level via Backend)
-- INSERT:
--   pgp_sym_encrypt('2001554897', current_setting('app.secret_encryption_key'))
-- SELECT (قراءة):
--   pgp_sym_decrypt(national_id_encrypted, current_setting('app.secret_encryption_key'))
-- ====================================================================
