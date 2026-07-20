# Shared shell for all Songs pages.
# Renders the navigation (combined station+view row, then interval row),
# page title, and yields to interval-specific content.
#
# Usage:
#   render Songs::ShowView.new(station_slug: @station_slug, interval: "daily", title: "Songs — This Week") do
#     render DataTableComponent.new(headers: [...], rows: [...])
#   end
class Songs::ShowView < BaseHtmlComponent
  def initialize(station_slug:, interval:, title:)
    @station_slug = station_slug
    @interval = interval
    @title = title
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

      h1 { @title }

      yield if block_given?
    end
  end
end
