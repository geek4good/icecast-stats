# SVG heatmap component using Phlex.
# Renders a day-of-week × hour grid showing listener intensity.
#
# Usage:
#   render HeatmapComponent.new(data: { [0, 10] => 5, [1, 14] => 20 }, day_names: %w[Sun Mon ...])
#
# data: Hash of { [dow, hour] => value }
# day_names: Array of 7 day name strings
class HeatmapComponent < BaseSvgComponent
  CELL_SIZE = 28
  CELL_GAP = 2
  LABEL_WIDTH = 36
  HEADER_HEIGHT = 20

  def initialize(data:, day_names:, cell_size: CELL_SIZE, dark_mode: false)
    super(dark_mode: dark_mode)
    @data = data
    @day_names = day_names
    @cell_size = cell_size
    @max_value = @data.values.max || 1
  end

  def view_template
    c = colors

    cols = 24
    rows = 7
    step = @cell_size + CELL_GAP

    grid_width = cols * step - CELL_GAP
    grid_height = rows * step - CELL_GAP
    total_width = LABEL_WIDTH + grid_width
    total_height = HEADER_HEIGHT + grid_height

    svg(
      width: total_width,
      height: total_height,
      viewBox: "0 0 #{total_width} #{total_height}",
      role: "img",
      "aria-label": "Heatmap showing listener patterns by day and hour",
      xmlns: "http://www.w3.org/2000/svg",
      style: "max-width: 100%; height: auto;"
    ) do
      desc { "Heatmap with #{rows} rows (days) and #{cols} columns (hours) showing average listeners" }

      # Column headers (hours)
      (0..23).each do |hour|
        x = LABEL_WIDTH + hour * step + @cell_size / 2
        text(
          x: x, y: 12,
          "text-anchor": "middle",
          fill: c[:text],
          "font-size": "10",
          "data-role": "col-label"
        ) { hour.to_s }
      end

      # Rows
      (0..6).each do |dow|
        y = HEADER_HEIGHT + dow * step

        # Day label
        text(
          x: LABEL_WIDTH - 6, y: y + @cell_size / 2 + 4,
          "text-anchor": "end",
          fill: c[:text],
          "font-size": "11",
          "data-role": "row-label"
        ) { @day_names[dow] }

        # Cells
        (0..23).each do |hour|
          cx = LABEL_WIDTH + hour * step
          value = @data[[dow, hour]] || 0
          intensity = (@max_value > 0) ? (value.to_f / @max_value) : 0

          g("data-has-value": (value > 0) ? "true" : nil) do
            title { "#{@day_names[dow]} #{hour}:00 — #{value} avg listeners" } if value > 0

            rect(
              x: cx, y: y,
              width: @cell_size, height: @cell_size,
              fill: intensity_fill(intensity, c),
              rx: 2,
              "data-role": "heatmap-cell"
            )

            if value > 0
              text(
                x: cx + @cell_size / 2, y: y + @cell_size / 2 + 4,
                "text-anchor": "middle",
                fill: (intensity > 0.5) ? "#ffffff" : c[:text_dark],
                "font-size": "9",
                "font-variant-numeric": "tabular-nums"
              ) { value.to_s }
            end
          end
        end
      end
    end
  end

  private

  # Interpolate between transparent and the avg color based on intensity (0..1)
  def intensity_fill(intensity, colors)
    # Parse the avg hex color
    avg_hex = colors[:avg]
    r = avg_hex[1..2].to_i(16)
    g = avg_hex[3..4].to_i(16)
    b = avg_hex[5..6].to_i(16)

    # Interpolate from light (grid_line) to saturated (avg)
    grid_hex = colors[:grid_line]
    gr = grid_hex[1..2].to_i(16)
    gg = grid_hex[3..4].to_i(16)
    gb = grid_hex[5..6].to_i(16)

    final_r = (gr + (r - gr) * intensity).round
    final_g = (gg + (g - gg) * intensity).round
    final_b = (gb + (b - gb) * intensity).round

    "##{final_r.to_s(16).rjust(2, "0")}#{final_g.to_s(16).rjust(2, "0")}#{final_b.to_s(16).rjust(2, "0")}"
  end
end
