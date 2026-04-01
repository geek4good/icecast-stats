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
end
