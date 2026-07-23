# Renders a summary row with Avg, Peak, and listening time stats.
# Used below bar charts in daily, weekly, and monthly views.
#
# Usage:
#   render SummaryRowComponent.new(summary: { avg: 12, peak: 30, minutes: 168, unit: "Minutes" })
class SummaryRowComponent < BaseHtmlComponent
  def initialize(summary:)
    @summary = summary
  end

  def view_template
    div(class: "summary-row") do
      span {
        strong { fmt(@summary[:avg]) }
        plain " Avg"
      }
      span {
        strong { fmt(@summary[:median]) }
        plain " Median"
      }
      span {
        strong { fmt(@summary[:peak]) }
        plain " Peak"
      }
      span {
        strong { fmt(@summary[:minutes]) }
        plain " #{@summary[:unit]}"
      }
    end
  end

  private

  def fmt(n)
    n.to_i.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')
  end
end
