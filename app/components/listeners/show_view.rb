# Shared shell for all Listeners pages.
# Renders the navigation (combined station+view row, then interval row),
# optional date navigation and summary stats (centered), and yields to
# interval-specific content.
#
# Usage:
#   render Listeners::ShowView.new(
#     station_slug: @station_slug,
#     interval: @interval,
#     date_nav: { prev_href: "...", label: "Mon 2 Jun", next_href: "..." },
#     summary: { avg: 12, peak: 30, hours: 168 }
#   ) do
#     render BarChartComponent.new(stats: @stats)
#   end
class Listeners::ShowView < BaseHtmlComponent
  def initialize(station_slug:, interval:, date_nav: nil, summary: nil)
    @station_slug = station_slug
    @interval = interval
    @date_nav = date_nav
    @summary = summary
  end

  def view_template(&)
    div(class: "page-container") do
      # Row 1: View tabs (left) + Station tabs (right)
      div(class: "nav-row") do
        render Nav::ViewTabsComponent.new(
          station_slug: @station_slug,
          current_view: "listeners",
          current_interval: @interval
        )
        render Nav::StationTabsComponent.new(
          station_slug: @station_slug,
          current_view: "listeners",
          current_interval: @interval
        )
      end

      # Row 2: Interval tabs
      render Nav::IntervalTabsComponent.new(
        station_slug: @station_slug,
        current_view: "listeners",
        current_interval: @interval
      )

      # Centered date navigation + summary stats
      if @date_nav || @summary
        div(class: "chart-meta") do
          if @date_nav
            nav(class: "date-nav") do
              if @date_nav[:prev_href]
                a(href: @date_nav[:prev_href], class: "nav-link") { "‹" }
              end
              span(class: "date-label") { @date_nav[:label] }
              if @date_nav[:next_href]
                a(href: @date_nav[:next_href], class: "nav-link") { "›" }
              end
            end
          end

          if @summary
            render SummaryRowComponent.new(summary: @summary)
          end
        end
      end

      yield if block_given?
    end
  end
end
