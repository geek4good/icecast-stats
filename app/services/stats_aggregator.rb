class StatsAggregator
  attr_reader :from, :to

  def initialize(from:, to:)
    @from = from
    @to = to
  end

  def persist_stats
    return if Stat.exists?(from:, to:)

    calculate_stats.map do |row|
      Stat.create(
        from:,
        to:,
        station: row["station"],
        average: row["average"],
        median: row["median"],
        maximum: row["maximum"],
        total_time: row["total_time"],
        snapshot_count: row["snapshot_count"]
      )
    end
  end

  def calculate_stats
    sql = Stat.sanitize_sql_array([<<~SQL, from:, to:])
      SELECT
        station,
        ROUND(AVG(average))::int AS average,
        ROUND(AVG(median))::int AS median,
        MAX(maximum) AS maximum,
        SUM(total_time) AS total_time,
        SUM(snapshot_count) AS snapshot_count
      FROM stats
      WHERE
        "from" >= :from AND "from" < :to
        AND "to" - "from" = interval '1 day'
        AND station IS NOT NULL
      GROUP BY station
    SQL

    Stat.connection.execute(sql)
  end
end
