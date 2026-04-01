class OutageDetector
  attr_reader :from, :to

  def initialize(from:, to:)
    @from = from
    @to = to
  end

  def detect
    snapshots = fetch_snapshots
    return [] if snapshots.empty?

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

    persist(outages)
  end

  private

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

  def estimate_downtime(previous_start, new_start)
    begin
      prev = Time.parse(previous_start)
      current = Time.parse(new_start)
      # The difference between stream starts is a rough estimate
      # of how long the stream was down + back up
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
