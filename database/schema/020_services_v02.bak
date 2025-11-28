DROP TABLE IF EXISTS service_resources;
DROP TABLE IF EXISTS services;

-- New services table (your proposed design)
CREATE TABLE IF NOT EXISTS services (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tenant_id BIGINT UNSIGNED NOT NULL DEFAULT 1,
  account_id BIGINT UNSIGNED NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  location_id BIGINT UNSIGNED NULL,
  site_id BIGINT UNSIGNED NULL,
  site_endpoint_id BIGINT UNSIGNED NULL,

  service_number VARCHAR(32) NOT NULL,
  external_ref VARCHAR(64) NULL,
  tags JSON NULL,

  service_kind ENUM('recurring','onceoff','usage','bundle','addon') NOT NULL DEFAULT 'recurring',
  billing_model ENUM('prepaid','postpaid') NOT NULL DEFAULT 'postpaid',
  enforcement_mode ENUM('auto','manual_only') NOT NULL DEFAULT 'auto',

  status ENUM('pending','active','suspended','terminated','completed','cancelled','dunning') NOT NULL DEFAULT 'pending',
  dunning_state ENUM('none','grace','soft_suspend','hard_suspend','terminated') NOT NULL DEFAULT 'none',
  grace_until DATETIME NULL,
  activated_at DATETIME NULL,
  suspended_at DATETIME NULL,
  terminated_at DATETIME NULL,

  cycle_anchor DATE NULL,
  recurring_type ENUM('monthly','quarterly','biannual','annual') NULL,
  recurring_anchor ENUM('purchase_date','specific_day') NULL,
  specific_day TINYINT UNSIGNED NULL,

  next_invoice_date DATE NULL,

  price_snapshot DECIMAL(12,2) NULL,
  setup_fee DECIMAL(12,2) NULL,
  tax_code_snapshot VARCHAR(32) NULL,
  currency CHAR(3) NOT NULL DEFAULT 'USD',
  discount_percent DECIMAL(5,2) NULL,
  credit_limit DECIMAL(12,2) NULL,
  deposit DECIMAL(12,2) NULL,

  price_overrides_json JSON NULL,
  provisioning_json JSON NULL,

  speed_profile VARCHAR(64) NULL,
  ip_assignment JSON NULL,
  mac_address VARBINARY(6) NULL,
  nas_identifier VARCHAR(128) NULL,
  auth_username VARCHAR(128) NULL,
  auth_secret_encrypted TEXT NULL,

  coe_policy VARCHAR(64) NULL,
  allowance_policy VARCHAR(64) NULL,
  allowance_state JSON NULL,

  notes TEXT NULL,
  last_provisioned_at DATETIME NULL,
  last_enforcement_at DATETIME NULL,
  health_status ENUM('ok','warning','error') NOT NULL DEFAULT 'ok',

  created_by BIGINT UNSIGNED NULL,
  updated_by BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  UNIQUE KEY ux_services_number (service_number),
  KEY idx_services_account (account_id),
  KEY idx_services_customer (customer_id),
  KEY idx_services_product (product_id),
  KEY idx_services_status (status),
  KEY idx_services_dunning (dunning_state),
  KEY idx_services_next_invoice (next_invoice_date),
  KEY idx_services_site (site_id),
  KEY idx_services_location (location_id)
);

