-- Migration 002: Add version column to event table for data migration tracking
ALTER TABLE labelmaker_data.event
ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_labelmaker_data_event_type_version
ON labelmaker_data.event(type, version);
