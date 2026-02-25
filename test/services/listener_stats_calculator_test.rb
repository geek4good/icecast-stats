require "test_helper"

class ListenerStatsCalculatorTest < ActiveSupport::TestCase
  setup do
    @from = Time.parse("2025-12-25 10:00:00 UTC")
    @to = Time.parse("2025-12-25 10:05:00 UTC")
    @calculator = ListenerStatsCalculator.new(from: @from, to: @to)
  end

  test "calculate_stats returns array of station stats" do
    results = @calculator.calculate_stats.to_a
    assert_equal 2, results.length
  end

  test "calculate_stats calculates correct average" do
    results = @calculator.calculate_stats.to_a
    surf_radio = results.find { |r| r["station"] == "Surf Radio" }
    talay_fm = results.find { |r| r["station"] == "Talay FM" }

    assert_equal 91, surf_radio["average"]
    assert_equal 334, talay_fm["average"]
  end

  test "calculate_stats calculates correct maximum" do
    results = @calculator.calculate_stats.to_a
    surf_radio = results.find { |r| r["station"] == "Surf Radio" }
    talay_fm = results.find { |r| r["station"] == "Talay FM" }

    assert_equal 91, surf_radio["maximum"]
    assert_equal 334, talay_fm["maximum"]
  end

  test "calculate_stats calculates correct median" do
    results = @calculator.calculate_stats.to_a
    surf_radio = results.find { |r| r["station"] == "Surf Radio" }
    talay_fm = results.find { |r| r["station"] == "Talay FM" }

    assert_equal 91, surf_radio["median"]
    assert_equal 334, talay_fm["median"]
  end

  test "calculate_stats calculates correct total_time" do
    results = @calculator.calculate_stats.to_a
    surf_radio = results.find { |r| r["station"] == "Surf Radio" }
    talay_fm = results.find { |r| r["station"] == "Talay FM" }

    assert_equal 455, surf_radio["total_time"]
    assert_equal 1670, talay_fm["total_time"]
  end

  test "calculate_stats returns empty array when no snapshots in range" do
    calculator = ListenerStatsCalculator.new(
      from: Time.parse("2020-01-01 00:00:00 UTC"),
      to: Time.parse("2020-01-01 01:00:00 UTC")
    )
    results = calculator.calculate_stats.to_a
    assert_empty results
  end

  test "persist_stats creates listener stat records" do
    assert_difference "ListenerStat.count", 2 do
      @calculator.persist_stats
    end
  end

  test "persist_stats does not create duplicates for same time range" do
    @calculator.persist_stats

    assert_no_difference "ListenerStat.count" do
      @calculator.persist_stats
    end
  end

  test "persist_stats returns early if stats already exist" do
    ListenerStat.create!(
      station: "Test",
      from: @from,
      to: @to,
      average: 10,
      median: 10,
      maximum: 10,
      total_time: 600
    )

    assert_no_difference "ListenerStat.count" do
      @calculator.persist_stats
    end
  end

  test "persist_stats creates records with correct values" do
    @calculator.persist_stats

    surf_radio = ListenerStat.find_by(station: "Surf Radio", from: @from, to: @to)
    talay_fm = ListenerStat.find_by(station: "Talay FM", from: @from, to: @to)

    assert_equal 91, surf_radio.average
    assert_equal 91, surf_radio.median
    assert_equal 91, surf_radio.maximum
    assert_equal 455, surf_radio.total_time

    assert_equal 334, talay_fm.average
    assert_equal 334, talay_fm.median
    assert_equal 334, talay_fm.maximum
    assert_equal 1670, talay_fm.total_time
  end
end
