class SongPlayExtractor
  STATION = "Surf Radio"
  GAP_THRESHOLD = 15.seconds

  attr_reader :from, :to

  def initialize(from:, to:)
    @from = from
    @to = to
  end

  def extract
    snapshots = fetch_snapshots
    return [] if snapshots.empty?

    plays = []
    current_title = nil
    current_start = nil
    current_count = 0
    last_time = nil

    snapshots.each do |row|
      title = row["title"]
      time = row["created_at"]

      if title != current_title || (last_time && (time - last_time) > GAP_THRESHOLD)
        if current_title
          plays << build_play(current_title, current_start, last_time, current_count)
        end
        current_title = title
        current_start = time
        current_count = 0
      end

      current_count += 1
      last_time = time
    end

    # Final segment
    if current_title
      plays << build_play(current_title, current_start, last_time, current_count)
    end

    persist(plays)
  end

  private

  def fetch_snapshots
    sql = Snapshot.sanitize_sql_array([<<~SQL, from:, to:, station: STATION])
      SELECT
        source->>'title' AS title,
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
        AND source->>'server_name' = :station
      ORDER BY snapshots.created_at
    SQL

    Snapshot.connection.select_all(sql).to_a.map do |row|
      row["created_at"] = Time.parse(row["created_at"]) if row["created_at"].is_a?(String)
      row
    end
  end

  def build_play(title, started_at, ended_at, snapshot_count)
    parsed = SongPlay.parse_artist_and_song(title)
    category = SongPlay.categorize(title)

    {
      title: title,
      artist: parsed[:artist],
      song: parsed[:song],
      category: category,
      station: STATION,
      started_at: started_at,
      ended_at: ended_at,
      duration_seconds: (ended_at - started_at).to_i,
      snapshot_count: snapshot_count
    }
  end

  def persist(plays)
    plays.filter_map do |attrs|
      next if SongPlay.exists?(station: attrs[:station], started_at: attrs[:started_at], title: attrs[:title])
      SongPlay.create!(attrs)
    end
  end
end
