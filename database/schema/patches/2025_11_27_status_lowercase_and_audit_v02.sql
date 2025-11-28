/* =========================================================
   LISTOWISP v02 – Patch
   File: 2025_11_27_status_lowercase_and_audit_v02.sql

   Goals:
   - Normalize status values to lowercase in key tables
   - Enforce lowercase status ENUM for users (known values)
   - Add created_by / updated_by to core business tables
   Notes:
   - Run AFTER importing the base v0.7.8 schema + services v2
   - Designed for a FRESH v02 DB (not a live prod DB)
   ========================================================= */

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------
-- 1. Normalize status values to lowercase across tables
--    (SAFE: will not break even if already lowercase)
-- ---------------------------------------------------------

-- Users
UPDATE users
SET status = LOWER(status)
WHERE status <> LOWER(status);

-- Customers (adjust table name if different)
UPDATE customers
SET status = LOWER(status)
WHERE status <> LOWER(status);

-- Accounts
UPDATE accounts
SET status = LOWER(status)
WHERE status <> LOWER(status);

-- Services
UPDATE services
SET status = LOWER(status)
WHERE status <> LOWER(status);

-- Modules (if they have a status column)
UPDATE modules
SET status = LOWER(status)
WHERE status <> LOWER(status);

-- License plans (if they have a status column)
UPDATE license_plans
SET status = LOWER(status)
WHERE status <> LOWER(status);

-- Company licenses (if they have a status column)
UPDATE company_licenses
SET status = LOWER(status)
WHERE status <> LOWER(status);

-- (Add more UPDATE ... LOWER(status) blocks here as you encounter other status fields)


-- ---------------------------------------------------------
-- 2. Enforce lowercase ENUM for users.status
--    (We KNOW v01 was ENUM('ACTIVE','DISABLED'))
--    v02 standard: ENUM('active','disabled')
-- ---------------------------------------------------------

ALTER TABLE users
    MODIFY COLUMN status ENUM('active','disabled')
        NOT NULL DEFAULT 'active';


-- ---------------------------------------------------------
-- 3. (TEMPLATES) Enforce lowercase ENUM for other tables
--    IMPORTANT:
--    - These are EXAMPLES; fill in the actual enum values
--      from your schema before uncommenting.
--    - You already ran the UPDATEs above, so the data will
--      match once the enum list is lowercase.
-- ---------------------------------------------------------

/*
-- Customers: example template
ALTER TABLE customers
    MODIFY COLUMN status ENUM('active','inactive','suspended','prospect')
        NOT NULL DEFAULT 'active';

-- Accounts: example template
ALTER TABLE accounts
    MODIFY COLUMN status ENUM('active','inactive','suspended','closed')
        NOT NULL DEFAULT 'active';

-- Services: example template
ALTER TABLE services
    MODIFY COLUMN status ENUM('pending','active','suspended','terminated')
        NOT NULL DEFAULT 'pending';

-- Modules: example template
ALTER TABLE modules
    MODIFY COLUMN status ENUM('active','inactive')
        NOT NULL DEFAULT 'active';

-- License plans: example template
ALTER TABLE license_plans
    MODIFY COLUMN status ENUM('active','inactive')
        NOT NULL DEFAULT 'active';

-- Company licenses: example template
ALTER TABLE company_licenses
    MODIFY COLUMN status ENUM('active','expired','suspended')
        NOT NULL DEFAULT 'active';
*/


-- ---------------------------------------------------------
-- 4. Add created_by / updated_by to key business tables
--    Pattern:
--      - Add BIGINT UNSIGNED columns
--      - Add FKs to users(id) with ON DELETE SET NULL
--    NOTE:
--      - Only do this where columns do not already exist
--      - If your MySQL/MariaDB version does not support
--        ADD COLUMN IF NOT EXISTS, remove that clause.
-- ---------------------------------------------------------

-- ACCOUNTS
ALTER TABLE accounts
    ADD COLUMN IF NOT EXISTS created_by BIGINT(20) UNSIGNED NULL AFTER tenant_id,
    ADD COLUMN IF NOT EXISTS updated_by BIGINT(20) UNSIGNED NULL AFTER created_by;

ALTER TABLE accounts
    ADD CONSTRAINT accounts_created_by_foreign
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT accounts_updated_by_foreign
        FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

-- LOCATIONS
ALTER TABLE locations
    ADD COLUMN IF NOT EXISTS created_by BIGINT(20) UNSIGNED NULL AFTER tenant_id,
    ADD COLUMN IF NOT EXISTS updated_by BIGINT(20) UNSIGNED NULL AFTER created_by;

ALTER TABLE locations
    ADD CONSTRAINT locations_created_by_foreign
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT locations_updated_by_foreign
        FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

-- SITES
ALTER TABLE sites
    ADD COLUMN IF NOT EXISTS created_by BIGINT(20) UNSIGNED NULL AFTER tenant_id,
    ADD COLUMN IF NOT EXISTS updated_by BIGINT(20) UNSIGNED NULL AFTER created_by;

ALTER TABLE sites
    ADD CONSTRAINT sites_created_by_foreign
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT sites_updated_by_foreign
        FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

-- PRODUCTS
ALTER TABLE products
    ADD COLUMN IF NOT EXISTS created_by BIGINT(20) UNSIGNED NULL AFTER tenant_id,
    ADD COLUMN IF NOT EXISTS updated_by BIGINT(20) UNSIGNED NULL AFTER created_by;

ALTER TABLE products
    ADD CONSTRAINT products_created_by_foreign
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT products_updated_by_foreign
        FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

-- SERVICES (base v1 or v2; adjust column positions if needed)
ALTER TABLE services
    ADD COLUMN IF NOT EXISTS created_by BIGINT(20) UNSIGNED NULL AFTER tenant_id,
    ADD COLUMN IF NOT EXISTS updated_by BIGINT(20) UNSIGNED NULL AFTER created_by;

ALTER TABLE services
    ADD CONSTRAINT services_created_by_foreign
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT services_updated_by_foreign
        FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

-- SERVICE_ORDERS (if present)
ALTER TABLE service_orders
    ADD COLUMN IF NOT EXISTS created_by BIGINT(20) UNSIGNED NULL AFTER tenant_id,
    ADD COLUMN IF NOT EXISTS updated_by BIGINT(20) UNSIGNED NULL AFTER created_by;

ALTER TABLE service_orders
    ADD CONSTRAINT service_orders_created_by_foreign
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT service_orders_updated_by_foreign
        FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

-- SITE_ENDPOINTS (optional)
ALTER TABLE site_endpoints
    ADD COLUMN IF NOT EXISTS created_by BIGINT(20) UNSIGNED NULL AFTER site_id,
    ADD COLUMN IF NOT EXISTS updated_by BIGINT(20) UNSIGNED NULL AFTER created_by;

ALTER TABLE site_endpoints
    ADD CONSTRAINT site_endpoints_created_by_foreign
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT site_endpoints_updated_by_foreign
        FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;


-- Add more tables as needed using the same pattern:
--   - charges, invoices, payments, etc. when they are added.


SET FOREIGN_KEY_CHECKS = 1;

