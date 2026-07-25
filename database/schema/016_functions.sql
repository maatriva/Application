-- ============================================
-- MAATRIVA DATABASE FUNCTIONS
-- ============================================

-- Function to automatically update the updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to log audit actions automatically via triggers
CREATE OR REPLACE FUNCTION log_audit_action()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
    v_action VARCHAR(255);
    v_target_table VARCHAR(100);
    v_target_id UUID := NULL;
    v_details TEXT;
BEGIN
    v_target_table := TG_TABLE_NAME;
    
    IF (TG_OP = 'INSERT') THEN
        v_action := 'CREATE';
        BEGIN
            v_target_id := NEW.id;
        EXCEPTION WHEN OTHERS THEN
            v_target_id := NULL;
        END;
        v_details := 'Created new record in ' || TG_TABLE_NAME;
    ELSIF (TG_OP = 'UPDATE') THEN
        v_action := 'UPDATE';
        BEGIN
            v_target_id := NEW.id;
        EXCEPTION WHEN OTHERS THEN
            v_target_id := NULL;
        END;
        v_details := 'Updated record in ' || TG_TABLE_NAME;
    ELSIF (TG_OP = 'DELETE') THEN
        v_action := 'DELETE';
        BEGIN
            v_target_id := OLD.id;
        EXCEPTION WHEN OTHERS THEN
            v_target_id := NULL;
        END;
        v_details := 'Deleted record in ' || TG_TABLE_NAME;
    END IF;
    
    -- Try to capture current user ID if set in connection context
    BEGIN
        v_user_id := NULLIF(current_setting('app.current_user_id', true), '')::UUID;
    EXCEPTION WHEN OTHERS THEN
        v_user_id := NULL;
    END;

    INSERT INTO audit_logs (user_id, action, target_table, target_id, details)
    VALUES (v_user_id, v_action, v_target_table, v_target_id, v_details);
    
    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;
