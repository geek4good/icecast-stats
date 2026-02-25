require "test_helper"

class SnapshotTest < ActiveSupport::TestCase
  test "stats is stored as jsonb" do
    snapshot = snapshots(:one)
    assert_instance_of Hash, snapshot.stats
    assert snapshot.stats.key?("icestats")
  end

  test "stats contains source array" do
    snapshot = snapshots(:one)
    sources = snapshot.stats.dig("icestats", "source")
    assert_instance_of Array, sources
    assert_equal 2, sources.length
  end

  test "stats source contains listeners" do
    snapshot = snapshots(:one)
    sources = snapshot.stats.dig("icestats", "source")
    surf_radio = sources.find { |s| s["server_name"] == "Surf Radio" }
    assert_equal 91, surf_radio["listeners"]
  end

  test "can query jsonb data" do
    snapshots = Snapshot.where("stats->'icestats'->'source' @> '[{\"server_name\": \"Surf Radio\"}]'")
    assert_equal 2, snapshots.count
    snapshots.each do |snapshot|
      assert snapshot.stats.dig("icestats", "source").any? { |s| s["server_name"] == "Surf Radio" }
    end
  end
end
