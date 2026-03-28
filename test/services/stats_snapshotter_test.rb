require "test_helper"

class StatsSnapshotterTest < ActiveSupport::TestCase
  def setup
    @snapshotter = StatsSnapshotter.new
  end

  test "responds to snapshot_stats" do
    assert_respond_to @snapshotter, :snapshot_stats
  end

  test "reads stats_url from credentials" do
    assert_not_nil Rails.application.credentials.stats_url
  end
end
