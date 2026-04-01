require "test_helper"

class SongPlayExtractionJobTest < ActiveJob::TestCase
  test "perform enqueues the job" do
    assert_enqueued_with(job: SongPlayExtractionJob) do
      SongPlayExtractionJob.perform_later
    end
  end

  test "perform executes without error" do
    perform_enqueued_jobs do
      SongPlayExtractionJob.perform_later
    end
  end
end
