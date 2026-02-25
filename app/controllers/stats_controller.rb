class StatsController < ApplicationController
  def index
    @count = Snapshot.count
    # today = Date.today
    # few_days_ago = today - 3.days
    # @stats = few_days_ago.upto(today).inject({}) do |stats, date|
    #   avg = {name: "Average listeners", data: {}}
    #   max = {name: "Maximum listeners", data: {}}
    #   HourlyListenerStat
    #       .surf_radio
    #       .where(date:)
    #       .select(:hour, :avg_listeners, :max_listeners)
    #       .each do |row|
    #     hour = "#{row.hour}:00h"
    #     avg[:data][hour] = row.avg_listeners
    #     max[:data][hour] = row.max_listeners
    #   end
    #   stats.merge!(date.strftime("%d %b %Y") => {avg:, max:})
    # end
  end
end
