require "test_helper"

class OutageDetectorTest < ActiveSupport::TestCase
  setup do
    @from = Time.parse("2025-12-25 10:00:00 UTC")
    @to = Time.parse("2025-12-25 11:00:00 UTC")
  end

  test "detect returns array" do
    detector = OutageDetector.new(from: @from, to: @to)
    results = detector.detect
    assert_kind_of Array, results
  end

  test "detect handles empty time range" do
    detector = OutageDetector.new(
      from: Time.parse("2020-01-01 00:00:00 UTC"),
      to: Time.parse("2020-01-01 01:00:00 UTC")
    )
    results = detector.detect
    assert_empty results
  end

  test "detect is idempotent" do
    detector = OutageDetector.new(from: @from, to: @to)
    detector.detect
    second_run = detector.detect
    assert_empty second_run
  end

  test "estimate_downtime calculates difference between stream starts" do
    detector = OutageDetector.new(from: @from, to: @to)
    downtime = detector.send(:estimate_downtime, "2025-12-25T08:00:00+0000", "2025-12-25T09:55:00+0000")
    assert_equal 6900, downtime
  end
end
