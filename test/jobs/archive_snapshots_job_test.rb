require "test_helper"

class ArchiveSnapshotsJobTest < ActiveJob::TestCase
  setup do
    @sample_stats = {"icestats" => {"source" => []}}
  end

  test "archives months before cutoff, preserves current and previous month" do
    # Travel to March 2, 2026 — cutoff will be Feb 1, so January and earlier get archived
    travel_to Time.utc(2026, 3, 2, 1, 0) do
      # Create January snapshots (should be archived)
      jan_start = Time.utc(2026, 1, 1)
      jan_snapshots = 2.times.map do |i|
        Snapshot.create!(stats: @sample_stats, created_at: jan_start + i.days + 1.hour, updated_at: jan_start + i.days + 1.hour)
      end
      create_daily_stats_for(jan_start)

      # Create February snapshots (should be preserved — previous month)
      feb_start = Time.utc(2026, 2, 1)
      2.times do |i|
        Snapshot.create!(stats: @sample_stats, created_at: feb_start + i.days, updated_at: feb_start + i.days)
      end

      # Create March snapshots (should be preserved — current month)
      mar_start = Time.utc(2026, 3, 1)
      Snapshot.create!(stats: @sample_stats, created_at: mar_start, updated_at: mar_start)

      ArchiveSnapshotsJob.perform_now

      # January archived
      assert_equal 0, Snapshot.where(id: jan_snapshots.map(&:id)).count

      # February and March preserved
      assert_equal 2, Snapshot.where(created_at: feb_start...feb_start.next_month).count
      assert_equal 1, Snapshot.where(created_at: mar_start...mar_start.next_month).count
    end
  ensure
    FileUtils.rm_rf(Rails.root.join("storage/snapshots"))
  end

  test "does nothing when no old snapshots exist" do
    travel_to Time.utc(2026, 3, 2) do
      mar_start = Time.utc(2026, 3, 1)
      Snapshot.create!(stats: @sample_stats, created_at: mar_start, updated_at: mar_start)

      assert_nothing_raised { ArchiveSnapshotsJob.perform_now }
    end
  end

  private

  def create_daily_stats_for(month_start)
    days_in_month = (month_start.to_date...month_start.to_date.next_month).count
    days_in_month.times do |i|
      day = month_start + i.days
      Stat.create!(
        station: "Surf Radio",
        from: day, to: day + 1.day,
        average: 50, median: 45, maximum: 100, total_time: 72_000
      )
    end
  end
end
