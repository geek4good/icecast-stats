require "test_helper"

class ListenerStatTest < ActiveSupport::TestCase
  test "surf_radio scope filters by station" do
    results = ListenerStat.surf_radio
    assert_equal 2, results.count
    results.each do |stat|
      assert_equal "Surf Radio", stat.station
    end
  end

  test "talay_fm scope filters by station" do
    results = ListenerStat.talay_fm
    assert_equal 1, results.count
    assert_equal "Talay FM", results.first.station
  end

  test "on scope filters by date range" do
    date = Date.new(2025, 12, 25)
    results = ListenerStat.on(date)
    assert_equal 2, results.count

    results.each do |stat|
      assert_equal date.beginning_of_day, stat.from
      assert_equal date.next_day.beginning_of_day, stat.to
    end
  end

  test "on scope does not return stats from other dates" do
    date = Date.new(2025, 12, 24)
    results = ListenerStat.on(date)
    assert_equal 1, results.count
    assert_equal "Surf Radio", results.first.station
  end

  test "unique index on station, from and to prevents duplicates" do
    existing = listener_stats(:surf_radio_today)
    duplicate = ListenerStat.new(
      station: existing.station,
      from: existing.from,
      to: existing.to,
      average: 10,
      median: 10,
      maximum: 10,
      total_time: 600
    )
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save }
  end

  test "allows same time range for different stations" do
    existing = listener_stats(:surf_radio_today)
    different_station = ListenerStat.new(
      station: "Different Station",
      from: existing.from,
      to: existing.to,
      average: 10,
      median: 10,
      maximum: 10,
      total_time: 600
    )
    assert different_station.save
  end
end
