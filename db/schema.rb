# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify the database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends
# to be faster and is potentially less error prone than running all of the
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_01_000003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # NanoID generation function — PostgreSQL-native, called via DEFAULT on each table.
  # Alphabet: 0-9a-z (36 chars), length: 12 → 36^12 ≈ 4.74 × 10^18 keyspace.
  execute <<~SQL
    CREATE OR REPLACE FUNCTION nanoid(size int DEFAULT 12)
    RETURNS text AS $$
    DECLARE
      alphabet text := '0123456789abcdefghijklmnopqrstuvwxyz';
      output text := '';
      i int;
    BEGIN
      FOR i IN 1..size LOOP
        output := output || substr(alphabet, floor(random() * 36)::int + 1, 1);
      END LOOP;
      RETURN output;
    END;
    $$ LANGUAGE plpgsql VOLATILE
  SQL

  create_table "snapshots", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "stats"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_snapshots_on_created_at"
  end

  create_table "song_plays", id: :string, force: :cascade do |t|
    t.text "artist"
    t.text "category", null: false
    t.datetime "created_at", null: false
    t.integer "duration_seconds", null: false
    t.datetime "ended_at", null: false
    t.integer "snapshot_count", null: false
    t.text "song"
    t.datetime "started_at", null: false
    t.text "station", null: false
    t.text "title", null: false
    t.datetime "updated_at", null: false
    t.index ["artist", "station"], name: "index_song_plays_on_artist_and_station"
    t.index ["category", "station"], name: "index_song_plays_on_category_and_station"
    t.index ["station", "started_at"], name: "index_song_plays_on_station_and_started_at"
    t.index ["title", "station"], name: "index_song_plays_on_title_and_station"
  end

  create_table "stats", id: :string, force: :cascade do |t|
    t.integer "average"
    t.datetime "created_at", null: false
    t.datetime "from"
    t.integer "maximum"
    t.integer "median"
    t.integer "snapshot_count"
    t.text "station"
    t.datetime "to"
    t.integer "total_time"
    t.datetime "updated_at", null: false
    t.index ["station", "from", "to"], name: "index_stats_on_station_and_from_and_to", unique: true
    t.index ["station"], name: "index_stats_on_station"
  end

  create_table "stream_outages", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "detected_at", null: false
    t.integer "estimated_downtime_seconds"
    t.text "new_stream_start"
    t.text "previous_stream_start"
    t.text "station", null: false
    t.datetime "updated_at", null: false
    t.index ["station", "detected_at"], name: "index_stream_outages_on_station_and_detected_at"
  end

  # Set nanoid() as the default for all primary keys (must run after table creation)
  ["snapshots", "song_plays", "stats", "stream_outages"].each do |table|
    execute "ALTER TABLE #{table} ALTER COLUMN id SET DEFAULT nanoid()"
  end
end
