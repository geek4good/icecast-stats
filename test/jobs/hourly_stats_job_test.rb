require "test_helper"

class HourlyStatsJobTest < ActiveJob::TestCase
  test "perform enqueues the job" do
    assert_enqueued_with(job: HourlyStatsJob) do
      HourlyStatsJob.perform_later
    end
  end

  test "perform executes without error" do
    perform_enqueued_jobs do
      HourlyStatsJob.perform_later
    end
  end
end
