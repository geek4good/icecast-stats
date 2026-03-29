class HourlyStatsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    to = Time.current.utc.beginning_of_hour
    from = to - 1.hour
    ListenerStatsCalculator.new(from:, to:).persist_stats
  end
end
