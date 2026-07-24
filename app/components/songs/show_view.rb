# Shared shell for all Songs pages.
# Renders the navigation, date navigation, and yields to interval-specific content.
#
# Usage:
#   render Songs::ShowView.new(station_slug: @station_slug, interval: "daily", date_nav: date_nav) do
#     render DataTableComponent.new(headers: [...], rows: [...])
#   end
class Songs::ShowView < BaseHtmlComponent
  def initialize(station_slug:, interval:, date_nav: nil)
    @station_slug = station_slug
    @interval = interval
    @date_nav = date_nav
  end

  def view_template(&)
    div(class: "page-container") do
      # Row 1: View tabs (left) + Station tabs (right)
      div(class: "nav-row") do
        render Nav::ViewTabsComponent.new(
          station_slug: @station_slug,
          current_view: "songs",
          current_interval: @interval
        )
        render Nav::StationTabsComponent.new(
          station_slug: @station_slug,
          current_view: "songs",
          current_interval: @interval
        )
      end

      # Row 2: Interval tabs
      render Nav::IntervalTabsComponent.new(
        station_slug: @station_slug,
        current_view: "songs",
        current_interval: @interval
      )

      # Date navigation
      if @date_nav
        div(class: "chart-meta") do
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
      end

      yield if block_given?
    end
  end
end
