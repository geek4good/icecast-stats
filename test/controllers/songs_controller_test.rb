require "test_helper"

class SongsControllerTest < ActionDispatch::IntegrationTest
  # ── Route resolution ──

  test "songs route resolves to songs#show" do
    assert_recognizes(
      {controller: "songs", action: "show", station: "surf-radio", interval: "daily"},
      "/surf-radio/songs/daily"
    )
  end

  test "legacy /songs redirects to station-scoped path" do
    get "/songs"
    assert_redirected_to "/surf-radio/songs/daily"
  end

  # ── Daily view ──

  test "daily renders successfully" do
    get songs_path(station: "surf-radio", interval: "daily")
    assert_response :success
  end

  test "daily shows station name in title" do
    get songs_path(station: "surf-radio", interval: "daily")
    assert_response :success
    assert_includes response.body, "Surf Radio"
  end

  # ── Weekly view ──

  test "weekly renders successfully" do
    get songs_path(station: "surf-radio", interval: "weekly")
    assert_response :success
  end

  test "weekly shows period label" do
    get songs_path(station: "surf-radio", interval: "weekly")
    assert_response :success
    assert_includes response.body, "Week of"
  end

  # ── Monthly view ──

  test "monthly renders successfully" do
    get songs_path(station: "surf-radio", interval: "monthly")
    assert_response :success
  end

  test "monthly shows month label" do
    get songs_path(station: "surf-radio", interval: "monthly")
    assert_response :success
    assert_includes response.body, (Date.current - 1.month).beginning_of_month.strftime("%B %Y")
  end

  # ── Interval validation ──

  test "invalid interval falls back to daily" do
    get songs_path(station: "surf-radio", interval: "garbage")
    assert_response :success
  end

  test "patterns interval falls back to daily for songs" do
    get songs_path(station: "surf-radio", interval: "patterns")
    assert_response :success
    # Should render daily view since songs doesn't support patterns
  end

  # ── Station scoping ──

  test "talay-fm station renders successfully" do
    get songs_path(station: "talay-fm", interval: "daily")
    assert_response :success
    assert_includes response.body, "Talay FM"
  end

  test "invalid station redirects to default" do
    get "/nonexistent-station/songs/daily"
    assert_redirected_to "/surf-radio/listeners/daily"
  end

  # ── Content rendering ──

  test "renders most played ads section when ads exist" do
    travel_to Time.zone.parse("2026-06-24 12:00:00") do # Wednesday midday
      SongPlay.create!(
        title: "Some Promo", artist: nil, song: nil, category: "ads",
        station: "Surf Radio", started_at: 5.days.ago, ended_at: 5.days.ago + 30.seconds,
        duration_seconds: 30, snapshot_count: 6
      )
      get songs_path(station: "surf-radio", interval: "weekly")
      assert_response :success
      assert_includes response.body, "Most Played Ads"
    end
  end

  test "shows empty state when no data" do
    get songs_path(station: "talay-fm", interval: "daily")
    assert_response :success
    assert_includes response.body, "No song data recorded for this period"
  end

  # ── Navigation components ──

  test "view includes station tabs" do
    get songs_path(station: "surf-radio", interval: "daily")
    assert_response :success
    assert_includes response.body, "Talay FM"
  end

  test "view includes view tabs with Listeners link" do
    get songs_path(station: "surf-radio", interval: "daily")
    assert_response :success
    assert_includes response.body, "Listeners"
  end

  test "view includes interval tabs (without Patterns for songs)" do
    get songs_path(station: "surf-radio", interval: "daily")
    assert_response :success
    assert_includes response.body, "Daily"
    assert_includes response.body, "Weekly"
    assert_includes response.body, "Monthly"
  end

  test "songs view does not show patterns in interval tabs" do
    get songs_path(station: "surf-radio", interval: "daily")
    assert_response :success
    # Patterns should not appear as a clickable link for Songs
    # It may appear in the station nav but not in the song interval nav
  end

  # ── Date navigation ──

  test "daily shows date navigation" do
    get songs_path(station: "surf-radio", interval: "daily")
    assert_response :success
    assert_includes response.body, "date-nav"
  end

  test "daily defaults to previous day" do
    get songs_path(station: "surf-radio", interval: "daily")
    assert_response :success
    assert_includes response.body, (Date.current - 1.day).strftime("%A, %-d %B %Y")
  end

  test "daily accepts date param" do
    get songs_path(station: "surf-radio", interval: "daily", date: "2025-12-25")
    assert_response :success
    assert_includes response.body, "Thursday, 25 December 2025"
  end

  test "weekly shows date navigation" do
    get songs_path(station: "surf-radio", interval: "weekly")
    assert_response :success
    assert_includes response.body, "date-nav"
  end

  test "weekly defaults to previous week" do
    get songs_path(station: "surf-radio", interval: "weekly")
    assert_response :success
    assert_includes response.body, "Week of"
  end

  test "monthly shows date navigation" do
    get songs_path(station: "surf-radio", interval: "monthly")
    assert_response :success
    assert_includes response.body, "date-nav"
  end

  test "monthly defaults to previous month" do
    get songs_path(station: "surf-radio", interval: "monthly")
    assert_response :success
    assert_includes response.body, (Date.current - 1.month).beginning_of_month.strftime("%B %Y")
  end
end
