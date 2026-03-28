class StatsController < ApplicationController
  def index
    @date = params[:date] ? Date.parse(params[:date]) : Date.current - 1.day

    day_start = Time.zone.local(@date.year, @date.month, @date.day)
    day_end = day_start + 1.day

    @surf_radio_stats = hourly_stats(ListenerStat.surf_radio, day_start, day_end)
    @talay_fm_stats = hourly_stats(ListenerStat.talay_fm, day_start, day_end)
    @date_label = @date.strftime("%A, %-d %B %Y")
  end

  private

  def hourly_stats(scope, day_start, day_end)
    scope
      .where(from: day_start...day_end)
      .order(:from)
      .map do |stat|
        local_hour = stat.from.in_time_zone.strftime("%-k")
        [local_hour, stat.average || 0, stat.maximum || 0, stat.median || 0]
      end
  end
end
