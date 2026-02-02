class StatsController < ApplicationController
  def index
    avg = {name: "Average listeners", data: {}}
    max = {name: "Maximum listeners", data: {}}
    HourlyListenerStat
        .surf_radio.on("2026-01-01")
        .select(:hour, :avg_listeners, :max_listeners)
        .each do |row|
      hour = "#{row.hour.to_s.rjust(2, "0")}:00h"
      avg[:data][hour] = row.avg_listeners
      max[:data][hour] = row.max_listeners
    end

    @stats = {avg:, max:}
  end
end
