-- Youngster Welfare Foundation Fund Management System
-- Supabase PostgreSQL Schema

-- 1. Users Table
CREATE TABLE IF NOT EXISTS ywf_users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    account_number TEXT,
    phone TEXT,
    role TEXT DEFAULT 'member' CHECK (role IN ('member', 'admin', 'super_admin')),
    is_active BOOLEAN DEFAULT true,
    photo_url TEXT,
    nid_number TEXT,
    nid_photo_url TEXT,
    address TEXT,
    dob DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Settings Table
CREATE TABLE IF NOT EXISTS ywf_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Transactions Table
CREATE TABLE IF NOT EXISTS ywf_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id UUID REFERENCES ywf_users(id) ON DELETE CASCADE,
    amount DECIMAL NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('deposit', 'profit', 'expense', 'investment')),
    date DATE DEFAULT CURRENT_DATE,
    month_year TEXT, -- YYYY-MM
    payment_method TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    note TEXT,
    ref_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Fines Table
CREATE TABLE IF NOT EXISTS ywf_fines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id UUID REFERENCES ywf_users(id) ON DELETE CASCADE,
    amount DECIMAL NOT NULL,
    reason TEXT NOT NULL,
    month_year TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid')),
    is_paid BOOLEAN DEFAULT false,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Profits Table
CREATE TABLE IF NOT EXISTS ywf_profits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    amount DECIMAL NOT NULL,
    investment_id UUID REFERENCES ywf_investments(id) ON DELETE SET NULL,
    month_year TEXT, -- YYYY-MM
    note TEXT,
    date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure columns exist if table was created earlier
ALTER TABLE ywf_profits ADD COLUMN IF NOT EXISTS investment_id UUID REFERENCES ywf_investments(id) ON DELETE SET NULL;
ALTER TABLE ywf_profits ADD COLUMN IF NOT EXISTS month_year TEXT;

-- 6. Expenses Table
CREATE TABLE IF NOT EXISTS ywf_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    amount DECIMAL NOT NULL,
    note TEXT,
    date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Investments Table
CREATE TABLE IF NOT EXISTS ywf_investments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    amount DECIMAL NOT NULL,
    name TEXT, -- Added for descriptive naming
    image_url TEXT, -- Added for proof/photo
    note TEXT,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed')),
    date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Payment Requests Table
CREATE TABLE IF NOT EXISTS ywf_payment_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id UUID REFERENCES ywf_users(id) ON DELETE CASCADE,
    amount DECIMAL NOT NULL,
    type TEXT CHECK (type IN ('deposit', 'fine')),
    month_year TEXT,
    payment_method TEXT,
    note TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    processed_by UUID REFERENCES ywf_users(id),
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure columns exist if tables were created earlier
ALTER TABLE ywf_users ADD COLUMN IF NOT EXISTS nid_number TEXT;
ALTER TABLE ywf_users ADD COLUMN IF NOT EXISTS nid_photo_url TEXT;
ALTER TABLE ywf_users ADD COLUMN IF NOT EXISTS dob DATE;
ALTER TABLE ywf_users ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE ywf_users ADD COLUMN IF NOT EXISTS photo_url TEXT;

ALTER TABLE ywf_payment_requests ADD COLUMN IF NOT EXISTS type TEXT CHECK (type IN ('deposit', 'fine'));
ALTER TABLE ywf_payment_requests ADD COLUMN IF NOT EXISTS month_year TEXT;
ALTER TABLE ywf_payment_requests ADD COLUMN IF NOT EXISTS payment_method TEXT;
ALTER TABLE ywf_payment_requests ADD COLUMN IF NOT EXISTS transaction_id TEXT;
ALTER TABLE ywf_payment_requests ADD COLUMN IF NOT EXISTS note TEXT;
ALTER TABLE ywf_payment_requests ADD COLUMN IF NOT EXISTS processed_by UUID REFERENCES ywf_users(id);
ALTER TABLE ywf_payment_requests ADD COLUMN IF NOT EXISTS processed_at TIMESTAMPTZ;

ALTER TABLE ywf_fines ADD COLUMN IF NOT EXISTS reason TEXT;
ALTER TABLE ywf_fines ADD COLUMN IF NOT EXISTS is_paid BOOLEAN DEFAULT false;
ALTER TABLE ywf_fines ADD COLUMN IF NOT EXISTS paid_at TIMESTAMPTZ;
ALTER TABLE ywf_fines ADD COLUMN IF NOT EXISTS month_year TEXT;

-- Ensure financial tables have date column
ALTER TABLE ywf_investments ADD COLUMN IF NOT EXISTS date DATE DEFAULT CURRENT_DATE;
ALTER TABLE ywf_profits ADD COLUMN IF NOT EXISTS date DATE DEFAULT CURRENT_DATE;
ALTER TABLE ywf_expenses ADD COLUMN IF NOT EXISTS date DATE DEFAULT CURRENT_DATE;

-- 9. Audit Logs Table
CREATE TABLE IF NOT EXISTS ywf_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES ywf_users(id),
    user_email TEXT,
    action TEXT NOT NULL,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Initial Settings
INSERT INTO ywf_settings (key, value) VALUES 
('monthly_deposit', '1000'),
('fine_after_10', '20'),
('fine_after_20', '30'),
('bkash', '01XXXXXXXXX'),
('nagad', '01XXXXXXXXX'),
('rocket', '01XXXXXXXXX'),
('admin_contact', '01XXXXXXXXX')
ON CONFLICT (key) DO NOTHING;

-- Ensure super_admin role for the foundation email
-- This uses an upsert pattern if possible, or just ensures the existing record is updated
DO $$
BEGIN
  -- If record exists, make sure it's a super_admin
  UPDATE ywf_users SET role = 'super_admin' WHERE email IN ('youngsterwelfarefoundationywf@gmail.com', 'risevoiceforchange2025@gmail.com');
END $$;

-- Refresh the PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- 10. Enable Row Level Security (RLS)
ALTER TABLE ywf_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE ywf_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE ywf_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ywf_fines ENABLE ROW LEVEL SECURITY;
ALTER TABLE ywf_profits ENABLE ROW LEVEL SECURITY;
ALTER TABLE ywf_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE ywf_investments ENABLE ROW LEVEL SECURITY;
ALTER TABLE ywf_payment_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE ywf_audit_log ENABLE ROW LEVEL SECURITY;

-- 11. Define Policies

-- Security Definer Functions to avoid RLS recursion
CREATE OR REPLACE FUNCTION is_admin() RETURNS boolean AS $$
DECLARE
  current_role text;
  caller_email text;
BEGIN
  -- Get email from JWT
  caller_email := lower(COALESCE(auth.jwt() ->> 'email', ''));
  
  -- Bypass for foundation emails
  IF caller_email IN ('youngsterwelfarefoundationywf@gmail.com', 'risevoiceforchange2025@gmail.com') THEN
    RETURN true;
  END IF;

  -- Get role directly bypassing RLS via SECURITY DEFINER
  SELECT role INTO current_role FROM ywf_users WHERE id = auth.uid();
  
  RETURN current_role IN ('admin', 'super_admin');
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_super_admin() RETURNS boolean AS $$
DECLARE
  current_role text;
  caller_email text;
BEGIN
  -- Get email from JWT
  caller_email := lower(COALESCE(auth.jwt() ->> 'email', ''));
  
  -- Bypass for foundation emails
  IF caller_email IN ('youngsterwelfarefoundationywf@gmail.com', 'risevoiceforchange2025@gmail.com') THEN
    RETURN true;
  END IF;

  -- Get role directly bypassing RLS via SECURITY DEFINER
  SELECT role INTO current_role FROM ywf_users WHERE id = auth.uid();
  
  RETURN current_role = 'super_admin';
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Policies for ywf_users: 
DROP POLICY IF EXISTS "Users view own profile" ON ywf_users;
DROP POLICY IF EXISTS "Users insert own profile" ON ywf_users;
DROP POLICY IF EXISTS "Users update own profile" ON ywf_users;
DROP POLICY IF EXISTS "Admins manage all" ON ywf_users;
DROP POLICY IF EXISTS "Foundation Bypass Policy" ON ywf_users;

-- Explicit policy for Foundation Admin bypass with casing safety
CREATE POLICY "Foundation Bypass Policy" ON ywf_users 
FOR ALL 
USING (lower(COALESCE(auth.jwt() ->> 'email', '')) IN ('youngsterwelfarefoundationywf@gmail.com', 'risevoiceforchange2025@gmail.com'))
WITH CHECK (lower(COALESCE(auth.jwt() ->> 'email', '')) IN ('youngsterwelfarefoundationywf@gmail.com', 'risevoiceforchange2025@gmail.com'));

-- General policies
CREATE POLICY "Users view own profile" ON ywf_users 
FOR SELECT USING (
  auth.uid() = id 
  OR 
  lower(email) = lower(COALESCE(auth.jwt() ->> 'email', ''))
);

CREATE POLICY "Users insert own profile" ON ywf_users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users update own profile" ON ywf_users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins manage all" ON ywf_users FOR ALL USING ( is_admin() );

-- Policies for ywf_settings:
CREATE POLICY "Settings are viewable by everyone" ON ywf_settings FOR SELECT USING (true);
CREATE POLICY "Settings are manageable by super admins_v3" ON ywf_settings FOR ALL USING ( is_super_admin() );

-- Policies for ywf_transactions:
CREATE POLICY "Users can read own transactions" ON ywf_transactions FOR SELECT USING (auth.uid() = member_id);
CREATE POLICY "Admins can manage transactions_v3" ON ywf_transactions FOR ALL USING ( is_admin() );

-- Policies for ywf_fines:
CREATE POLICY "Users can read own fines" ON ywf_fines FOR SELECT USING (auth.uid() = member_id);
CREATE POLICY "Admins can manage fines_v3" ON ywf_fines FOR ALL USING ( is_admin() );

-- Policies for Financial Tables:
CREATE POLICY "Admins can manage finance_v3" ON ywf_profits FOR ALL USING ( is_admin() );
CREATE POLICY "Admins can manage expenses_v3" ON ywf_expenses FOR ALL USING ( is_admin() );
CREATE POLICY "Admins can manage investments_v3" ON ywf_investments FOR ALL USING ( is_admin() );
CREATE POLICY "Members can view finance" ON ywf_profits FOR SELECT USING (true);
CREATE POLICY "Members can view expenses" ON ywf_expenses FOR SELECT USING (true);
CREATE POLICY "Members can view investments" ON ywf_investments FOR SELECT USING (true);

-- Policies for ywf_payment_requests:
CREATE POLICY "Users can handle own requests" ON ywf_payment_requests FOR ALL USING (auth.uid() = member_id);
CREATE POLICY "Admins can manage all requests_v3" ON ywf_payment_requests FOR ALL USING ( is_admin() );

-- Policies for ywf_audit_log:
CREATE POLICY "Only admins can view logs_v3" ON ywf_audit_log FOR SELECT USING ( is_admin() );
CREATE POLICY "Only super admins can delete logs" ON ywf_audit_log FOR DELETE USING ( is_super_admin() );

-- Ensure all required columns and constraints exist
ALTER TABLE ywf_audit_log ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES ywf_users(id);
ALTER TABLE ywf_profits ADD COLUMN IF NOT EXISTS investment_id UUID REFERENCES ywf_investments(id) ON DELETE SET NULL;
ALTER TABLE ywf_profits ADD COLUMN IF NOT EXISTS month_year TEXT;
