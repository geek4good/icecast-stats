class HourlyStatsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    now = Time.now
    to = now.beginning_of_hour
    from = to.ago(1.hour)
    ListenerStatsCalculator.new(from:, to:).persist_stats
  end
end
