require "test_helper"

class ListenersControllerTest < ActionDispatch::IntegrationTest
  # ── Route resolution ──

  test "root resolves to listeners#show with defaults" do
    assert_recognizes(
      {controller: "listeners", action: "show", station: "surf-radio", interval: "daily"},
      "/"
    )
  end

  test "listeners route resolves to listeners#show" do
    assert_recognizes(
      {controller: "listeners", action: "show", station: "surf-radio", interval: "daily"},
      "/surf-radio/listeners/daily"
    )
  end

  test "listeners patterns route resolves to listeners#show" do
    assert_recognizes(
      {controller: "listeners", action: "show", station: "talay-fm", interval: "patterns"},
      "/talay-fm/listeners/patterns"
    )
  end

  # ── Daily view ──

  test "daily renders successfully" do
    get listeners_path(station: "surf-radio", interval: "daily")
    assert_response :success
  end

  test "daily accepts date param" do
    get listeners_path(station: "surf-radio", interval: "daily", date: "2025-12-25")
    assert_response :success
  end

  test "daily with invalid date falls back gracefully" do
    get listeners_path(station: "surf-radio", interval: "daily", date: "not-a-date")
    assert_response :success
    # Should fall back to yesterday and still render
  end

  test "daily with impossible date falls back gracefully" do
    get listeners_path(station: "surf-radio", interval: "daily", date: "2025-13-45")
    assert_response :success
  end

  test "daily shows title with station name" do
    get listeners_path(station: "surf-radio", interval: "daily")
    assert_includes response.body, "Surf Radio"
  end

  test "daily shows no-data message when no stats" do
    get listeners_path(station: "talay-fm", interval: "daily")
    assert_response :success
    assert_includes response.body, "No stats recorded yet"
  end

  # ── Weekly view ──

  test "weekly renders successfully" do
    get listeners_path(station: "surf-radio", interval: "weekly")
    assert_response :success
  end

  test "weekly accepts week param" do
    get listeners_path(station: "surf-radio", interval: "weekly", week: "2025-W52")
    assert_response :success
  end

  test "weekly with invalid week format falls back gracefully" do
    get listeners_path(station: "surf-radio", interval: "weekly", week: "not-a-week")
    assert_response :success
  end

  test "weekly with nonsensical week falls back gracefully" do
    get listeners_path(station: "surf-radio", interval: "weekly", week: "9999-W99")
    assert_response :success
  end

  test "weekly with week zero falls back to default" do
    get listeners_path(station: "surf-radio", interval: "weekly", week: "2025-W00")
    assert_response :success
    # Should fall back to last week, not parse W00
    default_label = (Date.current - 1.week).beginning_of_week(:monday).strftime("%-d %b")
    assert_includes response.body, default_label
  end

  test "weekly with week 54 falls back to default" do
    get listeners_path(station: "surf-radio", interval: "weekly", week: "2025-W54")
    assert_response :success
    default_label = (Date.current - 1.week).beginning_of_week(:monday).strftime("%-d %b")
    assert_includes response.body, default_label
  end

  test "weekly with single digit week falls back to default" do
    get listeners_path(station: "surf-radio", interval: "weekly", week: "2025-W5")
    assert_response :success
    default_label = (Date.current - 1.week).beginning_of_week(:monday).strftime("%-d %b")
    assert_includes response.body, default_label
  end

  test "weekly accepts valid week 01" do
    get listeners_path(station: "surf-radio", interval: "weekly", week: "2025-W01")
    assert_response :success
  end

  test "weekly accepts valid week 53" do
    get listeners_path(station: "surf-radio", interval: "weekly", week: "2020-W53")
    assert_response :success
    # 2020 has 53 ISO weeks
  end

  test "weekly shows no-data message when no stats" do
    get listeners_path(station: "talay-fm", interval: "weekly")
    assert_response :success
    assert_includes response.body, "No stats recorded for this week"
  end

  test "weekly renders summary row with stats" do
    # Default weekly view is last week, scope is .daily (1-day intervals)
    week_start = (Date.current - 1.week).beginning_of_week(:monday)
    week_end = week_start + 7.days
    (week_start...week_end).each do |day|
      next_day = day + 1.day
      Stat.create!(
        from: Time.zone.local(day.year, day.month, day.day, 0, 0),
        to: Time.zone.local(next_day.year, next_day.month, next_day.day, 0, 0),
        average: 50, median: 40, maximum: 100,
        total_time: 3600, snapshot_count: 12,
        station: "Surf Radio"
      )
    end
    get listeners_path(station: "surf-radio", interval: "weekly")
    assert_response :success
    # Summary row should contain Avg and Peak from the consolidated query
    assert_includes response.body, "Avg:"
    assert_includes response.body, "Peak:"
  end

  # ── Monthly view ──

  test "monthly renders successfully" do
    get listeners_path(station: "surf-radio", interval: "monthly")
    assert_response :success
  end

  test "monthly accepts month param" do
    get listeners_path(station: "surf-radio", interval: "monthly", month: "2025-12")
    assert_response :success
  end

  test "monthly with invalid month falls back gracefully" do
    get listeners_path(station: "surf-radio", interval: "monthly", month: "abc-def")
    assert_response :success
  end

  test "monthly with out-of-range month falls back gracefully" do
    get listeners_path(station: "surf-radio", interval: "monthly", month: "2025-99")
    assert_response :success
  end

  test "monthly with month zero falls back gracefully" do
    get listeners_path(station: "surf-radio", interval: "monthly", month: "2025-00")
    assert_response :success
    expected_month = (Date.current - 1.month).beginning_of_month.strftime("%B %Y")
    assert_includes response.body, expected_month
  end

  test "monthly with month thirteen falls back gracefully" do
    get listeners_path(station: "surf-radio", interval: "monthly", month: "2025-13")
    assert_response :success
    expected_month = (Date.current - 1.month).beginning_of_month.strftime("%B %Y")
    assert_includes response.body, expected_month
  end

  test "monthly with single-digit month falls back gracefully" do
    get listeners_path(station: "surf-radio", interval: "monthly", month: "2025-6")
    assert_response :success
    expected_month = (Date.current - 1.month).beginning_of_month.strftime("%B %Y")
    assert_includes response.body, expected_month
  end

  test "monthly shows month label" do
    get listeners_path(station: "surf-radio", interval: "monthly", month: "2025-12")
    assert_response :success
    assert_includes response.body, "December 2025"
  end

  test "monthly shows no-data message when no stats" do
    get listeners_path(station: "talay-fm", interval: "monthly")
    assert_response :success
    assert_includes response.body, "No stats recorded for this month"
  end

  test "monthly renders summary row with stats" do
    month_start = (Date.current - 1.month).beginning_of_month
    5.times do |i|
      day = month_start + i.days
      next_day = day + 1.day
      Stat.create!(
        from: Time.zone.local(day.year, day.month, day.day, 0, 0),
        to: Time.zone.local(next_day.year, next_day.month, next_day.day, 0, 0),
        average: 60, median: 50, maximum: 120,
        total_time: 3600, snapshot_count: 24,
        station: "Surf Radio"
      )
    end
    get listeners_path(station: "surf-radio", interval: "monthly")
    assert_response :success
    assert_includes response.body, "Avg:"
    assert_includes response.body, "Peak:"
  end

  # ── Patterns view ──

  test "patterns renders successfully" do
    get listeners_path(station: "surf-radio", interval: "patterns")
    assert_response :success
  end

  test "patterns accepts month param" do
    get listeners_path(station: "surf-radio", interval: "patterns", month: "2025-12")
    assert_response :success
  end

  test "patterns defaults to previous month" do
    get listeners_path(station: "surf-radio", interval: "patterns")
    assert_response :success
    expected_month = (Date.current - 1.month).beginning_of_month.strftime("%B %Y")
    assert_includes response.body, expected_month
  end

  test "patterns shows month navigation" do
    get listeners_path(station: "surf-radio", interval: "patterns", month: "2025-12")
    assert_response :success
    assert_includes response.body, "December 2025"
    assert_includes response.body, "2025-11"
    assert_includes response.body, "2026-01"
  end

  test "patterns hides next link when month is current or future" do
    current_month = Date.current.strftime("%Y-%m")
    get listeners_path(station: "surf-radio", interval: "patterns", month: current_month)
    assert_response :success
    next_month = Date.current.next_month.strftime("%Y-%m")
    assert_not_includes response.body, "month=#{next_month}"
  end

  test "patterns with invalid month falls back gracefully" do
    get listeners_path(station: "surf-radio", interval: "patterns", month: "garbage")
    assert_response :success
  end

  test "patterns with month zero falls back gracefully" do
    get listeners_path(station: "surf-radio", interval: "patterns", month: "2025-00")
    assert_response :success
    expected_month = (Date.current - 1.month).beginning_of_month.strftime("%B %Y")
    assert_includes response.body, expected_month
  end

  test "patterns with month thirteen falls back gracefully" do
    get listeners_path(station: "surf-radio", interval: "patterns", month: "2025-13")
    assert_response :success
    expected_month = (Date.current - 1.month).beginning_of_month.strftime("%B %Y")
    assert_includes response.body, expected_month
  end

  test "patterns shows no-data message when no stats" do
    get listeners_path(station: "talay-fm", interval: "patterns")
    assert_response :success
    assert_includes response.body, "No stats recorded"
  end

  test "patterns renders all chart sections with data" do
    # Create stats across multiple days and hours to populate all 3 chart sections
    (1..7).each do |day|
      (0..23).each do |hour|
        Stat.create!(
          from: Time.utc(2025, 12, day, hour, 0),
          to: Time.utc(2025, 12, day, hour + 1, 0),
          average: 10 + day + hour,
          median: 8 + day,
          maximum: 20 + day + hour,
          total_time: 3600,
          snapshot_count: 12,
          station: "Surf Radio"
        )
      end
    end
    get listeners_path(station: "surf-radio", interval: "patterns", month: "2025-12")
    assert_response :success
    assert_includes response.body, "Day-of-Week Averages"
    assert_includes response.body, "Hour × Day Heatmap"
    assert_includes response.body, "Weekend vs Weekday"
  end

  test "patterns renders dow chart without heatmap data" do
    # Stats on only one day — enough for DOW chart but limited heatmap
    Stat.create!(
      from: Time.utc(2025, 12, 1, 12, 0),
      to: Time.utc(2025, 12, 1, 13, 0),
      average: 50, median: 40, maximum: 80,
      total_time: 3600, snapshot_count: 12,
      station: "Surf Radio"
    )
    get listeners_path(station: "surf-radio", interval: "patterns", month: "2025-12")
    assert_response :success
    assert_includes response.body, "Day-of-Week Averages"
  end

  # ── Station scoping ──

  test "invalid station slug redirects to default station" do
    get "/nonexistent-station/listeners/daily"
    assert_redirected_to "/surf-radio/listeners/daily"
  end

  test "talay-fm station renders successfully" do
    get listeners_path(station: "talay-fm", interval: "daily")
    assert_response :success
    assert_includes response.body, "Talay FM"
  end

  test "surf-radio station renders successfully" do
    get listeners_path(station: "surf-radio", interval: "daily")
    assert_response :success
    assert_includes response.body, "Surf Radio"
  end

  # ── Interval validation ──

  test "invalid interval falls back to daily" do
    get listeners_path(station: "surf-radio", interval: "garbage")
    assert_response :success
    # Should render daily view without error
  end

  test "convenience redirect from /listeners to /listeners/daily" do
    get "/surf-radio/listeners"
    assert_redirected_to "/surf-radio/listeners/daily"
  end

  # ── Navigation components present ──

  test "daily view includes station tabs" do
    get listeners_path(station: "surf-radio", interval: "daily")
    assert_response :success
    assert_includes response.body, "Talay FM"
  end

  test "daily view includes interval tabs" do
    get listeners_path(station: "surf-radio", interval: "daily")
    assert_response :success
    # Interval tabs render as nav-interval elements
    assert_includes response.body, "Daily"
  end

  test "daily view includes view tabs" do
    get listeners_path(station: "surf-radio", interval: "daily")
    assert_response :success
    assert_includes response.body, "Songs"
  end
end
