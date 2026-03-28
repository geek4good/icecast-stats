class StatsController < ApplicationController
  def index
    @surf_radio_stats = ListenerStat.surf_radio.where(from: 30.days.ago..).order(:from)
    @talay_fm_stats = ListenerStat.talay_fm.where(from: 30.days.ago..).order(:from)
  end
end
