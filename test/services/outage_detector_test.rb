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

  test "detects snapshot gaps as outages" do
    base = Time.parse("2025-12-25 10:10:00 UTC")
    create_snapshot(base)
    create_snapshot(base + 5.seconds)
    create_snapshot(base + 65.seconds) # 60-second gap

    detector = OutageDetector.new(from: base, to: base + 2.minutes)
    results = detector.detect

    assert_equal 2, results.size # one per station (Surf Radio, Talay FM)
    results.each do |outage|
      assert_equal 60, outage.estimated_downtime_seconds
      assert_nil outage.previous_stream_start
      assert_nil outage.new_stream_start
      assert_equal base + 65.seconds, outage.detected_at
    end
    assert_equal ["Surf Radio", "Talay FM"], results.map(&:station).sort
  end

  test "no false positives for normal snapshot intervals" do
    base = Time.parse("2025-12-25 10:10:00 UTC")
    create_snapshot(base)
    create_snapshot(base + 5.seconds)
    create_snapshot(base + 10.seconds)

    detector = OutageDetector.new(from: base, to: base + 1.minute)
    results = detector.detect

    assert_empty results
  end

  test "gap detection is idempotent" do
    base = Time.parse("2025-12-25 10:10:00 UTC")
    create_snapshot(base)
    create_snapshot(base + 65.seconds)

    detector = OutageDetector.new(from: base, to: base + 2.minutes)
    first_run = detector.detect
    assert_equal 2, first_run.size

    second_run = detector.detect
    assert_empty second_run
  end

  private

  def create_snapshot(time)
    Snapshot.create!(
      created_at: time,
      updated_at: time,
      stats: {
        "icestats" => {
          "source" => [
            { "server_name" => "Surf Radio", "listeners" => 100, "stream_start_iso8601" => "2025-12-25T08:00:00+0000" },
            { "server_name" => "Talay FM", "listeners" => 200, "stream_start_iso8601" => "2025-12-25T08:00:00+0000" }
          ]
        }
      }
    )
  end
end
