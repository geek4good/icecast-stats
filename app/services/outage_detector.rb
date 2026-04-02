class OutageDetector
  SNAPSHOT_GAP_THRESHOLD = 20.seconds

  attr_reader :from, :to

  def initialize(from:, to:)
    @from = from
    @to = to
  end

  def detect
    snapshots = fetch_snapshots
    return [] if snapshots.empty?

    outages = detect_stream_restarts(snapshots) + detect_snapshot_gaps
    persist(outages)
  end

  private

  def detect_stream_restarts(snapshots)
    outages = []
    last_stream_start = {}

    snapshots.each do |row|
      station = row["station"]
      stream_start = row["stream_start"]
      detected_at = row["created_at"]

      if last_stream_start[station] && stream_start != last_stream_start[station]
        estimated_downtime = estimate_downtime(last_stream_start[station], stream_start)
        outages << {
          station: station,
          detected_at: detected_at,
          previous_stream_start: last_stream_start[station],
          new_stream_start: stream_start,
          estimated_downtime_seconds: estimated_downtime
        }
      end

      last_stream_start[station] = stream_start
    end

    outages
  end

  def detect_snapshot_gaps
    timestamps = fetch_snapshot_timestamps
    return [] if timestamps.size < 2

    outages = []

    timestamps.each_cons(2) do |prev_time, next_time|
      gap = next_time - prev_time
      next unless gap > SNAPSHOT_GAP_THRESHOLD

      stations = stations_at(prev_time)
      stations.each do |station|
        outages << {
          station: station,
          detected_at: next_time,
          previous_stream_start: nil,
          new_stream_start: nil,
          estimated_downtime_seconds: gap.to_i
        }
      end
    end

    outages
  end

  def fetch_snapshots
    sql = Snapshot.sanitize_sql_array([<<~SQL, from:, to:])
      SELECT
        source->>'server_name' AS station,
        source->>'stream_start_iso8601' AS stream_start,
        snapshots.created_at
      FROM
        snapshots,
        jsonb_array_elements(
          CASE jsonb_typeof(stats->'icestats'->'source')
            WHEN 'array' THEN stats->'icestats'->'source'
            ELSE jsonb_build_array(stats->'icestats'->'source')
          END
        ) AS source
      WHERE
        snapshots.created_at >= :from AND snapshots.created_at < :to
        AND source->>'stream_start_iso8601' IS NOT NULL
      ORDER BY snapshots.created_at
    SQL

    Snapshot.connection.select_all(sql).to_a.map do |row|
      row["created_at"] = Time.parse(row["created_at"]) if row["created_at"].is_a?(String)
      row
    end
  end

  def fetch_snapshot_timestamps
    sql = Snapshot.sanitize_sql_array([<<~SQL, from:, to:])
      SELECT DISTINCT created_at
      FROM snapshots
      WHERE created_at >= :from AND created_at < :to
      ORDER BY created_at
    SQL

    Snapshot.connection.select_values(sql).map do |ts|
      ts.is_a?(String) ? Time.parse(ts) : ts
    end
  end

  def stations_at(timestamp)
    sql = Snapshot.sanitize_sql_array([<<~SQL, timestamp:])
      SELECT DISTINCT source->>'server_name' AS station
      FROM
        snapshots,
        jsonb_array_elements(
          CASE jsonb_typeof(stats->'icestats'->'source')
            WHEN 'array' THEN stats->'icestats'->'source'
            ELSE jsonb_build_array(stats->'icestats'->'source')
          END
        ) AS source
      WHERE snapshots.created_at = :timestamp
        AND source->>'server_name' IS NOT NULL
    SQL

    Snapshot.connection.select_values(sql)
  end

  def estimate_downtime(previous_start, new_start)
    begin
      prev = Time.parse(previous_start)
      current = Time.parse(new_start)
      (current - prev).abs.to_i
    rescue
      nil
    end
  end

  def persist(outages)
    outages.filter_map do |attrs|
      next if StreamOutage.exists?(station: attrs[:station], detected_at: attrs[:detected_at])
      StreamOutage.create!(attrs)
    end
  end
end
