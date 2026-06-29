# Base class for all SVG chart components.
# Provides shared utilities for grid calculation, theming, and SVG structure.
class BaseSvgComponent < Phlex::SVG
  CHART_COLORS = {
    avg: "#2563eb",
    peak: "#93c5fd",
    median: "#a78bfa",
    grid_line: "#e5e5e5",
    text: "#737373",
    text_dark: "#0a0a0a",
    bg: "#ffffff"
  }.freeze

  DARK_CHART_COLORS = {
    avg: "#3b82f6",
    peak: "#60a5fa",
    median: "#a78bfa",
    grid_line: "#262626",
    text: "#a3a3a3",
    text_dark: "#fafafa",
    bg: "#0a0a0a"
  }.freeze

  def initialize(dark_mode: false)
    @dark_mode = dark_mode
  end

  def colors
    @dark_mode ? DARK_CHART_COLORS : CHART_COLORS
  end

  # Compute "nice" grid step values for the Y-axis.
  # Returns [grid_lines, grid_step] where grid_lines is an array of integer values.
  def compute_grid(max_value)
    return [[1], 1] if max_value.nil? || max_value <= 0

    raw_step = max_value / 4.0
    magnitude = 10**Math.log10([raw_step, 1].max).floor
    nice_steps = [1, 2, 2.5, 5, 10].map { |n| n * magnitude }
    grid_step = nice_steps.find { |s| s >= raw_step } || nice_steps.last
    grid_count = (max_value.to_f / grid_step).ceil
    grid_count += 1 if grid_count * grid_step == max_value
    grid_lines = (1..grid_count).map { |i| (i * grid_step).to_i }
    [grid_lines, grid_step]
  end

  # Format a number for display (e.g., 1200 → "1,200")
  def format_number(n)
    return "0" if n.nil?
    n.to_i.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')
  end
end
