require "test_helper"

class SongPlayTest < ActiveSupport::TestCase
  test "music scope returns only music" do
    results = SongPlay.music
    results.each do |play|
      assert_equal "music", play.category
    end
  end

  test "news scope returns only news" do
    results = SongPlay.news
    assert results.all? { |p| p.category == "news" }
  end

  test "ads scope returns only ads" do
    results = SongPlay.ads
    assert results.all? { |p| p.category == "ads" }
  end

  test "for_station scope filters by station" do
    results = SongPlay.for_station("Surf Radio")
    results.each do |play|
      assert_equal "Surf Radio", play.station
    end
  end

  test "categorize returns news for BBC World News" do
    assert_equal "news", SongPlay.categorize("BBC World News")
  end

  test "categorize returns ads for station tagline" do
    assert_equal "ads", SongPlay.categorize("SURF RADIO - www.surf.radio")
  end

  test "categorize returns music for everything else" do
    assert_equal "music", SongPlay.categorize("Little Mix - Sweet Melody")
  end

  test "parse_artist_and_song splits on dash" do
    result = SongPlay.parse_artist_and_song("Little Mix - Sweet Melody")
    assert_equal "Little Mix", result[:artist]
    assert_equal "Sweet Melody", result[:song]
  end

  test "parse_artist_and_song handles no dash" do
    result = SongPlay.parse_artist_and_song("BBC World News")
    assert_nil result[:artist]
    assert_nil result[:song]
  end

  test "parse_artist_and_song handles multiple dashes" do
    result = SongPlay.parse_artist_and_song("AC/DC - Back in Black - Remastered")
    assert_equal "AC/DC", result[:artist]
    assert_equal "Back in Black - Remastered", result[:song]
  end
end
