/* =========================================================
   LISTOWISP v02 – Core Minimal Seed
   File: seed_core_minimal_v02.sql

   Run on a fresh v02 database AFTER:
   - 010_base_schema_v02.sql
   - 020_services_v02.sql
   - patches (incl. status/audit patch)
   ========================================================= */

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------
-- 1) TENANT
-- ---------------------------------------------------------

INSERT INTO tenants (
    id, name, code,
    grace_days_postpaid, grace_days_prepaid, tax_rate,
    created_at, updated_at
) VALUES (
    1,
    'LISTOWISP Demo Tenant',
    'tenant01',
    7,
    2,
    0.0000,
    NOW(), NOW()
)
ON DUPLICATE KEY UPDATE
    name = VALUES(name),
    grace_days_postpaid = VALUES(grace_days_postpaid),
    grace_days_prepaid = VALUES(grace_days_prepaid),
    tax_rate = VALUES(tax_rate),
    updated_at = VALUES(updated_at);

-- ---------------------------------------------------------
-- 2) COMPANY (core billing profile)
-- ---------------------------------------------------------

INSERT INTO companies (
    id,
    tenant_id,
    legal_name,
    trading_name,
    tax_id,
    email_from,
    currency,
    time_zone,
    next_invoice_number,
    invoice_terms_days,
    tax_display,
    created_at,
    updated_at
) VALUES (
    1,
    1,
    'LISTOWISP Demo ISP',
    'LISTOWISP',
    'JMD000000',
    'no-reply@listowisp.pro',
    'USD',
    'America/Santo_Domingo',
    1,
    14,
    'exclusive',
    NOW(),
    NOW()
)
ON DUPLICATE KEY UPDATE
    legal_name = VALUES(legal_name),
    trading_name = VALUES(trading_name),
    tax_id = VALUES(tax_id),
    email_from = VALUES(email_from),
    currency = VALUES(currency),
    time_zone = VALUES(time_zone),
    updated_at = VALUES(updated_at);

-- ---------------------------------------------------------
-- 3) ADMIN USER (tenant-level)
--    Password = "password"
--    Hash = standard Laravel bcrypt hash
-- ---------------------------------------------------------

INSERT INTO users (
    id,
    tenant_id,
    name,
    email,
    phone,
    status,
    email_verified_at,
    password,
    last_login_at,
    failed_login_count,
    created_at,
    updated_at
) VALUES (
    1,
    1,
    'System Administrator',
    'admin@listowisp.pro',
    '+1 876 000 0000',
    'active',
    NOW(),
    -- Laravel default hash for "password"
    '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    NULL,
    0,
    NOW(),
    NOW()
)
ON DUPLICATE KEY UPDATE
    tenant_id = VALUES(tenant_id),
    name = VALUES(name),
    phone = VALUES(phone),
    status = VALUES(status),
    updated_at = VALUES(updated_at);

-- ---------------------------------------------------------
-- 4) ADDRESS for the company
-- ---------------------------------------------------------

-- We assume App\Models\Company as the morph type.
INSERT INTO addresses (
    id,
    tenant_id,
    addressable_type,
    addressable_id,
    label,
    is_primary,
    line1,
    line2,
    city,
    region,
    postal_code,
    country,
    created_by,
    updated_by,
    created_at,
    updated_at
) VALUES (
    1,
    1,
    'App\\Models\\Company',
    1,
    'Head Office',
    1,
    '123 Demo Street',
    NULL,
    'Santo Domingo',
    'DN',
    '00000',
    'DO',
    1,
    1,
    NOW(),
    NOW()
)
ON DUPLICATE KEY UPDATE
    line1 = VALUES(line1),
    city = VALUES(city),
    region = VALUES(region),
    postal_code = VALUES(postal_code),
    country = VALUES(country),
    updated_by = VALUES(updated_by),
    updated_at = VALUES(updated_at);

-- Link company to its primary address (if not already linked)
UPDATE companies
SET address_id = 1
WHERE id = 1
  AND (address_id IS NULL OR address_id = 0);

-- ---------------------------------------------------------
-- 5) ROLES
-- ---------------------------------------------------------

INSERT INTO roles (id, name, guard_name, created_at, updated_at) VALUES
    (1, 'super_admin', 'web', NOW(), NOW())
ON DUPLICATE KEY UPDATE
    guard_name = VALUES(guard_name),
    updated_at = VALUES(updated_at);

-- ---------------------------------------------------------
-- 6) PERMISSIONS (minimal set)
-- ---------------------------------------------------------

INSERT INTO permissions (id, name, guard_name, created_at, updated_at) VALUES
    (1, 'dashboard.view',  'web', NOW(), NOW()),
    (2, 'users.manage',    'web', NOW(), NOW()),
    (3, 'settings.manage', 'web', NOW(), NOW()),
    (4, 'billing.manage',  'web', NOW(), NOW()),
    (5, 'network.manage',  'web', NOW(), NOW())
ON DUPLICATE KEY UPDATE
    guard_name = VALUES(guard_name),
    updated_at = VALUES(updated_at);

-- ---------------------------------------------------------
-- 7) ROLE ↔ PERMISSION mapping
--    super_admin gets all the above permissions
-- ---------------------------------------------------------

-- Clear any existing mappings for role 1 (optional but safe on fresh DB)
DELETE FROM role_has_permissions WHERE role_id = 1;

INSERT INTO role_has_permissions (permission_id, role_id) VALUES
    (1, 1),
    (2, 1),
    (3, 1),
    (4, 1),
    (5, 1);

-- ---------------------------------------------------------
-- 8) USER ↔ ROLE mapping
--    user #1 is super_admin
-- ---------------------------------------------------------

-- Remove any existing roles for this user in case of re-seed
DELETE FROM model_has_roles
WHERE model_type = 'App\\Models\\User'
  AND model_id = 1;

INSERT INTO model_has_roles (role_id, model_type, model_id) VALUES
    (1, 'App\\Models\\User', 1);

SET FOREIGN_KEY_CHECKS = 1;

