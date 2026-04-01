require "test_helper"
require "rake"

class StatsRollupTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task.tasks.each(&:reenable)
  end

  test "stats:backfill_daily runs without error" do
    assert_nothing_raised do
      capture_io { Rake::Task["stats:backfill_daily"].invoke }
    end
  end

  test "stats:backfill_daily is idempotent" do
    capture_io { Rake::Task["stats:backfill_daily"].invoke }
    Rake::Task["stats:backfill_daily"].reenable
    daily_count = Stat.daily.count

    capture_io { Rake::Task["stats:backfill_daily"].invoke }
    assert_equal daily_count, Stat.daily.count
  end

  test "stats:backfill_monthly creates monthly stats from daily stats" do
    # 2 monthly stats created (one per station with daily fixture data)
    assert_difference "Stat.monthly.count", 2 do
      capture_io { Rake::Task["stats:backfill_monthly"].invoke }
    end
  end

  test "stats:backfill_monthly is idempotent" do
    capture_io { Rake::Task["stats:backfill_monthly"].invoke }
    Rake::Task["stats:backfill_monthly"].reenable

    assert_no_difference "Stat.monthly.count" do
      capture_io { Rake::Task["stats:backfill_monthly"].invoke }
    end
  end

  test "stats:backfill_outages runs without error" do
    assert_nothing_raised do
      capture_io { Rake::Task["stats:backfill_outages"].invoke }
    end
  end

  test "stats:backfill runs all subtasks" do
    assert_nothing_raised do
      capture_io { Rake::Task["stats:backfill"].invoke }
    end
  end
end
