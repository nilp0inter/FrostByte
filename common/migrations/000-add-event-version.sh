#!/bin/sh
# 000-add-event-version.sh — Add version column to event tables
#
# Adds version INTEGER NOT NULL DEFAULT 1 to both frostbyte_data.event
# and labelmaker_data.event, plus a composite index on (type, version)
# for efficient migration queries.
#
# Idempotent: uses IF NOT EXISTS for both column and index.

set -eu

echo "=== Add Event Version Column ==="

for schema in frostbyte_data labelmaker_data; do
  echo "Processing ${schema}.event..."

  psql -q -c "
    ALTER TABLE ${schema}.event
    ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1;
  "
  echo "  Column 'version' ensured."

  psql -q -c "
    CREATE INDEX IF NOT EXISTS idx_${schema}_event_type_version
    ON ${schema}.event(type, version);
  "
  echo "  Index on (type, version) ensured."
done

echo "=== Event Version Column Complete ==="
