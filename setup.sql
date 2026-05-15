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
    month_year TEXT, -- YYYY-MM
    payment_method TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    note TEXT,
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
    note TEXT,
    date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

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

-- Policies for ywf_users: 
-- 1. Users can read their own profile
-- 2. Admins can read all profiles
-- 3. Only admins can update profiles
CREATE POLICY "Users can view own profile" ON ywf_users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Admins can view all profiles" ON ywf_users FOR SELECT USING (EXISTS (SELECT 1 FROM ywf_users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')));
CREATE POLICY "Admins can update profiles" ON ywf_users FOR UPDATE USING (EXISTS (SELECT 1 FROM ywf_users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')));

-- Policies for ywf_settings:
-- 1. Everyone can read settings
-- 2. Only super_admins can manage settings
CREATE POLICY "Anyone can read settings" ON ywf_settings FOR SELECT USING (true);
CREATE POLICY "Super admins can manage settings" ON ywf_settings FOR ALL USING (EXISTS (SELECT 1 FROM ywf_users WHERE id = auth.uid() AND role = 'super_admin'));

-- Policies for ywf_transactions:
-- 1. Users can read their own transactions
-- 2. Admins can manage all transactions
CREATE POLICY "Users can read own transactions" ON ywf_transactions FOR SELECT USING (auth.uid() = member_id);
CREATE POLICY "Admins can manage transactions" ON ywf_transactions FOR ALL USING (EXISTS (SELECT 1 FROM ywf_users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')));

-- Policies for ywf_fines:
-- 1. Users can read their own fines
-- 2. Admins can manage all fines
CREATE POLICY "Users can read own fines" ON ywf_fines FOR SELECT USING (auth.uid() = member_id);
CREATE POLICY "Admins can manage fines" ON ywf_fines FOR ALL USING (EXISTS (SELECT 1 FROM ywf_users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')));

-- Policies for Financial Tables (Profits, Expenses, Investments):
-- 1. Admins and Super Admins can manage
-- 2. Members can view (optional, depending on your needs)
CREATE POLICY "Admins can manage finance" ON ywf_profits FOR ALL USING (EXISTS (SELECT 1 FROM ywf_users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')));
CREATE POLICY "Admins can manage expenses" ON ywf_expenses FOR ALL USING (EXISTS (SELECT 1 FROM ywf_users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')));
CREATE POLICY "Admins can manage investments" ON ywf_investments FOR ALL USING (EXISTS (SELECT 1 FROM ywf_users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')));
CREATE POLICY "Members can view finance" ON ywf_profits FOR SELECT USING (true);
CREATE POLICY "Members can view expenses" ON ywf_expenses FOR SELECT USING (true);
CREATE POLICY "Members can view investments" ON ywf_investments FOR SELECT USING (true);

-- Policies for ywf_payment_requests:
-- 1. Users can create and read their own requests
-- 2. Admins can read and update all requests
CREATE POLICY "Users can handle own requests" ON ywf_payment_requests FOR ALL USING (auth.uid() = member_id);
CREATE POLICY "Admins can manage all requests" ON ywf_payment_requests FOR ALL USING (EXISTS (SELECT 1 FROM ywf_users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')));

-- Policies for ywf_audit_log:
-- 1. Only admins can read logs
CREATE POLICY "Only admins can view logs" ON ywf_audit_log FOR SELECT USING (EXISTS (SELECT 1 FROM ywf_users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')));
