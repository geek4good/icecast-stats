# Shared concern for controllers that are scoped to a single station.
# Validates the station slug from the URL and provides @station_name and @station_slug.
#
# Usage:
#   class ListenersController < ApplicationController
#     include StationScoped
#     # now has @station_slug, @station_name available
#   end
module StationScoped
  extend ActiveSupport::Concern

  STATIONS = {
    "surf-radio" => "Surf Radio",
    "talay-fm" => "Talay FM"
  }.freeze

  INTERVALS = %w[daily weekly monthly patterns].freeze
  LISTENER_INTERVALS = %w[daily weekly monthly patterns].freeze
  SONG_INTERVALS = %w[daily weekly monthly].freeze

  included do
    before_action :set_station
    before_action :set_interval
  end

  private

  def set_station
    slug = params[:station]
    unless STATIONS.key?(slug)
      redirect_to "/#{STATIONS.keys.first}/listeners/daily" and return
    end
    @station_slug = slug
    @station_name = STATIONS[slug]
  end

  def set_interval
    @interval = params[:interval] || "daily"
    valid_intervals = self.class.const_defined?(:VALID_INTERVALS) ? self.class::VALID_INTERVALS : INTERVALS
    unless valid_intervals.include?(@interval)
      @interval = valid_intervals.first
    end
  end

  def station_scope(model)
    case model.name
    when "Stat"
      model.where(station: @station_name)
    when "SongPlay"
      model.for_station(@station_name)
    else
      model.where(station: @station_name)
    end
  end

  # Parse a YYYY-MM month param, returning nil on invalid/out-of-range input.
  # Falls back to the given block when the param is missing or unparseable.
  def parse_month_param(key: :month)
    raw = params[key]
    return nil unless raw.present? && raw.match?(/\A\d{4}-(?:0[1-9]|1[0-2])\z/)

    year, month = raw.split("-").map(&:to_i)
    Date.new(year, month, 1)
  rescue Date::Error, ArgumentError
    nil
  end

end
