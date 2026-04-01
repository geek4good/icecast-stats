require "test_helper"

class MonthlyStatsJobTest < ActiveJob::TestCase
  test "perform enqueues the job" do
    assert_enqueued_with(job: MonthlyStatsJob) do
      MonthlyStatsJob.perform_later
    end
  end

  test "perform executes without error" do
    perform_enqueued_jobs do
      MonthlyStatsJob.perform_later
    end
  end
end
