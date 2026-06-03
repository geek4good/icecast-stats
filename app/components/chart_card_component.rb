# Card wrapper for chart sections.
# Renders a <section class="chart-card"> with optional title and subtitle.
#
# Usage:
#   render ChartCardComponent.new(title: "Surf Radio", subtitle: "Listeners per hour") do
#     render BarChartComponent.new(stats: @stats)
#   end
class ChartCardComponent < BaseHtmlComponent
  def initialize(title: nil, subtitle: nil)
    @title = title
    @subtitle = subtitle
  end

  def view_template(&)
    section(class: "chart-card") do
      if @title || @subtitle
        header(class: "chart-header") do
          h2 { @title } if @title
          p(class: "chart-subtitle") { @subtitle } if @subtitle
        end
      end
      yield if block_given?
    end
  end
end
