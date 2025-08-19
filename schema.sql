-- USERS
CREATE TABLE users (
    id TEXT PRIMARY KEY,               -- UUID
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT,                -- only if not using Clerk/SSO
    auth_provider TEXT NOT NULL,       -- 'clerk', 'google', 'microsoft', etc.
    role TEXT NOT NULL DEFAULT 'owner', -- 'owner', 'accountant', 'staff'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- BUSINESSES
CREATE TABLE businesses (
    id TEXT PRIMARY KEY,               -- UUID
    user_id TEXT NOT NULL,             -- Owner
    name TEXT NOT NULL,
    industry TEXT,
    currency TEXT NOT NULL DEFAULT 'USD',
    fiscal_year_start DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- TRANSACTIONS (normalized CSV/QuickBooks/Xero data)
CREATE TABLE transactions (
    id TEXT PRIMARY KEY,               -- UUID
    business_id TEXT NOT NULL,
    date DATE NOT NULL,
    description TEXT,
    category TEXT,                     -- e.g. 'Revenue', 'Expense', 'Payroll'
    amount DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (business_id) REFERENCES businesses(id)
);

-- REPORTS (generated outputs)
CREATE TABLE reports (
    id TEXT PRIMARY KEY,
    business_id TEXT NOT NULL,
    type TEXT NOT NULL,                -- 'P&L', 'Balance Sheet', 'Cash Flow'
    file_url TEXT,                     -- Link to R2 storage
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (business_id) REFERENCES businesses(id)
);

-- ALERTS (system notifications)
CREATE TABLE alerts (
    id TEXT PRIMARY KEY,
    business_id TEXT NOT NULL,
    message TEXT NOT NULL,
    severity TEXT CHECK(severity IN ('info', 'warning', 'critical')) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved BOOLEAN DEFAULT 0,
    FOREIGN KEY (business_id) REFERENCES businesses(id)
);

-- INTEGRATIONS (QuickBooks, Xero, etc.)
CREATE TABLE integrations (
    id TEXT PRIMARY KEY,
    business_id TEXT NOT NULL,
    provider TEXT NOT NULL,            -- 'quickbooks', 'xero'
    access_token TEXT NOT NULL,
    refresh_token TEXT,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (business_id) REFERENCES businesses(id)
);

-- Users
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('owner','admin','viewer')),
  business_id TEXT NOT NULL,
  FOREIGN KEY (business_id) REFERENCES businesses(id)
);

-- Business table (if not already exists)
CREATE TABLE businesses (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Invitations
CREATE TABLE invitations (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL,
  email TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin','viewer')),
  token TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  accepted BOOLEAN DEFAULT 0,
  FOREIGN KEY (business_id) REFERENCES businesses(id)
);