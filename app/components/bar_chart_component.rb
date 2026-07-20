# SVG bar chart component using Phlex.
# Renders a stacked bar chart (average + peak) with Y-axis grid lines,
# X-axis labels, native SVG tooltips, and a legend.
#
# Usage:
#   render BarChartComponent.new(stats: [["0", 10, 25, 12], ["1", 15, 30, 18]])
#
# stats: Array of [label, average, maximum, median]
class BarChartComponent < BaseSvgComponent
  CHART_WIDTH = 800
  CHART_HEIGHT = 350
  PADDING_LEFT = 48
  PADDING_RIGHT = 16
  PADDING_TOP = 36
  PADDING_BOTTOM = 48
  BAR_GAP = 4

  def initialize(stats:, width: CHART_WIDTH, height: CHART_HEIGHT, dark_mode: false, tooltip_labels: nil)
    super(dark_mode: dark_mode)
    @stats = stats
    @width = width
    @height = height
    @tooltip_labels = tooltip_labels
  end

  def view_template
    c = colors

    plot_left = PADDING_LEFT
    plot_right = @width - PADDING_RIGHT
    plot_top = PADDING_TOP
    plot_bottom = @height - PADDING_BOTTOM
    plot_width = plot_right - plot_left
    plot_height = plot_bottom - plot_top

    max_value = @stats.map { |s| s[2] }.max || 0
    grid_lines, = compute_grid(max_value)
    y_max = grid_lines.last || 1

    svg(
      width: @width,
      height: @height,
      viewBox: "0 0 #{@width} #{@height}",
      role: "img",
      "aria-label": "Bar chart showing #{@stats.length} data points",
      xmlns: "http://www.w3.org/2000/svg",
      style: "max-width: 100%; height: auto;"
    ) do
      desc { "Bar chart with #{@stats.length} bars showing average and peak values" }

      # Y-axis grid lines
      grid_lines.reverse_each.with_index do |value, _i|
        y = plot_bottom - (value.to_f / y_max * plot_height)
        line(
          x1: plot_left, y1: y,
          x2: plot_right, y2: y,
          stroke: c[:grid_line], stroke_width: 1
        )
        text(
          x: plot_left - 8, y: y + 4,
          "text-anchor": "end",
          fill: c[:text],
          "font-size": "12",
          "data-role": "grid-label"
        ) { format_number(value) }
      end

      # Zero line
      line(
        x1: plot_left, y1: plot_bottom,
        x2: plot_right, y2: plot_bottom,
        stroke: c[:grid_line], stroke_width: 1
      )

      # Bars
      if @stats.any?
        bar_count = @stats.length
        total_gaps = (bar_count - 1) * BAR_GAP
        bar_width = ((plot_width - total_gaps) / bar_count).floor
        # Clamp bar width for readability
        bar_width = [bar_width, 40].min

        # Center the bars if they don't fill the width
        total_bars_width = bar_count * bar_width + (bar_count - 1) * BAR_GAP
        offset_x = plot_left + (plot_width - total_bars_width) / 2

        # Precompute layout for each bar
        bars = @stats.each_with_index.map do |(label, avg, peak, _median), i|
          x = offset_x + i * (bar_width + BAR_GAP)
          avg_height = (avg.to_f / y_max * plot_height).round(2)
          peak_height = ((peak - avg).to_f / y_max * plot_height).round(2)

          {
            i: i, label: label, avg: avg, peak: peak, x: x,
            avg_height: avg_height, peak_height: peak_height,
            y_avg: plot_bottom - avg_height,
            y_peak: plot_bottom - avg_height - peak_height,
            tooltip_label: @tooltip_labels&.[](i)
          }
        end

        # Tooltips are in a separate group (rendered after bars for correct
        # paint order), so we use :has() selectors to link hover state.
        style do
          bars.each do |b|
            plain(".bars:has(.bar-#{b[:i]}:hover)~.tooltips .tip-#{b[:i]}{opacity:.95} ")
          end
        end

        g(class: "bars") do
          bars.each do |b|
            g(class: "bar-#{b[:i]}") do
              if b[:peak_height] > 0
                rect(
                  x: b[:x], y: b[:y_peak],
                  width: bar_width, height: [b[:peak_height], 0.5].max,
                  fill: c[:peak], rx: 2
                )
              end

              if b[:avg_height] > 0
                rect(
                  x: b[:x], y: b[:y_avg],
                  width: bar_width, height: [b[:avg_height], 0.5].max,
                  fill: c[:avg]
                )
              end

              text(
                x: b[:x] + bar_width / 2, y: plot_bottom + 20,
                "text-anchor": "middle",
                fill: c[:text], "font-size": "11"
              ) { b[:label] }
            end
          end
        end

        # Tooltips (rendered after all bars for correct paint order)
        g(class: "tooltips") do
          bars.each do |b|
            lines = []
            lines << b[:tooltip_label] if b[:tooltip_label]
            lines << "Avg #{b[:avg]} · Peak #{b[:peak]}"

            tooltip_w = [lines.map(&:length).max * 6.5 + 16, 70].max
            tooltip_x = (b[:x] + bar_width / 2 - tooltip_w / 2).to_i
            tooltip_x = tooltip_x.clamp(plot_left, plot_right - tooltip_w)
            tooltip_h = lines.length * 15 + 7
            tooltip_y = b[:y_peak] - tooltip_h - 6

            g(class: "tip-#{b[:i]} bar-tooltip", "pointer-events": "none") do
              rect(
                x: tooltip_x, y: tooltip_y,
                width: tooltip_w, height: tooltip_h,
                fill: c[:text_dark], rx: 4
              )
              lines.each_with_index do |line, li|
                text(
                  x: tooltip_x + tooltip_w / 2, y: tooltip_y + 15 + li * 15,
                  "text-anchor": "middle",
                  fill: c[:bg], "font-size": "11"
                ) { line }
              end
            end
          end
        end
      end

      # Legend
      g("data-role": "legend", transform: "translate(#{plot_left + plot_width / 2 - 80}, #{plot_bottom + 38})") do
        rect(x: 0, y: -8, width: 10, height: 10, fill: c[:avg], rx: 2)
        text(x: 16, y: 0, fill: c[:text], "font-size": "13") { "Average" }

        rect(x: 90, y: -8, width: 10, height: 10, fill: c[:peak], rx: 2)
        text(x: 106, y: 0, fill: c[:text], "font-size": "13") { "Peak" }
      end
    end
  end
end
