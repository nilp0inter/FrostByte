-- Migration 004: Add version column to event table for data migration tracking
ALTER TABLE frostbyte_data.event
ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_frostbyte_data_event_type_version
ON frostbyte_data.event(type, version);
