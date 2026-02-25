class ListenerStatsCalculator
  def calculate_stats(from, to)
    return if ListenerStat.exists?(from:, to:)

    listeners = Snapshot
      .where("created_at >= ?", from)
      .where("created_at < ?", to)
      .pluck(Arel.sql("json_extract(stats, '$.icestats.source[0].listeners')"))

    average = average(listeners).round
    median = median(listeners).round
    maximum = maximum(listeners)
    total_time = (average * minutes).round

    ListenerStat.create(average:, median:, maximum:, total_time:)
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

  def minutes(from, to)
    return 0 if from > to

    seconds = to - from
    seconds / 60.0
  end
end
