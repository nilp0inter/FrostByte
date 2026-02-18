-- LabelMaker Logic Layer
-- Projection tables, event handlers, business logic, and replay functions
-- This file is idempotent: DROP + CREATE on each deploy

DROP SCHEMA IF EXISTS labelmaker_logic CASCADE;
CREATE SCHEMA labelmaker_logic;

-- =============================================================================
-- Event Dispatcher
-- =============================================================================

CREATE FUNCTION labelmaker_logic.apply_event(p_type TEXT, p_payload JSONB, p_created_at TIMESTAMPTZ)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    -- No event types handled yet; warn on any unknown type
    RAISE WARNING 'Unknown event type: %', p_type;
END;
$$;

-- =============================================================================
-- Trigger: auto-apply events on INSERT
-- =============================================================================

CREATE FUNCTION labelmaker_logic.handle_event()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM labelmaker_logic.apply_event(NEW.type, NEW.payload, NEW.created_at);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER event_handler
    AFTER INSERT ON labelmaker_data.event
    FOR EACH ROW EXECUTE FUNCTION labelmaker_logic.handle_event();

-- =============================================================================
-- Replay Function
-- =============================================================================

CREATE FUNCTION labelmaker_logic.replay_all_events()
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    -- No projection tables to truncate yet

    -- Replay each event in order (calls apply_event directly, no trigger)
    PERFORM labelmaker_logic.apply_event(e.type, e.payload, e.created_at)
    FROM labelmaker_data.event e ORDER BY e.id;
END;
$$;
