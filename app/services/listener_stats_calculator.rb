class ListenerStatsCalculator
  attr_reader :from, :to

  def initialize(from:, to:)
    @from = from
    @to = to
  end

  def calculate_stats
    return if ListenerStat.exists?(from:, to:)

    listeners_by_station.each do |station, listeners|
      average = average(listeners).round
      median = median(listeners).round
      maximum = maximum(listeners)
      total_time = (average * minutes).round

      ListenerStat.create(from:, to:, station:, average:, median:, maximum:, total_time:)
    end
  end

  def average(vals)
    vals.sum / Float(vals.size)
  end

  def median(vals)
    ary = vals.sort
    num = ary.size
    idx = num / 2
    num.odd? ? ary[idx + 1] : (ary[(idx - 1)..idx].sum / 2.0)
  end

  def maximum(vals)
    ary = vals.sort
    ary.last
  end

  def minutes
    return 0 if from > to

    seconds = to - from
    seconds / 60.0
  end

  private

  def listeners_by_station
    @listeners_by_station ||= begin
      listeners = Hash.new { |h, k| h[k] = [] }
      query_stats.each_with_object(listeners) do |item, hash|
        station, count = item.values_at("server_name", "listeners")
        hash[station] << count
      end
    end
  end

  def query_stats
    fmt = "%F %T"
    ActiveRecord::Base.connection.execute(<<~SQL)
      SELECT
        json_extract(source.value, '$.server_name') server_name,
        json_extract(source.value, '$.listeners') listeners
      FROM
        snapshots snaps,
        json_each(snaps.stats, '$.icestats.source') source
      WHERE
        snaps.created_at >= '#{from.strftime(fmt)}'
      AND
        snaps.created_at < '#{to.strftime(fmt)}';
    SQL
  end
end
