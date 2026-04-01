require "test_helper"

class SongsControllerTest < ActionDispatch::IntegrationTest
  test "songs route resolves to songs#index" do
    assert_recognizes({controller: "songs", action: "index"}, "/songs")
  end

  test "index renders successfully" do
    get songs_path
    assert_response :success
  end

  test "index accepts period param" do
    get songs_path(period: "this_month")
    assert_response :success
  end

  test "index with last_month period renders successfully" do
    get songs_path(period: "last_month")
    assert_response :success
  end

  test "index with this_year period renders successfully" do
    get songs_path(period: "this_year")
    assert_response :success
    assert_includes response.body, "This Year"
  end

  test "index with all_time period renders successfully" do
    get songs_path(period: "all_time")
    assert_response :success
    assert_includes response.body, "All Time"
  end

  test "this_year period label is correct" do
    get songs_path(period: "this_year")
    assert_includes response.body, "Songs — This Year"
  end

  test "all_time period label is correct" do
    get songs_path(period: "all_time")
    assert_includes response.body, "Songs — All Time"
  end

  test "period selector includes all period links" do
    get songs_path
    assert_response :success
    assert_includes response.body, 'period=this_week'
    assert_includes response.body, 'period=this_month'
    assert_includes response.body, 'period=last_month'
    assert_includes response.body, 'period=this_year'
    assert_includes response.body, 'period=all_time'
  end
end
