require "test_helper"

class StatsControllerTest < ActionDispatch::IntegrationTest
  test "root route resolves to stats#index" do
    assert_recognizes({controller: "stats", action: "index"}, "/")
  end

  test "stats_index route resolves to stats#index" do
    assert_recognizes({controller: "stats", action: "index"}, "/stats/index")
  end

  test "weekly route resolves to stats#weekly" do
    assert_recognizes({controller: "stats", action: "weekly"}, "/stats/weekly")
  end

  test "monthly route resolves to stats#monthly" do
    assert_recognizes({controller: "stats", action: "monthly"}, "/stats/monthly")
  end

  test "index renders successfully" do
    get root_path
    assert_response :success
  end

  test "index accepts date param" do
    get root_path(date: "2025-12-25")
    assert_response :success
  end

  test "weekly renders successfully" do
    get stats_weekly_path
    assert_response :success
  end

  test "weekly accepts week param" do
    get stats_weekly_path(week: "2025-W52")
    assert_response :success
  end

  test "monthly renders successfully" do
    get stats_monthly_path
    assert_response :success
  end

  test "monthly accepts month param" do
    get stats_monthly_path(month: "2025-12")
    assert_response :success
  end

  test "patterns route resolves to stats#patterns" do
    assert_recognizes({controller: "stats", action: "patterns"}, "/stats/patterns")
  end

  test "patterns renders successfully" do
    get stats_patterns_path
    assert_response :success
  end

  test "patterns accepts month param" do
    get stats_patterns_path(month: "2025-12")
    assert_response :success
  end

  test "patterns defaults to previous month" do
    get stats_patterns_path
    assert_response :success
    expected_month = (Date.current - 1.month).beginning_of_month.strftime("%B %Y")
    assert_includes response.body, expected_month
  end

  test "patterns shows month navigation" do
    get stats_patterns_path(month: "2025-12")
    assert_response :success
    assert_includes response.body, "December 2025"
    assert_includes response.body, "month=2025-11"
    assert_includes response.body, "month=2026-01"
  end

  test "patterns hides next link when month is current or future" do
    current_month = Date.current.strftime("%Y-%m")
    get stats_patterns_path(month: current_month)
    assert_response :success
    next_month = Date.current.next_month.strftime("%Y-%m")
    assert_not_includes response.body, "month=#{next_month}"
  end

  test "patterns includes station sections" do
    get stats_patterns_path(month: "2025-12")
    assert_response :success
    assert_includes response.body, "Surf Radio"
  end

  test "patterns handles stats with nil station" do
    Stat.create!(from: "2026-01-15 10:00:00", to: "2026-01-15 11:00:00", average: 10, median: 8, maximum: 20, total_time: 600, station: nil)
    get stats_patterns_path(month: "2026-01")
    assert_response :success
  end
end
