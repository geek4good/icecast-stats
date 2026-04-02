class ArchiveSnapshotsJob < ApplicationJob
  queue_as :default

  def perform
    cutoff = 1.month.ago.beginning_of_month

    oldest = Snapshot.where("created_at < ?", cutoff).minimum(:created_at)
    return unless oldest

    current = oldest.in_time_zone.beginning_of_month
    while current < cutoff
      SnapshotArchiver.new(month: current).archive
      current = current.next_month
    end
  end
end
