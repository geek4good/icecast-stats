class SnapshotJob < ApplicationJob
  queue_as :default

  def perform(*args)
    StatsSnapshotter.new.snapshot_stats
  end
end
