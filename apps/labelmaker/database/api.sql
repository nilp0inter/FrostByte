-- LabelMaker API Layer
-- Read views and RPC write functions exposed via PostgREST
-- This file is idempotent: DROP + CREATE on each deploy

DROP SCHEMA IF EXISTS labelmaker_api CASCADE;
CREATE SCHEMA labelmaker_api;

-- =============================================================================
-- Read Views
-- =============================================================================

-- Event view (supports INSERT for writes via PostgREST auto-updatable view)
CREATE VIEW labelmaker_api.event AS
SELECT * FROM labelmaker_data.event;

-- Template list (for list page — summary only, excludes deleted)
CREATE VIEW labelmaker_api.template_list AS
SELECT id, name, label_type_id, created_at
FROM labelmaker_logic.template
WHERE deleted = FALSE
ORDER BY created_at DESC;

-- Template detail (for editor — full state, single row)
CREATE VIEW labelmaker_api.template_detail AS
SELECT id, name, label_type_id, label_width, label_height, corner_radius,
       rotate, padding, content, next_id, sample_values
FROM labelmaker_logic.template
WHERE deleted = FALSE;

-- =============================================================================
-- RPC Functions
-- =============================================================================

-- Create template (server generates UUID, returns it)
CREATE FUNCTION labelmaker_api.create_template(p_name TEXT)
RETURNS TABLE(template_id UUID) LANGUAGE plpgsql AS $$
DECLARE
    v_id UUID := gen_random_uuid();
BEGIN
    INSERT INTO labelmaker_data.event (type, payload)
    VALUES ('template_created', jsonb_build_object('template_id', v_id, 'name', p_name));
    RETURN QUERY SELECT v_id;
END;
$$;
