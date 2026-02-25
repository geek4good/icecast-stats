class ListenerStatsCalculator
  attr_reader :from, :to

  def initialize(from:, to:)
    @from = from
    @to = to
  end

  def persist_stats
    return if ListenerStat.exists?(from:, to:)

    calculate_stats.map do |row|
      ListenerStat.create(
        from:,
        to:,
        station: row["station"],
        average: row["average"],
        median: row["median"],
        maximum: row["maximum"],
        total_time: row["total_time"]
      )
    end
  end

  def calculate_stats
    sql = Snapshot.sanitize_sql_array([<<~SQL, from:, to:])
      SELECT
        source->>'server_name' AS station,
        ROUND(AVG((source->>'listeners')::int))::int AS average,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (source->>'listeners')::int))::int AS median,
        MAX((source->>'listeners')::int) AS maximum,
        ROUND(AVG((source->>'listeners')::int) * (EXTRACT(EPOCH FROM (CAST(:to AS timestamp) - CAST(:from AS timestamp))) / 60))::int AS total_time
      FROM
        snapshots,
        jsonb_array_elements(stats->'icestats'->'source') AS source
      WHERE
        created_at >= :from AND created_at < :to
      GROUP BY
        source->>'server_name'
    SQL

    Snapshot.connection.execute(sql)
  end
end
