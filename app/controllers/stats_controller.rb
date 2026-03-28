class StatsController < ApplicationController
  def index
    zone = ActiveSupport::TimeZone[cookies[:tz].to_s] || Time.zone
    @date = params[:date] ? Date.parse(params[:date]) : zone.today - 1.day

    day_start = zone.local(@date.year, @date.month, @date.day).utc
    day_end = day_start + 1.day

    @surf_radio_stats = hourly_stats(ListenerStat.surf_radio, day_start, day_end, zone)
    @talay_fm_stats = hourly_stats(ListenerStat.talay_fm, day_start, day_end, zone)
    @date_label = @date.strftime("%A, %-d %B %Y")
  end

  private

  def hourly_stats(scope, day_start, day_end, zone)
    utc_offset = zone.utc_offset
    scope
      .where(from: day_start...day_end)
      .order(:from)
      .map do |stat|
        local_hour = (stat.from + utc_offset).strftime("%-k")
        [local_hour, stat.average || 0, stat.maximum || 0, stat.median || 0]
      end
  end
end
