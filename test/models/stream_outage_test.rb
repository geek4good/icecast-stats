require "test_helper"

class StreamOutageTest < ActiveSupport::TestCase
  test "for_station scope filters by station" do
    results = StreamOutage.for_station("Surf Radio")
    results.each do |outage|
      assert_equal "Surf Radio", outage.station
    end
  end

  test "recent scope orders by detected_at desc" do
    results = StreamOutage.recent
    dates = results.map(&:detected_at)
    assert_equal dates.sort.reverse, dates
  end
end
