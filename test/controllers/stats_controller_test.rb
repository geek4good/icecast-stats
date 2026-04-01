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
end
