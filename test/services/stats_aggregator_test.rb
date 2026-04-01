require "test_helper"

class StatsAggregatorTest < ActiveSupport::TestCase
  setup do
    # Use a range outside of fixture data (fixtures are in Dec 2025)
    @from = Time.zone.local(2026, 2, 1)
    @to = Time.zone.local(2026, 3, 1)

    # Create daily stat rows within the range
    Stat.create!(station: "Surf Radio", from: Time.zone.local(2026, 2, 10), to: Time.zone.local(2026, 2, 11),
      average: 50, median: 45, maximum: 100, total_time: 72000, snapshot_count: 24)
    Stat.create!(station: "Surf Radio", from: Time.zone.local(2026, 2, 11), to: Time.zone.local(2026, 2, 12),
      average: 60, median: 55, maximum: 120, total_time: 86400, snapshot_count: 24)
    Stat.create!(station: "Talay FM", from: Time.zone.local(2026, 2, 10), to: Time.zone.local(2026, 2, 11),
      average: 200, median: 180, maximum: 400, total_time: 288000, snapshot_count: 24)

    # Create an hourly stat in the same range (should be excluded)
    Stat.create!(station: "Surf Radio", from: Time.zone.local(2026, 2, 10, 10), to: Time.zone.local(2026, 2, 10, 11),
      average: 999, median: 999, maximum: 999, total_time: 999, snapshot_count: 1)

    @aggregator = StatsAggregator.new(from: @from, to: @to)
  end

  test "calculate_stats returns array of station stats" do
    results = @aggregator.calculate_stats.to_a
    assert_equal 2, results.length
  end

  test "calculate_stats calculates correct average" do
    results = @aggregator.calculate_stats.to_a
    surf_radio = results.find { |r| r["station"] == "Surf Radio" }
    talay_fm = results.find { |r| r["station"] == "Talay FM" }

    assert_equal 55, surf_radio["average"]
    assert_equal 200, talay_fm["average"]
  end

  test "calculate_stats calculates correct maximum" do
    results = @aggregator.calculate_stats.to_a
    surf_radio = results.find { |r| r["station"] == "Surf Radio" }
    talay_fm = results.find { |r| r["station"] == "Talay FM" }

    assert_equal 120, surf_radio["maximum"]
    assert_equal 400, talay_fm["maximum"]
  end

  test "calculate_stats calculates correct median" do
    results = @aggregator.calculate_stats.to_a
    surf_radio = results.find { |r| r["station"] == "Surf Radio" }

    assert_equal 50, surf_radio["median"]
  end

  test "calculate_stats calculates correct total_time" do
    results = @aggregator.calculate_stats.to_a
    surf_radio = results.find { |r| r["station"] == "Surf Radio" }
    talay_fm = results.find { |r| r["station"] == "Talay FM" }

    assert_equal 158400, surf_radio["total_time"]
    assert_equal 288000, talay_fm["total_time"]
  end

  test "calculate_stats calculates correct snapshot_count" do
    results = @aggregator.calculate_stats.to_a
    surf_radio = results.find { |r| r["station"] == "Surf Radio" }

    assert_equal 48, surf_radio["snapshot_count"]
  end

  test "calculate_stats returns empty array when no stats in range" do
    aggregator = StatsAggregator.new(
      from: Time.parse("2020-01-01 00:00:00 UTC"),
      to: Time.parse("2020-02-01 00:00:00 UTC")
    )
    results = aggregator.calculate_stats.to_a
    assert_empty results
  end

  test "calculate_stats excludes non-daily rows" do
    results = @aggregator.calculate_stats.to_a
    surf_radio = results.find { |r| r["station"] == "Surf Radio" }

    # If the hourly row (avg 999) were included, the average would be much higher
    assert_equal 55, surf_radio["average"]
  end

  test "calculate_stats excludes nil station rows" do
    Stat.create!(station: nil, from: Time.zone.local(2026, 2, 10), to: Time.zone.local(2026, 2, 11),
      average: 999, median: 999, maximum: 999, total_time: 999, snapshot_count: 1)

    results = @aggregator.calculate_stats.to_a
    stations = results.map { |r| r["station"] }
    assert_not_includes stations, nil
  end

  test "persist_stats creates stat records" do
    assert_difference "Stat.count", 2 do
      @aggregator.persist_stats
    end
  end

  test "persist_stats does not create duplicates for same time range" do
    @aggregator.persist_stats

    assert_no_difference "Stat.count" do
      @aggregator.persist_stats
    end
  end

  test "persist_stats creates records with correct values" do
    @aggregator.persist_stats

    surf_radio = Stat.find_by(station: "Surf Radio", from: @from, to: @to)
    talay_fm = Stat.find_by(station: "Talay FM", from: @from, to: @to)

    assert_equal 55, surf_radio.average
    assert_equal 50, surf_radio.median
    assert_equal 120, surf_radio.maximum
    assert_equal 158400, surf_radio.total_time
    assert_equal 48, surf_radio.snapshot_count

    assert_equal 200, talay_fm.average
    assert_equal 180, talay_fm.median
    assert_equal 400, talay_fm.maximum
    assert_equal 288000, talay_fm.total_time
    assert_equal 24, talay_fm.snapshot_count
  end
end
