require "test_helper"

class StatTest < ActiveSupport::TestCase
  test "surf_radio scope filters by station" do
    results = Stat.surf_radio
    assert_equal 9, results.count
    results.each do |stat|
      assert_equal "Surf Radio", stat.station
    end
  end

  test "talay_fm scope filters by station" do
    results = Stat.talay_fm
    assert_equal 3, results.count
    assert_equal "Talay FM", results.first.station
  end

  test "hourly scope returns only hourly stats" do
    results = Stat.hourly
    results.each do |stat|
      assert_equal 1.hour, stat.to - stat.from
    end
  end

  test "daily scope returns only daily stats" do
    results = Stat.daily
    results.each do |stat|
      assert_equal 1.day, stat.to - stat.from
    end
  end

  test "on scope filters by date range" do
    date = Date.new(2025, 12, 25)
    results = Stat.on(date)
    assert_equal 2, results.count

    results.each do |stat|
      assert_equal Time.zone.local(2025, 12, 25), stat.from
      assert_equal Time.zone.local(2025, 12, 26), stat.to
    end
  end

  test "on scope does not return stats from other dates" do
    date = Date.new(2025, 12, 24)
    results = Stat.on(date)
    assert_equal 1, results.count
    assert_equal "Surf Radio", results.first.station
  end

  test "unique index on station, from and to prevents duplicates" do
    existing = stats(:surf_radio_today)
    duplicate = Stat.new(
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
    existing = stats(:surf_radio_today)
    different_station = Stat.new(
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
