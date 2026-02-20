-- FrostByte Database Schema: Data Layer (Event Sourcing)
-- Squashed migration: creates the final frostbyte_data schema directly.

-- Enable extensions (shared with other apps, idempotent)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS citext;

-- Create data schema
CREATE SCHEMA IF NOT EXISTS frostbyte_data;

-- =============================================================================
-- Event Store
-- =============================================================================

CREATE TABLE IF NOT EXISTS frostbyte_data.event (
    id BIGSERIAL PRIMARY KEY,
    type TEXT NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_frostbyte_event_type ON frostbyte_data.event(type);
CREATE INDEX IF NOT EXISTS idx_frostbyte_event_created_at ON frostbyte_data.event(created_at);
CREATE INDEX IF NOT EXISTS idx_frostbyte_event_type_version ON frostbyte_data.event(type, version);
