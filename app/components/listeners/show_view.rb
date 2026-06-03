# Shared shell for all Listeners pages.
# Renders the navigation (combined station+view row, then interval row),
# optional date navigation, page title, and yields to interval-specific content.
#
# Usage:
#   render Listeners::ShowView.new(
#     station_slug: @station_slug,
#     interval: @interval,
#     title: "Surf Radio",
#     date_nav: { prev_href: "...", label: "Mon 2 Jun", next_href: "..." }
#   ) do
#     render BarChartComponent.new(stats: @stats)
#   end
class Listeners::ShowView < BaseHtmlComponent
  def initialize(station_slug:, interval:, title:, date_nav: nil)
    @station_slug = station_slug
    @interval = interval
    @title = title
    @date_nav = date_nav
  end

  def view_template(&)
    # Row 1: Station tabs (left) + View tabs (right)
    div(class: "nav-row") do
      render Nav::StationTabsComponent.new(
        station_slug: @station_slug,
        current_view: "listeners",
        current_interval: @interval
      )
      render Nav::ViewTabsComponent.new(
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

    # Optional date navigation (prev/next day, week, month)
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

    h1 { @title }

    yield if block_given?
  end
end
