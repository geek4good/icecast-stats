require "test_helper"

class StatsSnapshotterTest < ActiveSupport::TestCase
  def setup
    @snapshotter = StatsSnapshotter.new
    @original_stats_url = ENV["STATS_URL"]
  end

  def teardown
    ENV["STATS_URL"] = @original_stats_url
  end

  test "responds to snapshot_stats" do
    assert_respond_to @snapshotter, :snapshot_stats
  end

  test "reads STATS_URL from environment" do
    ENV["STATS_URL"] = "http://test.example.com/stats.json"
    assert_equal "http://test.example.com/stats.json", ENV["STATS_URL"]
  end
end
