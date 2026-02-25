require "test_helper"

class StatsControllerTest < ActionDispatch::IntegrationTest
  test "root route resolves to stats#index" do
    assert_recognizes({controller: "stats", action: "index"}, "/")
  end

  test "stats_index route resolves to stats#index" do
    assert_recognizes({controller: "stats", action: "index"}, "/stats/index")
  end
end
