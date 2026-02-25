require "test_helper"

class SnapshotJobTest < ActiveJob::TestCase
  test "perform enqueues the job" do
    assert_enqueued_with(job: SnapshotJob) do
      SnapshotJob.perform_later
    end
  end

  test "perform executes without error" do
    perform_enqueued_jobs do
      SnapshotJob.perform_later
    end
  end
end
