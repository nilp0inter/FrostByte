-- LabelMaker API Layer
-- Read views and RPC write functions exposed via PostgREST
-- This file is idempotent: DROP + CREATE on each deploy

DROP SCHEMA IF EXISTS labelmaker_api CASCADE;
CREATE SCHEMA labelmaker_api;

-- =============================================================================
-- Read Views
-- =============================================================================

CREATE VIEW labelmaker_api.event AS
SELECT * FROM labelmaker_data.event;
