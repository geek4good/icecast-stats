class DailyStatsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    to = Time.current.beginning_of_day.utc
    from = to.prev_day
    StatsCalculator.new(from:, to:).persist_stats
  end
end
