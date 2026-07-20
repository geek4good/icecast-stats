#!/usr/bin/env bash
#
# pull-prod-data.sh — pull production aggregated data into local dev DB.
#
# Dumps stats, song_plays, and stream_outages from the production
# icecast_stats database on severance and loads them into the local
# icecast_stats_development database.
#
# Does NOT pull raw snapshots — the views render from aggregated tables.
# Total: ~125K rows, loads in seconds.
#
# Usage: ./scripts/pull-prod-data.sh
#
set -euo pipefail

REMOTE="ubuntu@severance"
DUMP_FILE="/tmp/icecast-stats-dev-data.sql"

echo ">>> Pulling production data for local development..."
echo

# Resolve the production DB container
echo ">>> Finding production DB container..."
PROD_DB=$(ssh "$REMOTE" 'docker ps --filter "name=severance-db" --format "{{.Names}}" | head -1')

if [ -z "$PROD_DB" ]; then
    echo "!!! Could not find severance-db container. Aborting."
    exit 1
fi

echo "  Container: $PROD_DB"
echo

# Dump aggregated tables from production
echo ">>> Dumping aggregated tables from production..."
TABLES="stats song_plays stream_outages"
TABLE_ARGS=""
for t in $TABLES; do TABLE_ARGS="$TABLE_ARGS -t $t"; done

ssh "$REMOTE" "docker exec $PROD_DB \
    pg_dump -U postgres -d icecast_stats \
    --data-only \
    --column-inserts \
    $TABLE_ARGS" > "$DUMP_FILE"

ROW_COUNT=$(grep -c "^INSERT INTO" "$DUMP_FILE")
SIZE=$(du -h "$DUMP_FILE" | cut -f1)
echo "  Exported $ROW_COUNT INSERT statements ($SIZE)"
echo

# Load into local dev DB
echo ">>> Loading into icecast_stats_development..."

# Truncate first to avoid conflicts with any existing dev data
bin/rails dbconsole --include-password development <<SQL
TRUNCATE stats, song_plays, stream_outages RESTART IDENTITY CASCADE;
SQL

psql -d icecast_stats_development < "$DUMP_FILE"

echo

# Verify
echo ">>> Local dev DB now contains:"
psql -d icecast_stats_development -c "
    SELECT 'stats' AS table, COUNT(*) FROM stats
    UNION ALL SELECT 'song_plays', COUNT(*) FROM song_plays
    UNION ALL SELECT 'stream_outages', COUNT(*) FROM stream_outages;
"

echo
echo ">>> Done. Start the dev server with: bin/dev"

# Cleanup
rm "$DUMP_FILE" 2>/dev/null || true
echo ">>> Cleaned up temp files."
