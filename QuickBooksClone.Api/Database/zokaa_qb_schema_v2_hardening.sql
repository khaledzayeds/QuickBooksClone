-- ================================================================
-- ZOKAA QuickBooks Clone Schema v2 Hardening
-- Apply after: zokaa_qb_complete_schema.sql
-- Target: MySQL 8.0.29+ / MariaDB 10.5+
--
-- This migration keeps your current 83-table schema and adds the
-- foundations that are painful to add later: multi-company tenancy,
-- permissions, document numbering, posting lifecycle, idempotent API
-- writes, attachments, activity history, projects, inventory ledger,
-- richer taxes, reconciliation improvements, and approval workflows.
-- ================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DELIMITER $$

DROP PROCEDURE IF EXISTS zq_add_column_if_missing $$
CREATE PROCEDURE zq_add_column_if_missing(
    IN p_table_name VARCHAR(128),
    IN p_column_name VARCHAR(128),
    IN p_column_definition TEXT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name = p_table_name
          AND column_name = p_column_name
    ) THEN
        SET @sql = CONCAT('ALTER TABLE `', p_table_name, '` ADD COLUMN ', p_column_definition);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END $$

DROP PROCEDURE IF EXISTS zq_add_index_if_missing $$
CREATE PROCEDURE zq_add_index_if_missing(
    IN p_table_name VARCHAR(128),
    IN p_index_name VARCHAR(128),
    IN p_index_definition TEXT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.statistics
        WHERE table_schema = DATABASE()
          AND table_name = p_table_name
          AND index_name = p_index_name
    ) THEN
        SET @sql = CONCAT('ALTER TABLE `', p_table_name, '` ADD ', p_index_definition);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END $$

DROP PROCEDURE IF EXISTS zq_add_fk_if_missing $$
CREATE PROCEDURE zq_add_fk_if_missing(
    IN p_table_name VARCHAR(128),
    IN p_constraint_name VARCHAR(128),
    IN p_fk_definition TEXT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE table_schema = DATABASE()
          AND table_name = p_table_name
          AND constraint_name = p_constraint_name
          AND constraint_type = 'FOREIGN KEY'
    ) THEN
        SET @sql = CONCAT('ALTER TABLE `', p_table_name, '` ADD CONSTRAINT `', p_constraint_name, '` ', p_fk_definition);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END $$

DELIMITER ;

-- ================================================================
-- 1) TENANCY / COMPANY MODEL
-- ================================================================

CREATE TABLE IF NOT EXISTS companies (
    id                 INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_name       VARCHAR(200) NOT NULL,
    legal_name         VARCHAR(200),
    tax_number         VARCHAR(50),
    base_currency      CHAR(3)      NOT NULL DEFAULT 'EGP',
    locale             VARCHAR(20)  NOT NULL DEFAULT 'en-EG',
    timezone           VARCHAR(80)  NOT NULL DEFAULT 'Africa/Cairo',
    fiscal_year_start  TINYINT      NOT NULL DEFAULT 1,
    accounting_method  ENUM('cash','accrual') NOT NULL DEFAULT 'accrual',
    is_active          TINYINT(1)   NOT NULL DEFAULT 1,
    created_at         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_companies_tax_number (tax_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO companies (id, company_name, legal_name, tax_number, base_currency, fiscal_year_start, accounting_method)
SELECT 1, company_name, legal_name, tax_number, base_currency, fiscal_year_start, accounting_method
FROM company_settings
WHERE NOT EXISTS (SELECT 1 FROM companies WHERE id = 1)
LIMIT 1;

INSERT INTO companies (id, company_name)
SELECT 1, 'Default Company'
WHERE NOT EXISTS (SELECT 1 FROM companies WHERE id = 1);

CALL zq_add_column_if_missing('company_settings', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
UPDATE company_settings SET company_id = 1 WHERE company_id IS NULL;
CALL zq_add_index_if_missing('company_settings', 'idx_company_settings_company', 'INDEX `idx_company_settings_company` (`company_id`)');
CALL zq_add_fk_if_missing('company_settings', 'fk_company_settings_company', 'FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE');

-- Tenant columns are nullable for safe migration. On a fresh production
-- database we can make them NOT NULL after default seeding.
CALL zq_add_column_if_missing('fiscal_years', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('fiscal_periods', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('payment_terms', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('users', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('roles', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('audit_log', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('chart_of_accounts', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('classes', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('locations', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('tags', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('customers', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('vendors', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('item_categories', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('units_of_measure', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('items', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('price_levels', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('inventory_locations', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('inventory_stock', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('inventory_adjustments', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('inventory_transfers', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('assemblies', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('transactions', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('journal_entries', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('recurring_transactions', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('estimates', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('sales_orders', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('invoices', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('customer_payments', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('credit_memos', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('deposits', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('purchase_orders', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('item_receipts', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('bills', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('bill_payments', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('expenses', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('vendor_credits', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('bank_accounts', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('bank_transfers', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('bank_imported_txn', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('bank_rules', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('reconciliations', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('fixed_assets', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('budgets', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('employees', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('pay_categories', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('pay_schedules', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('pay_runs', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');
CALL zq_add_column_if_missing('leave_types', 'company_id', '`company_id` INT UNSIGNED NULL AFTER `id`');

-- ================================================================
-- 2) API / SECURITY / PERMISSIONS
-- ================================================================

CREATE TABLE IF NOT EXISTS permissions (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code           VARCHAR(120) NOT NULL UNIQUE,
    module         VARCHAR(60)  NOT NULL,
    description    VARCHAR(255),
    is_system      TINYINT(1)   NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS role_permissions (
    role_id        INT UNSIGNED NOT NULL,
    permission_id  INT UNSIGNED NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id)       REFERENCES roles(id)       ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id     INT UNSIGNED,
    user_id        INT UNSIGNED NOT NULL,
    token_hash     CHAR(64)     NOT NULL UNIQUE,
    expires_at     DATETIME     NOT NULL,
    revoked_at     DATETIME,
    replaced_by_id BIGINT UNSIGNED,
    created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address     VARCHAR(45),
    user_agent     VARCHAR(500),
    FOREIGN KEY (company_id)     REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id)        REFERENCES users(id)     ON DELETE CASCADE,
    FOREIGN KEY (replaced_by_id) REFERENCES refresh_tokens(id) ON DELETE SET NULL,
    INDEX idx_refresh_user (user_id),
    INDEX idx_refresh_expiry (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS api_clients (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id     INT UNSIGNED,
    name           VARCHAR(150) NOT NULL,
    client_key     VARCHAR(80)  NOT NULL UNIQUE,
    secret_hash    VARCHAR(255),
    is_active      TINYINT(1)   NOT NULL DEFAULT 1,
    created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS idempotency_keys (
    id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id       INT UNSIGNED,
    user_id          INT UNSIGNED,
    idempotency_key  VARCHAR(120) NOT NULL,
    request_method   VARCHAR(10)  NOT NULL,
    request_path     VARCHAR(300) NOT NULL,
    request_hash     CHAR(64)     NOT NULL,
    response_status  SMALLINT,
    response_body    JSON,
    locked_until     DATETIME,
    created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at       DATETIME     NOT NULL,
    UNIQUE KEY uq_idempotency_scope (company_id, idempotency_key),
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id)    REFERENCES users(id)     ON DELETE SET NULL,
    INDEX idx_idempotency_expiry (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ================================================================
-- 3) COMMON ENTITY INFRASTRUCTURE
-- ================================================================

CREATE TABLE IF NOT EXISTS document_sequences (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id      INT UNSIGNED NOT NULL,
    document_type   VARCHAR(60)  NOT NULL,
    fiscal_year_id  INT UNSIGNED,
    prefix          VARCHAR(20)  NOT NULL DEFAULT '',
    suffix          VARCHAR(20)  NOT NULL DEFAULT '',
    next_number     BIGINT UNSIGNED NOT NULL DEFAULT 1,
    padding         TINYINT      NOT NULL DEFAULT 6,
    reset_policy    ENUM('never','fiscal_year','calendar_year','monthly') NOT NULL DEFAULT 'never',
    is_active       TINYINT(1)   NOT NULL DEFAULT 1,
    UNIQUE KEY uq_doc_sequence (company_id, document_type, fiscal_year_id),
    FOREIGN KEY (company_id)     REFERENCES companies(id)    ON DELETE CASCADE,
    FOREIGN KEY (fiscal_year_id) REFERENCES fiscal_years(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS attachments (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id      INT UNSIGNED,
    entity_type     VARCHAR(80)  NOT NULL,
    entity_id       BIGINT UNSIGNED NOT NULL,
    file_name       VARCHAR(255) NOT NULL,
    storage_path    VARCHAR(700) NOT NULL,
    content_type    VARCHAR(120),
    file_size_bytes BIGINT UNSIGNED,
    sha256_hash     CHAR(64),
    uploaded_by     INT UNSIGNED,
    uploaded_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at      DATETIME,
    FOREIGN KEY (company_id)  REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES users(id)     ON DELETE SET NULL,
    INDEX idx_attachments_entity (company_id, entity_type, entity_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS entity_notes (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id  INT UNSIGNED,
    entity_type VARCHAR(80)  NOT NULL,
    entity_id   BIGINT UNSIGNED NOT NULL,
    note        TEXT         NOT NULL,
    is_pinned   TINYINT(1)   NOT NULL DEFAULT 0,
    created_by  INT UNSIGNED,
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id)     ON DELETE SET NULL,
    INDEX idx_notes_entity (company_id, entity_type, entity_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS activity_events (
    id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id    INT UNSIGNED,
    actor_user_id INT UNSIGNED,
    entity_type   VARCHAR(80)  NOT NULL,
    entity_id     BIGINT UNSIGNED NOT NULL,
    event_type    VARCHAR(80)  NOT NULL,
    event_data    JSON,
    occurred_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id)    REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (actor_user_id) REFERENCES users(id)     ON DELETE SET NULL,
    INDEX idx_activity_entity (company_id, entity_type, entity_id),
    INDEX idx_activity_time (occurred_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS custom_field_definitions (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id   INT UNSIGNED NOT NULL,
    entity_type  VARCHAR(80)  NOT NULL,
    field_key    VARCHAR(80)  NOT NULL,
    label        VARCHAR(150) NOT NULL,
    data_type    ENUM('text','number','date','boolean','select') NOT NULL DEFAULT 'text',
    options_json JSON,
    is_required  TINYINT(1)   NOT NULL DEFAULT 0,
    is_active    TINYINT(1)   NOT NULL DEFAULT 1,
    UNIQUE KEY uq_custom_field (company_id, entity_type, field_key),
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS custom_field_values (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id           INT UNSIGNED NOT NULL,
    field_definition_id  INT UNSIGNED NOT NULL,
    entity_type          VARCHAR(80) NOT NULL,
    entity_id            BIGINT UNSIGNED NOT NULL,
    value_text           TEXT,
    value_number         DECIMAL(20,6),
    value_date           DATE,
    value_boolean        TINYINT(1),
    FOREIGN KEY (company_id)          REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (field_definition_id) REFERENCES custom_field_definitions(id) ON DELETE CASCADE,
    INDEX idx_custom_value_entity (company_id, entity_type, entity_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CALL zq_add_column_if_missing('customers', 'created_by', '`created_by` INT UNSIGNED NULL');
CALL zq_add_column_if_missing('customers', 'updated_at', '`updated_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP');
CALL zq_add_column_if_missing('customers', 'deleted_at', '`deleted_at` DATETIME NULL');
CALL zq_add_column_if_missing('customers', 'row_version', '`row_version` BIGINT UNSIGNED NOT NULL DEFAULT 1');
CALL zq_add_column_if_missing('vendors', 'created_by', '`created_by` INT UNSIGNED NULL');
CALL zq_add_column_if_missing('vendors', 'updated_at', '`updated_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP');
CALL zq_add_column_if_missing('vendors', 'deleted_at', '`deleted_at` DATETIME NULL');
CALL zq_add_column_if_missing('vendors', 'row_version', '`row_version` BIGINT UNSIGNED NOT NULL DEFAULT 1');
CALL zq_add_column_if_missing('items', 'created_by', '`created_by` INT UNSIGNED NULL');
CALL zq_add_column_if_missing('items', 'updated_at', '`updated_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP');
CALL zq_add_column_if_missing('items', 'deleted_at', '`deleted_at` DATETIME NULL');
CALL zq_add_column_if_missing('items', 'row_version', '`row_version` BIGINT UNSIGNED NOT NULL DEFAULT 1');
CALL zq_add_column_if_missing('transactions', 'updated_at', '`updated_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP');
CALL zq_add_column_if_missing('transactions', 'deleted_at', '`deleted_at` DATETIME NULL');
CALL zq_add_column_if_missing('transactions', 'row_version', '`row_version` BIGINT UNSIGNED NOT NULL DEFAULT 1');

-- ================================================================
-- 4) ACCOUNTING POSTING / VOIDING MODEL
-- ================================================================

CALL zq_add_column_if_missing('transactions', 'source_entity_type', '`source_entity_type` VARCHAR(80) NULL AFTER `txn_type`');
CALL zq_add_column_if_missing('transactions', 'source_entity_id', '`source_entity_id` BIGINT UNSIGNED NULL AFTER `source_entity_type`');
CALL zq_add_column_if_missing('transactions', 'posted_at', '`posted_at` DATETIME NULL AFTER `status`');
CALL zq_add_column_if_missing('transactions', 'posted_by', '`posted_by` INT UNSIGNED NULL AFTER `posted_at`');
CALL zq_add_column_if_missing('transactions', 'voided_at', '`voided_at` DATETIME NULL AFTER `posted_by`');
CALL zq_add_column_if_missing('transactions', 'voided_by', '`voided_by` INT UNSIGNED NULL AFTER `voided_at`');
CALL zq_add_column_if_missing('transactions', 'void_reason', '`void_reason` VARCHAR(500) NULL AFTER `voided_by`');
CALL zq_add_column_if_missing('transactions', 'reversal_txn_id', '`reversal_txn_id` INT UNSIGNED NULL AFTER `void_reason`');
CALL zq_add_column_if_missing('transactions', 'lock_date_override_reason', '`lock_date_override_reason` VARCHAR(500) NULL');
CALL zq_add_index_if_missing('transactions', 'idx_txn_company_date', 'INDEX `idx_txn_company_date` (`company_id`, `txn_date`)');
CALL zq_add_index_if_missing('transactions', 'idx_txn_source', 'INDEX `idx_txn_source` (`source_entity_type`, `source_entity_id`)');
CALL zq_add_fk_if_missing('transactions', 'fk_transactions_posted_by', 'FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`) ON DELETE SET NULL');
CALL zq_add_fk_if_missing('transactions', 'fk_transactions_voided_by', 'FOREIGN KEY (`voided_by`) REFERENCES `users` (`id`) ON DELETE SET NULL');
CALL zq_add_fk_if_missing('transactions', 'fk_transactions_reversal', 'FOREIGN KEY (`reversal_txn_id`) REFERENCES `transactions` (`id`) ON DELETE SET NULL');

CREATE TABLE IF NOT EXISTS transaction_locks (
    id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id       INT UNSIGNED NOT NULL,
    fiscal_period_id INT UNSIGNED,
    lock_date        DATE         NOT NULL,
    reason           VARCHAR(255),
    locked_by        INT UNSIGNED,
    locked_at        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id)       REFERENCES companies(id)      ON DELETE CASCADE,
    FOREIGN KEY (fiscal_period_id) REFERENCES fiscal_periods(id) ON DELETE SET NULL,
    FOREIGN KEY (locked_by)        REFERENCES users(id)          ON DELETE SET NULL,
    INDEX idx_transaction_locks_date (company_id, lock_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ================================================================
-- 5) SALES / PURCHASING GAPS
-- ================================================================

CREATE TABLE IF NOT EXISTS projects (
    id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id         INT UNSIGNED NOT NULL,
    customer_id        INT UNSIGNED,
    parent_project_id  INT UNSIGNED,
    project_code       VARCHAR(50),
    name               VARCHAR(200) NOT NULL,
    status             ENUM('not_started','in_progress','on_hold','completed','cancelled') NOT NULL DEFAULT 'not_started',
    start_date         DATE,
    end_date           DATE,
    budget_amount      DECIMAL(15,2),
    is_billable        TINYINT(1) NOT NULL DEFAULT 1,
    created_at         DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_project_code (company_id, project_code),
    FOREIGN KEY (company_id)        REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id)       REFERENCES customers(id) ON DELETE SET NULL,
    FOREIGN KEY (parent_project_id) REFERENCES projects(id)  ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CALL zq_add_column_if_missing('estimates', 'project_id', '`project_id` INT UNSIGNED NULL');
CALL zq_add_column_if_missing('sales_orders', 'project_id', '`project_id` INT UNSIGNED NULL');
CALL zq_add_column_if_missing('invoices', 'project_id', '`project_id` INT UNSIGNED NULL');
CALL zq_add_column_if_missing('expenses', 'project_id', '`project_id` INT UNSIGNED NULL');
CALL zq_add_column_if_missing('bills', 'project_id', '`project_id` INT UNSIGNED NULL');
CALL zq_add_fk_if_missing('invoices', 'fk_invoices_project', 'FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE SET NULL');
CALL zq_add_fk_if_missing('expenses', 'fk_expenses_project', 'FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE SET NULL');
CALL zq_add_fk_if_missing('bills', 'fk_bills_project', 'FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE SET NULL');

CREATE TABLE IF NOT EXISTS sales_receipts (
    id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id         INT UNSIGNED NOT NULL,
    transaction_id     INT UNSIGNED NOT NULL UNIQUE,
    customer_id        INT UNSIGNED,
    receipt_date       DATE         NOT NULL,
    payment_method     ENUM('cash','bank_transfer','cheque','credit_card','debit_card') NOT NULL DEFAULT 'cash',
    bank_account_id    INT UNSIGNED,
    subtotal           DECIMAL(15,2) NOT NULL DEFAULT 0,
    discount_amount    DECIMAL(15,2) NOT NULL DEFAULT 0,
    tax_amount         DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_amount       DECIMAL(15,2) NOT NULL DEFAULT 0,
    status             ENUM('draft','posted','void') NOT NULL DEFAULT 'posted',
    FOREIGN KEY (company_id)      REFERENCES companies(id)     ON DELETE CASCADE,
    FOREIGN KEY (transaction_id)  REFERENCES transactions(id)  ON DELETE CASCADE,
    FOREIGN KEY (customer_id)     REFERENCES customers(id)     ON DELETE SET NULL,
    FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS sales_receipt_lines (
    id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sales_receipt_id  INT UNSIGNED NOT NULL,
    item_id           INT UNSIGNED,
    description       TEXT,
    qty               DECIMAL(12,3) NOT NULL DEFAULT 1,
    unit_price        DECIMAL(15,4) NOT NULL DEFAULT 0,
    discount_percent  DECIMAL(5,2)  NOT NULL DEFAULT 0,
    tax_code          VARCHAR(20),
    tax_amount        DECIMAL(15,2) NOT NULL DEFAULT 0,
    amount            DECIMAL(15,2) NOT NULL DEFAULT 0,
    class_id          INT UNSIGNED,
    sort_order        SMALLINT      NOT NULL DEFAULT 0,
    FOREIGN KEY (sales_receipt_id) REFERENCES sales_receipts(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id)          REFERENCES items(id)          ON DELETE SET NULL,
    FOREIGN KEY (class_id)         REFERENCES classes(id)        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS refund_receipts (
    id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id         INT UNSIGNED NOT NULL,
    transaction_id     INT UNSIGNED NOT NULL UNIQUE,
    customer_id        INT UNSIGNED,
    refund_date        DATE         NOT NULL,
    bank_account_id    INT UNSIGNED,
    total_amount       DECIMAL(15,2) NOT NULL DEFAULT 0,
    reason             VARCHAR(255),
    status             ENUM('draft','posted','void') NOT NULL DEFAULT 'posted',
    FOREIGN KEY (company_id)      REFERENCES companies(id)     ON DELETE CASCADE,
    FOREIGN KEY (transaction_id)  REFERENCES transactions(id)  ON DELETE CASCADE,
    FOREIGN KEY (customer_id)     REFERENCES customers(id)     ON DELETE SET NULL,
    FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS credit_memo_applications (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id      INT UNSIGNED NOT NULL,
    credit_memo_id  INT UNSIGNED NOT NULL,
    invoice_id      INT UNSIGNED NOT NULL,
    applied_amount  DECIMAL(15,2) NOT NULL,
    applied_date    DATE          NOT NULL,
    created_by      INT UNSIGNED,
    created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id)     REFERENCES companies(id)    ON DELETE CASCADE,
    FOREIGN KEY (credit_memo_id) REFERENCES credit_memos(id) ON DELETE CASCADE,
    FOREIGN KEY (invoice_id)     REFERENCES invoices(id)     ON DELETE CASCADE,
    FOREIGN KEY (created_by)     REFERENCES users(id)        ON DELETE SET NULL,
    UNIQUE KEY uq_credit_application (credit_memo_id, invoice_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS vendor_credit_applications (
    id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id        INT UNSIGNED NOT NULL,
    vendor_credit_id  INT UNSIGNED NOT NULL,
    bill_id           INT UNSIGNED NOT NULL,
    applied_amount    DECIMAL(15,2) NOT NULL,
    applied_date      DATE          NOT NULL,
    created_by        INT UNSIGNED,
    created_at        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id)       REFERENCES companies(id)      ON DELETE CASCADE,
    FOREIGN KEY (vendor_credit_id) REFERENCES vendor_credits(id) ON DELETE CASCADE,
    FOREIGN KEY (bill_id)          REFERENCES bills(id)          ON DELETE CASCADE,
    FOREIGN KEY (created_by)       REFERENCES users(id)          ON DELETE SET NULL,
    UNIQUE KEY uq_vendor_credit_application (vendor_credit_id, bill_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS cheques (
    id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id        INT UNSIGNED NOT NULL,
    transaction_id    INT UNSIGNED NOT NULL UNIQUE,
    bank_account_id   INT UNSIGNED NOT NULL,
    payee_type        ENUM('vendor','customer','employee','other') NOT NULL DEFAULT 'vendor',
    payee_id          INT UNSIGNED,
    cheque_number     VARCHAR(50) NOT NULL,
    cheque_date       DATE        NOT NULL,
    amount            DECIMAL(15,2) NOT NULL,
    memo              VARCHAR(255),
    status            ENUM('issued','cleared','void','stopped') NOT NULL DEFAULT 'issued',
    FOREIGN KEY (company_id)      REFERENCES companies(id)     ON DELETE CASCADE,
    FOREIGN KEY (transaction_id)  REFERENCES transactions(id)  ON DELETE CASCADE,
    FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(id),
    UNIQUE KEY uq_cheque_number (company_id, bank_account_id, cheque_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ================================================================
-- 6) INVENTORY COSTING / SERIALS / LOTS
-- ================================================================

CREATE TABLE IF NOT EXISTS inventory_movements (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id      INT UNSIGNED NOT NULL,
    item_id         INT UNSIGNED NOT NULL,
    location_id     INT UNSIGNED,
    transaction_id  INT UNSIGNED,
    source_type     VARCHAR(80)  NOT NULL,
    source_id       BIGINT UNSIGNED NOT NULL,
    movement_date   DATETIME     NOT NULL,
    qty_in          DECIMAL(12,3) NOT NULL DEFAULT 0,
    qty_out         DECIMAL(12,3) NOT NULL DEFAULT 0,
    unit_cost       DECIMAL(15,4) NOT NULL DEFAULT 0,
    total_cost      DECIMAL(15,2) NOT NULL DEFAULT 0,
    costing_method  ENUM('average','fifo','lifo','specific') NOT NULL DEFAULT 'average',
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id)     REFERENCES companies(id)           ON DELETE CASCADE,
    FOREIGN KEY (item_id)        REFERENCES items(id),
    FOREIGN KEY (location_id)    REFERENCES inventory_locations(id) ON DELETE SET NULL,
    FOREIGN KEY (transaction_id) REFERENCES transactions(id)        ON DELETE SET NULL,
    INDEX idx_inventory_movements_item_date (company_id, item_id, movement_date),
    INDEX idx_inventory_movements_source (source_type, source_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS inventory_cost_layers (
    id                 BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id         INT UNSIGNED NOT NULL,
    item_id            INT UNSIGNED NOT NULL,
    location_id        INT UNSIGNED,
    source_movement_id BIGINT UNSIGNED,
    received_date      DATE         NOT NULL,
    qty_original       DECIMAL(12,3) NOT NULL,
    qty_remaining      DECIMAL(12,3) NOT NULL,
    unit_cost          DECIMAL(15,4) NOT NULL,
    FOREIGN KEY (company_id)         REFERENCES companies(id)           ON DELETE CASCADE,
    FOREIGN KEY (item_id)            REFERENCES items(id),
    FOREIGN KEY (location_id)        REFERENCES inventory_locations(id) ON DELETE SET NULL,
    FOREIGN KEY (source_movement_id) REFERENCES inventory_movements(id) ON DELETE SET NULL,
    INDEX idx_cost_layers_item (company_id, item_id, qty_remaining)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS item_lots (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id      INT UNSIGNED NOT NULL,
    item_id         INT UNSIGNED NOT NULL,
    lot_number      VARCHAR(100) NOT NULL,
    manufactured_at DATE,
    expires_at      DATE,
    notes           VARCHAR(255),
    UNIQUE KEY uq_item_lot (company_id, item_id, lot_number),
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id)    REFERENCES items(id)    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS item_serial_numbers (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id           INT UNSIGNED NOT NULL,
    item_id              INT UNSIGNED NOT NULL,
    serial_number        VARCHAR(120) NOT NULL,
    current_location_id  INT UNSIGNED,
    status               ENUM('available','sold','reserved','damaged','returned') NOT NULL DEFAULT 'available',
    source_movement_id   BIGINT UNSIGNED,
    UNIQUE KEY uq_item_serial (company_id, item_id, serial_number),
    FOREIGN KEY (company_id)          REFERENCES companies(id)            ON DELETE CASCADE,
    FOREIGN KEY (item_id)             REFERENCES items(id)                ON DELETE CASCADE,
    FOREIGN KEY (current_location_id) REFERENCES inventory_locations(id)  ON DELETE SET NULL,
    FOREIGN KEY (source_movement_id)  REFERENCES inventory_movements(id)  ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CALL zq_add_column_if_missing('items', 'track_lots', '`track_lots` TINYINT(1) NOT NULL DEFAULT 0');
CALL zq_add_column_if_missing('items', 'track_serials', '`track_serials` TINYINT(1) NOT NULL DEFAULT 0');
CALL zq_add_column_if_missing('items', 'costing_method', '`costing_method` ENUM(''average'',''fifo'',''lifo'',''specific'') NOT NULL DEFAULT ''average''');

-- ================================================================
-- 7) TAX MODEL
-- ================================================================

CREATE TABLE IF NOT EXISTS tax_agencies (
    id                    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id             INT UNSIGNED NOT NULL,
    name                   VARCHAR(150) NOT NULL,
    tax_number             VARCHAR(50),
    payable_account_id     INT UNSIGNED,
    receivable_account_id  INT UNSIGNED,
    is_active              TINYINT(1) NOT NULL DEFAULT 1,
    FOREIGN KEY (company_id)             REFERENCES companies(id)         ON DELETE CASCADE,
    FOREIGN KEY (payable_account_id)     REFERENCES chart_of_accounts(id) ON DELETE SET NULL,
    FOREIGN KEY (receivable_account_id)  REFERENCES chart_of_accounts(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS tax_rates (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id     INT UNSIGNED NOT NULL,
    agency_id      INT UNSIGNED,
    name           VARCHAR(120) NOT NULL,
    rate           DECIMAL(8,4) NOT NULL DEFAULT 0,
    effective_from DATE,
    effective_to   DATE,
    is_active      TINYINT(1)   NOT NULL DEFAULT 1,
    FOREIGN KEY (company_id) REFERENCES companies(id)    ON DELETE CASCADE,
    FOREIGN KEY (agency_id)  REFERENCES tax_agencies(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS tax_code_rates (
    tax_code_id    INT UNSIGNED NOT NULL,
    tax_rate_id    INT UNSIGNED NOT NULL,
    sort_order     SMALLINT     NOT NULL DEFAULT 0,
    is_compound    TINYINT(1)   NOT NULL DEFAULT 0,
    PRIMARY KEY (tax_code_id, tax_rate_id),
    FOREIGN KEY (tax_code_id) REFERENCES tax_codes(id) ON DELETE CASCADE,
    FOREIGN KEY (tax_rate_id) REFERENCES tax_rates(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ================================================================
-- 8) BANKING / RECONCILIATION
-- ================================================================

CALL zq_add_column_if_missing('reconciliation_items', 'transaction_id', '`transaction_id` INT UNSIGNED NULL AFTER `reconciliation_id`');
CALL zq_add_column_if_missing('reconciliation_items', 'cleared_amount', '`cleared_amount` DECIMAL(15,2) NULL AFTER `imported_txn_id`');
CALL zq_add_fk_if_missing('reconciliation_items', 'fk_reconciliation_items_txn', 'FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`id`) ON DELETE CASCADE');

CREATE TABLE IF NOT EXISTS bank_feeds (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id          INT UNSIGNED NOT NULL,
    bank_account_id     INT UNSIGNED NOT NULL,
    provider            VARCHAR(80)  NOT NULL,
    external_account_id VARCHAR(160),
    last_sync_at        DATETIME,
    status              ENUM('active','paused','error') NOT NULL DEFAULT 'active',
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id)      REFERENCES companies(id)     ON DELETE CASCADE,
    FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ================================================================
-- 9) APPROVALS / WORKFLOW
-- ================================================================

CREATE TABLE IF NOT EXISTS approval_policies (
    id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id       INT UNSIGNED NOT NULL,
    entity_type      VARCHAR(80)  NOT NULL,
    name             VARCHAR(150) NOT NULL,
    min_amount       DECIMAL(15,2),
    max_amount       DECIMAL(15,2),
    required_role_id INT UNSIGNED,
    is_active        TINYINT(1) NOT NULL DEFAULT 1,
    FOREIGN KEY (company_id)       REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (required_role_id) REFERENCES roles(id)     ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS approval_requests (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id      INT UNSIGNED NOT NULL,
    policy_id       INT UNSIGNED,
    entity_type     VARCHAR(80) NOT NULL,
    entity_id       BIGINT UNSIGNED NOT NULL,
    requested_by    INT UNSIGNED,
    status          ENUM('pending','approved','rejected','cancelled') NOT NULL DEFAULT 'pending',
    requested_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at    DATETIME,
    FOREIGN KEY (company_id)   REFERENCES companies(id)          ON DELETE CASCADE,
    FOREIGN KEY (policy_id)    REFERENCES approval_policies(id)  ON DELETE SET NULL,
    FOREIGN KEY (requested_by) REFERENCES users(id)              ON DELETE SET NULL,
    INDEX idx_approval_entity (company_id, entity_type, entity_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS approval_actions (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    approval_request_id BIGINT UNSIGNED NOT NULL,
    acted_by            INT UNSIGNED,
    action              ENUM('approved','rejected','commented') NOT NULL,
    comments            VARCHAR(500),
    acted_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (approval_request_id) REFERENCES approval_requests(id) ON DELETE CASCADE,
    FOREIGN KEY (acted_by)            REFERENCES users(id)             ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ================================================================
-- 10) INTEGRATION / RELIABILITY
-- ================================================================

CREATE TABLE IF NOT EXISTS outbox_messages (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id      INT UNSIGNED,
    aggregate_type  VARCHAR(100) NOT NULL,
    aggregate_id    BIGINT UNSIGNED NOT NULL,
    event_type      VARCHAR(120) NOT NULL,
    payload         JSON         NOT NULL,
    status          ENUM('pending','processing','published','failed') NOT NULL DEFAULT 'pending',
    attempts        INT          NOT NULL DEFAULT 0,
    next_attempt_at DATETIME,
    published_at    DATETIME,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    INDEX idx_outbox_status (status, next_attempt_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS import_batches (
    id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id   INT UNSIGNED NOT NULL,
    import_type  VARCHAR(80)  NOT NULL,
    file_name    VARCHAR(255),
    status       ENUM('pending','validated','imported','failed') NOT NULL DEFAULT 'pending',
    total_rows   INT NOT NULL DEFAULT 0,
    success_rows INT NOT NULL DEFAULT 0,
    failed_rows  INT NOT NULL DEFAULT 0,
    created_by   INT UNSIGNED,
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id)     ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS import_errors (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    import_batch_id BIGINT UNSIGNED NOT NULL,
    row_number      INT,
    field_name      VARCHAR(100),
    error_message   VARCHAR(500) NOT NULL,
    raw_row         JSON,
    FOREIGN KEY (import_batch_id) REFERENCES import_batches(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ================================================================
-- 11) BASE PERMISSION SEED
-- ================================================================

INSERT IGNORE INTO permissions (code, module, description) VALUES
('company.manage', 'setup', 'Manage company settings'),
('users.manage', 'security', 'Manage users'),
('roles.manage', 'security', 'Manage roles and permissions'),
('accounts.view', 'accounting', 'View chart of accounts'),
('accounts.manage', 'accounting', 'Manage chart of accounts'),
('transactions.post', 'accounting', 'Post accounting transactions'),
('transactions.void', 'accounting', 'Void posted transactions'),
('periods.close', 'accounting', 'Close fiscal periods'),
('customers.manage', 'sales', 'Manage customers'),
('invoices.manage', 'sales', 'Manage invoices'),
('payments.manage', 'sales', 'Manage customer payments'),
('vendors.manage', 'purchases', 'Manage vendors'),
('bills.manage', 'purchases', 'Manage bills'),
('bill_payments.manage', 'purchases', 'Manage bill payments'),
('items.manage', 'inventory', 'Manage products and services'),
('inventory.adjust', 'inventory', 'Create inventory adjustments'),
('banking.manage', 'banking', 'Manage bank accounts and reconciliation'),
('payroll.manage', 'payroll', 'Manage payroll'),
('reports.view', 'reports', 'View reports'),
('attachments.manage', 'documents', 'Manage attachments');

SET FOREIGN_KEY_CHECKS = 1;

DROP PROCEDURE IF EXISTS zq_add_fk_if_missing;
DROP PROCEDURE IF EXISTS zq_add_index_if_missing;
DROP PROCEDURE IF EXISTS zq_add_column_if_missing;

-- ================================================================
-- END - ZOKAA QuickBooks Clone Schema v2 Hardening
-- ================================================================
