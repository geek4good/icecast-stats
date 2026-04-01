require "test_helper"

class DailyStatsJobTest < ActiveJob::TestCase
  test "perform enqueues the job" do
    assert_enqueued_with(job: DailyStatsJob) do
      DailyStatsJob.perform_later
    end
  end

  test "perform executes without error" do
    perform_enqueued_jobs do
      DailyStatsJob.perform_later
    end
  end
end
