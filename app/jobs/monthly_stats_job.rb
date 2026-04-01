class MonthlyStatsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    to = Time.current.beginning_of_month.utc
    from = to.prev_month
    StatsAggregator.new(from:, to:).persist_stats
  end
end
