require "test_helper"

class StatsSnapshotterTest < ActiveSupport::TestCase
  def setup
    @snapshotter = StatsSnapshotter.new
    @snapshotter.define_singleton_method(:uri) { URI("http://test.local/stats") }
  end

  def teardown
    Net::HTTP.singleton_class.send(:remove_method, :get_response)
  rescue NameError
    # No singleton method to remove
  end

  def stub_response(body: nil, error: nil)
    response = Object.new
    response.define_singleton_method(:value) { raise error if error }
    response.define_singleton_method(:body) { body } if body
    Net::HTTP.define_singleton_method(:get_response) { |*| response }
  end

  def capture_log_errors
    errors = []
    Rails.logger.define_singleton_method(:error) { |msg| errors << msg }
    yield
    errors
  ensure
    begin
      Rails.logger.singleton_class.send(:remove_method, :error)
    rescue NameError
    end
  end

  test "responds to snapshot_stats" do
    assert_respond_to @snapshotter, :snapshot_stats
  end

  test "reads stats_url from credentials" do
    skip "RAILS_MASTER_KEY not available" unless Rails.application.credentials.stats_url
    assert_kind_of String, Rails.application.credentials.stats_url
  end

  test "creates snapshot from successful response" do
    stub_response(body: '{"icestats":{"source":[]}}')

    assert_difference "Snapshot.count", 1 do
      @snapshot = @snapshotter.snapshot_stats
    end

    assert_equal({"icestats" => {"source" => []}}, @snapshot.stats)
  end

  test "handles http error gracefully" do
    stub_response(error: StandardError.new("HTTP 500"))

    errors = capture_log_errors do
      assert_no_difference "Snapshot.count" do
        @snapshotter.snapshot_stats
      end
    end

    refute_empty errors
    assert_includes errors.first, "HTTP 500"
  end

  test "handles network failure gracefully" do
    Net::HTTP.define_singleton_method(:get_response) { |*| raise Errno::ECONNREFUSED, "Connection refused" }

    errors = capture_log_errors do
      assert_no_difference "Snapshot.count" do
        @snapshotter.snapshot_stats
      end
    end

    refute_empty errors
    assert_includes errors.first, "Connection refused"
  end
end
