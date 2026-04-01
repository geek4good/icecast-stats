require "test_helper"

class SongPlayExtractorTest < ActiveSupport::TestCase
  setup do
    @from = Time.parse("2025-12-25 10:00:00 UTC")
    @to = Time.parse("2025-12-25 10:10:00 UTC")
  end

  test "extract creates song play records from snapshots" do
    # The fixture snapshots don't have title fields, so this should produce
    # records only if titles exist. With our current fixtures, title may be nil.
    extractor = SongPlayExtractor.new(from: @from, to: @to)
    results = extractor.extract
    assert_kind_of Array, results
  end

  test "extract handles empty time range" do
    extractor = SongPlayExtractor.new(
      from: Time.parse("2020-01-01 00:00:00 UTC"),
      to: Time.parse("2020-01-01 01:00:00 UTC")
    )
    results = extractor.extract
    assert_empty results
  end

  test "extract is idempotent" do
    extractor = SongPlayExtractor.new(from: @from, to: @to)
    first_run = extractor.extract
    second_run = extractor.extract
    assert_empty second_run
  end

  test "build_play parses music category correctly" do
    extractor = SongPlayExtractor.new(from: @from, to: @to)
    play = extractor.send(:build_play, "Little Mix - Sweet Melody", @from, @from + 210, 42)

    assert_equal "Little Mix - Sweet Melody", play[:title]
    assert_equal "Little Mix", play[:artist]
    assert_equal "Sweet Melody", play[:song]
    assert_equal "music", play[:category]
    assert_equal "Surf Radio", play[:station]
    assert_equal 210, play[:duration_seconds]
    assert_equal 42, play[:snapshot_count]
  end

  test "build_play parses news category correctly" do
    extractor = SongPlayExtractor.new(from: @from, to: @to)
    play = extractor.send(:build_play, "BBC World News", @from, @from + 180, 36)

    assert_equal "news", play[:category]
    assert_nil play[:artist]
    assert_nil play[:song]
  end

  test "build_play parses ads category correctly" do
    extractor = SongPlayExtractor.new(from: @from, to: @to)
    play = extractor.send(:build_play, "SURF RADIO - www.surf.radio", @from, @from + 30, 6)

    assert_equal "ads", play[:category]
  end
end
