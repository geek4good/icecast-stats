require "minitest/autorun"
require "nokogiri"
require "active_support"
require "active_support/core_ext/string"
require "phlex"

require_relative "../../app/components/base_svg_component"
require_relative "../../app/components/bar_chart_component"

class BarChartComponentTest < Minitest::Test
  def sample_stats
    [
      ["0", 10, 25, 12],
      ["1", 15, 30, 18],
      ["2", 8, 20, 10],
      ["3", 0, 0, 0]
    ]
  end

  def render_component(component)
    Nokogiri::HTML.fragment(component.call)
  end

  def test_renders_svg_element
    doc = render_component(BarChartComponent.new(stats: sample_stats))
    svg = doc.at_css("svg")
    assert svg, "Expected an <svg> element"
    assert_includes svg["viewbox"], "0 0"
  end

  def test_renders_correct_number_of_bar_groups
    doc = render_component(BarChartComponent.new(stats: sample_stats))
    bar_groups = doc.css("g.bars > g")
    assert_equal 4, bar_groups.length
  end

  def test_each_bar_has_tooltip
    doc = render_component(BarChartComponent.new(stats: sample_stats))
    tooltips = doc.css("g.tooltips > g")
    assert_equal 4, tooltips.length
    assert_includes tooltips.first.text, "Avg 10"
    assert_includes tooltips.first.text, "Median 12"
  end

  def test_renders_y_axis_grid_labels
    doc = render_component(BarChartComponent.new(stats: sample_stats))
    grid_labels = doc.css('text[data-role="grid-label"]')
    refute_empty grid_labels, "Expected grid labels"
    top_label = grid_labels.first.text.delete(",").to_i
    assert top_label >= 30, "Top grid label (#{top_label}) should be >= max value (30)"
  end

  def test_renders_x_axis_labels
    doc = render_component(BarChartComponent.new(stats: sample_stats))
    x_labels = doc.css("g.bars > g > text")
    assert_equal 4, x_labels.length
    assert_equal "0", x_labels[0].text
    assert_equal "3", x_labels[3].text
  end

  def test_renders_legend
    doc = render_component(BarChartComponent.new(stats: sample_stats))
    legend = doc.css('g[data-role="legend"]')
    refute_empty legend, "Expected a legend group"
  end

  def test_has_aria_label
    doc = render_component(BarChartComponent.new(stats: sample_stats))
    svg = doc.at_css("svg")
    assert svg["aria-label"], "Expected aria-label on SVG"
  end

  def test_has_desc_element
    html = BarChartComponent.new(stats: sample_stats).call
    assert_includes html, "<desc>", "Expected a <desc> element"
  end

  def test_handles_empty_stats
    doc = render_component(BarChartComponent.new(stats: []))
    svg = doc.at_css("svg")
    assert svg, "Should still render SVG even with empty stats"
    bar_groups = doc.css("g.bars > g")
    assert_equal 0, bar_groups.length
  end

  def test_handles_all_zero_values
    zero_stats = [["Mon", 0, 0, 0], ["Tue", 0, 0, 0]]
    doc = render_component(BarChartComponent.new(stats: zero_stats))
    svg = doc.at_css("svg")
    assert svg, "Should render without error when all values are zero"
  end

  def test_handles_single_data_point
    single = [["12pm", 42, 50, 45]]
    doc = render_component(BarChartComponent.new(stats: single))
    bar_groups = doc.css("g.bars > g")
    assert_equal 1, bar_groups.length
  end

  def test_bars_use_correct_colors
    html = BarChartComponent.new(stats: sample_stats).call
    assert_includes html, "#2563eb", "Expected avg color"
    assert_includes html, "#93c5fd", "Expected peak color"
  end

  def test_dark_mode_uses_dark_colors
    html = BarChartComponent.new(stats: sample_stats, dark_mode: true).call
    assert_includes html, "#3b82f6", "Expected dark mode avg color"
    assert_includes html, "#60a5fa", "Expected dark mode peak color"
  end
end
