# Interval tabs — Tier 3 of navigation.
# Renders interval links (Daily | Weekly | Monthly | Patterns).
# Adapts available intervals based on the current view (Songs omits Patterns).
#
# Usage:
#   render Nav::IntervalTabsComponent.new(
#     station_slug: "surf-radio",
#     current_view: "listeners",
#     current_interval: "daily"
#   )
class Nav::IntervalTabsComponent < BaseHtmlComponent
  INTERVALS = {
    "daily" => "Daily",
    "weekly" => "Weekly",
    "monthly" => "Monthly",
    "patterns" => "Patterns"
  }.freeze

  def initialize(station_slug:, current_view:, current_interval:)
    @station_slug = station_slug
    @current_view = current_view
    @current_interval = current_interval
    @available_intervals = (current_view == "songs") ? INTERVALS.except("patterns") : INTERVALS
  end

  def view_template
    nav(class: "nav-intervals") do
      @available_intervals.each do |slug, name|
        if slug == @current_interval
          span(class: "nav-interval nav-interval--active") { name }
        else
          href = "/#{@station_slug}/#{@current_view}/#{slug}"
          a(href: href, class: "nav-interval") { name }
        end
      end
    end
  end
end
