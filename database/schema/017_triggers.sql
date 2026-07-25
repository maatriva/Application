-- ============================================
-- MAATRIVA DATABASE TRIGGERS
-- ============================================

-- Triggers for auto-updating updated_at columns
CREATE OR REPLACE TRIGGER tr_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER tr_babies_updated_at
BEFORE UPDATE ON babies
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER tr_subscriptions_updated_at
BEFORE UPDATE ON subscriptions
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- Triggers for auditing changes to sensitive tables
CREATE OR REPLACE TRIGGER tr_audit_users
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION log_audit_action();

CREATE OR REPLACE TRIGGER tr_audit_devices
AFTER INSERT OR UPDATE OR DELETE ON devices
FOR EACH ROW EXECUTE FUNCTION log_audit_action();

CREATE OR REPLACE TRIGGER tr_audit_device_assignments
AFTER INSERT OR UPDATE OR DELETE ON device_assignments
FOR EACH ROW EXECUTE FUNCTION log_audit_action();

CREATE OR REPLACE TRIGGER tr_audit_caregivers
AFTER INSERT OR UPDATE OR DELETE ON caregivers
FOR EACH ROW EXECUTE FUNCTION log_audit_action();

CREATE OR REPLACE TRIGGER tr_audit_subscriptions
AFTER INSERT OR UPDATE OR DELETE ON subscriptions
FOR EACH ROW EXECUTE FUNCTION log_audit_action();
