class SongsController < ApplicationController
  def index
    @period = params[:period] || "this_week"
    range = period_range(@period)
    @period_label = period_label(@period)

    plays = SongPlay.for_station("Surf Radio").where(started_at: range)

    @content_breakdown = plays
      .group(:category)
      .sum(:duration_seconds)
      .transform_values { |v| v / 60 }

    @top_songs = plays.music
      .group(:title, :artist)
      .select(
        "title",
        "artist",
        "SUM(duration_seconds) AS total_duration",
        "COUNT(*) AS play_count",
        "ROUND(AVG(duration_seconds))::int AS avg_duration"
      )
      .order("total_duration DESC")
      .limit(25)

    @top_artists = plays.music
      .where.not(artist: nil)
      .group(:artist)
      .select(
        "artist",
        "SUM(duration_seconds) AS total_duration",
        "COUNT(*) AS play_count"
      )
      .order("total_duration DESC")
      .limit(25)

    @top_ads = plays.ads
      .group(:title)
      .select(
        "title",
        "SUM(duration_seconds) AS total_duration",
        "COUNT(*) AS play_count",
        "ROUND(AVG(duration_seconds))::int AS avg_duration"
      )
      .order("total_duration DESC")
      .limit(25)
  end

  private

  def period_range(period)
    case period
    when "this_week"
      Date.current.beginning_of_week(:monday).beginning_of_day..Time.current
    when "this_month"
      Date.current.beginning_of_month.beginning_of_day..Time.current
    when "last_month"
      last = Date.current - 1.month
      last.beginning_of_month.beginning_of_day..last.end_of_month.end_of_day
    when "this_year"
      Date.current.beginning_of_year.beginning_of_day..Time.current
    when "all_time"
      Time.zone.local(2000, 1, 1)..Time.current
    else
      Date.current.beginning_of_week(:monday).beginning_of_day..Time.current
    end
  end

  def period_label(period)
    case period
    when "this_week" then "This Week"
    when "this_month" then "This Month"
    when "last_month" then (Date.current - 1.month).strftime("%B %Y")
    when "this_year" then "This Year"
    when "all_time" then "All Time"
    else "This Week"
    end
  end
end
