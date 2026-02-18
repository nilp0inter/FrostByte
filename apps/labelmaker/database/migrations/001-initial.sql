-- LabelMaker Database Schema: Data Layer (Event Sourcing)
-- All persistent tables live in the 'labelmaker_data' schema

-- Enable extensions (shared with other apps, idempotent)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS citext;

-- Create data schema
CREATE SCHEMA IF NOT EXISTS labelmaker_data;

-- =============================================================================
-- Event Store
-- =============================================================================

CREATE TABLE labelmaker_data.event (
    id BIGSERIAL PRIMARY KEY,
    type TEXT NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_labelmaker_event_type ON labelmaker_data.event(type);
CREATE INDEX idx_labelmaker_event_created_at ON labelmaker_data.event(created_at);
