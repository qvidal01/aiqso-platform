-- AIQSO Platform Master Database Schema
-- PostgreSQL database: aiqso_master (LXC 150 @ 10.10.10.150)

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Tenants table: Core customer information
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subdomain VARCHAR(63) UNIQUE NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255) NOT NULL,
    stripe_customer_id VARCHAR(255),
    status VARCHAR(50) DEFAULT 'trial',
    created_at TIMESTAMP DEFAULT NOW(),
    trial_ends_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT valid_subdomain CHECK (subdomain ~ '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'),
    CONSTRAINT valid_email CHECK (contact_email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT valid_status CHECK (status IN ('trial', 'active', 'suspended', 'cancelled'))
);

-- Services table: Available platform services
CREATE TABLE services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_key VARCHAR(50) UNIQUE NOT NULL,
    service_name VARCHAR(100) NOT NULL,
    description TEXT,
    docker_image VARCHAR(255),
    base_price DECIMAL(10,2),
    requires_database BOOLEAN DEFAULT true,
    config_template JSONB,
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT valid_service_key CHECK (service_key ~ '^[a-z0-9-]+$')
);

-- Subscriptions table: Customer subscription details
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    stripe_subscription_id VARCHAR(255),
    status VARCHAR(50),
    current_period_start TIMESTAMP,
    current_period_end TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT valid_subscription_status CHECK (status IN ('active', 'past_due', 'cancelled', 'incomplete'))
);

-- Tenant Services table: Track deployed services per tenant
CREATE TABLE tenant_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    service_id UUID REFERENCES services(id) ON DELETE CASCADE,
    container_id INTEGER,
    container_name VARCHAR(255),
    database_name VARCHAR(255),
    status VARCHAR(50) DEFAULT 'provisioning',
    config JSONB,
    ip_address INET,
    provisioned_at TIMESTAMP,
    last_health_check TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT valid_tenant_service_status CHECK (status IN ('provisioning', 'active', 'stopped', 'failed', 'deprovisioning')),
    UNIQUE(tenant_id, service_id)
);

-- Usage Metrics table: Track service usage for billing
CREATE TABLE usage_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    service_id UUID REFERENCES services(id) ON DELETE CASCADE,
    metric_type VARCHAR(50),
    metric_value DECIMAL(15,2),
    recorded_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT valid_metric_type CHECK (metric_type IN ('storage_gb', 'api_calls', 'ai_requests', 'bandwidth_gb', 'users'))
);

-- Backups table: Track backup status and locations
CREATE TABLE backups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    service_id UUID REFERENCES services(id),
    backup_type VARCHAR(50),
    file_path TEXT,
    file_size_bytes BIGINT,
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,

    CONSTRAINT valid_backup_type CHECK (backup_type IN ('full', 'incremental', 'database', 'snapshot')),
    CONSTRAINT valid_backup_status CHECK (status IN ('pending', 'in_progress', 'completed', 'failed', 'expired'))
);

-- Audit Log table: Track all platform actions
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id),
    user_email VARCHAR(255),
    action VARCHAR(100),
    details JSONB,
    ip_address INET,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_tenants_subdomain ON tenants(subdomain);
CREATE INDEX idx_tenants_status ON tenants(status);
CREATE INDEX idx_tenant_services_tenant ON tenant_services(tenant_id);
CREATE INDEX idx_tenant_services_status ON tenant_services(status);
CREATE INDEX idx_usage_metrics_tenant ON usage_metrics(tenant_id);
CREATE INDEX idx_usage_metrics_recorded ON usage_metrics(recorded_at);
CREATE INDEX idx_backups_tenant ON backups(tenant_id);
CREATE INDEX idx_backups_created ON backups(created_at);
CREATE INDEX idx_audit_log_tenant ON audit_log(tenant_id);
CREATE INDEX idx_audit_log_created ON audit_log(created_at);

-- Seed initial services
INSERT INTO services (service_key, service_name, description, docker_image, base_price, requires_database, config_template) VALUES
('crm', 'CRM Suite', 'Customer relationship management powered by EspoCRM', 'espocrm/espocrm:latest', 49.00, true, '{"ram": "2048", "cpu": 2, "storage": "10GB"}'::jsonb),
('docs', 'Document Management', 'Paperless-NGX document management and OCR', 'paperlessngx/paperless-ngx:latest', 29.00, true, '{"ram": "2048", "cpu": 2, "storage": "20GB", "clone_from": 102}'::jsonb),
('social', 'Social Media Manager', 'Multi-platform social media scheduling with AI', 'custom/social-manager:latest', 39.00, true, '{"ram": "1024", "cpu": 1, "storage": "5GB"}'::jsonb),
('content', 'Content Creation Suite', 'AI-powered blog and content generation', 'custom/content-suite:latest', 59.00, true, '{"ram": "2048", "cpu": 2, "storage": "10GB"}'::jsonb),
('email', 'Email Marketing', 'Listmonk email campaign management', 'listmonk/listmonk:latest', 29.00, true, '{"ram": "1024", "cpu": 1, "storage": "5GB", "clone_from": 104}'::jsonb),
('calendar', 'Calendar & Scheduling', 'CalCom appointment scheduling', 'calcom/cal.com:latest', 19.00, true, '{"ram": "1024", "cpu": 1, "storage": "5GB", "clone_from": 136}'::jsonb);

-- Create admin user function
CREATE OR REPLACE FUNCTION create_audit_entry()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (tenant_id, action, details)
        VALUES (NEW.tenant_id, TG_TABLE_NAME || '_created', row_to_json(NEW));
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (tenant_id, action, details)
        VALUES (NEW.tenant_id, TG_TABLE_NAME || '_updated', jsonb_build_object('old', row_to_json(OLD), 'new', row_to_json(NEW)));
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (tenant_id, action, details)
        VALUES (OLD.tenant_id, TG_TABLE_NAME || '_deleted', row_to_json(OLD));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for audit logging
CREATE TRIGGER tenant_services_audit
AFTER INSERT OR UPDATE OR DELETE ON tenant_services
FOR EACH ROW EXECUTE FUNCTION create_audit_entry();

CREATE TRIGGER subscriptions_audit
AFTER INSERT OR UPDATE OR DELETE ON subscriptions
FOR EACH ROW EXECUTE FUNCTION create_audit_entry();

-- Grant permissions (run after creating application user)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO aiqso_app;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO aiqso_app;