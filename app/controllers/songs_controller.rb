class SongsController < ApplicationController
  include StationScoped

  VALID_INTERVALS = SONG_INTERVALS

  AD_TITLES = SongPlay::AD_TITLES

  def show
    case @interval
    when "daily" then show_daily
    when "weekly" then show_weekly
    when "monthly" then show_monthly
    else show_daily
    end
  end

  private

  def show_daily
    @date = begin
      params[:date] ? Date.parse(params[:date]) : Date.current - 1.day
    rescue Date::Error
      Date.current - 1.day
    end
    @date = Date.current - 1.day if @date >= Date.current

    day_start = Time.zone.local(@date.year, @date.month, @date.day)
    day_end = day_start + 1.day
    range = day_start..day_end

    prev_date = (@date - 1.day).strftime("%Y-%m-%d")
    next_date = ((@date + 1.day) < Date.current) ? (@date + 1.day).strftime("%Y-%m-%d") : nil

    date_nav = {
      prev_href: songs_path(station: @station_slug, interval: "daily", date: prev_date),
      label: "#{@date.strftime("%A, %-d %B %Y")} (ICT, UTC+7)",
      next_href: next_date ? songs_path(station: @station_slug, interval: "daily", date: next_date) : nil
    }

    load_and_render(range, date_nav)
  end

  def show_weekly
    @week_start = begin
      if params[:week].present? && params[:week].match?(/\A\d{4}-W(?:0[1-9]|[1-4]\d|5[0-3])\z/)
        year, week_num = params[:week].split("-W").map(&:to_i)
        Date.commercial(year, week_num, 1)
      end
    rescue Date::Error
      nil
    end
    @week_start ||= (Date.current - 1.week).beginning_of_week(:monday)
    @week_start = (Date.current - 1.week).beginning_of_week(:monday) if @week_start >= Date.current.beginning_of_week(:monday)
    @week_end = @week_start + 7.days

    week_start_time = Time.zone.local(@week_start.year, @week_start.month, @week_start.day)
    week_end_time = Time.zone.local(@week_end.year, @week_end.month, @week_end.day)
    range = week_start_time..week_end_time

    week_label = "#{@week_start.strftime("%-d %b")} – #{(@week_end - 1.day).strftime("%-d %b %Y")}"

    next_week_start = @week_start + 1.week
    date_nav = {
      prev_href: songs_path(station: @station_slug, interval: "weekly", week: (@week_start - 1.week).strftime("%G-W%V")),
      label: "Week of #{week_label} (ICT, UTC+7)",
      next_href: (next_week_start < Date.current.beginning_of_week(:monday)) ? songs_path(station: @station_slug, interval: "weekly", week: next_week_start.strftime("%G-W%V")) : nil
    }

    load_and_render(range, date_nav)
  end

  def show_monthly
    @month_start = parse_month_param || (Date.current - 1.month).beginning_of_month
    @month_start = (Date.current - 1.month).beginning_of_month if @month_start >= Date.current.beginning_of_month
    @month_end = @month_start.next_month

    month_start_time = Time.zone.local(@month_start.year, @month_start.month, @month_start.day)
    month_end_time = Time.zone.local(@month_end.year, @month_end.month, @month_end.day)
    range = month_start_time..month_end_time

    month_label = @month_start.strftime("%B %Y")

    date_nav = {
      prev_href: songs_path(station: @station_slug, interval: "monthly", month: (@month_start - 1.month).strftime("%Y-%m")),
      label: "#{month_label} (ICT, UTC+7)",
      next_href: (@month_end < Date.current.beginning_of_month) ? songs_path(station: @station_slug, interval: "monthly", month: @month_end.strftime("%Y-%m")) : nil
    }

    load_and_render(range, date_nav)
  end

  def load_and_render(range, date_nav)
    plays = SongPlay.for_station(@station_name).where(started_at: range)

    content_breakdown = plays
      .group(:category)
      .sum(:duration_seconds)
      .transform_values { |v| v / 60 }

    top_songs = plays.music
      .group(:title, :artist)
      .select(
        "title",
        "artist",
        "SUM(duration_seconds) AS total_duration",
        "COUNT(*) AS play_count",
        "ROUND(AVG(duration_seconds))::int AS avg_duration"
      )
      .order("play_count DESC, total_duration DESC")
      .limit(25)

    top_artists = plays.music
      .where.not(artist: nil)
      .group(:artist)
      .select(
        "artist",
        "SUM(duration_seconds) AS total_duration",
        "COUNT(*) AS play_count"
      )
      .order("play_count DESC, total_duration DESC")
      .limit(25)

    top_ads = plays.ads
      .where.not(title: AD_TITLES)
      .group(:title)
      .select(
        "title",
        "SUM(duration_seconds) AS total_duration",
        "COUNT(*) AS play_count",
        "ROUND(AVG(duration_seconds))::int AS avg_duration"
      )
      .order("play_count DESC, total_duration DESC")
      .limit(25)

    view = Songs::ShowView.new(station_slug: @station_slug, interval: @interval, date_nav: date_nav) { |v|
      if content_breakdown.any?
        cards = content_breakdown.map { |category, minutes|
          {title: category.capitalize, stats: {"" => "#{minutes.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')} min"}}
        }
        v.render ChartCardComponent.new(title: "Content Breakdown", subtitle: "Minutes by category") do
          v.render SummaryCardsComponent.new(cards: cards)
        end
      end

      if top_songs.any?
        rows = top_songs.each_with_index.map { |song, i|
          [i + 1, song.title, song.artist || "–",
            format_duration(song.total_duration.to_i),
            song.play_count,
            format_duration(song.avg_duration)]
        }
        v.render ChartCardComponent.new(title: "Most Played Songs") do
          v.render DataTableComponent.new(
            headers: ["#", "Title", "Artist", "Total Time", "Plays", "Avg Duration"],
            rows: rows
          )
        end
      end

      if top_artists.any?
        rows = top_artists.each_with_index.map { |artist, i|
          [i + 1, artist.artist,
            format_duration(artist.total_duration.to_i),
            artist.play_count]
        }
        v.render ChartCardComponent.new(title: "Top Artists") do
          v.render DataTableComponent.new(
            headers: ["#", "Artist", "Total Time", "Songs Played"],
            rows: rows
          )
        end
      end

      if top_ads.any?
        rows = top_ads.each_with_index.map { |ad, i|
          [i + 1, ad.title,
            format_duration(ad.total_duration.to_i),
            ad.play_count,
            format_duration(ad.avg_duration)]
        }
        v.render ChartCardComponent.new(title: "Most Played Ads") do
          v.render DataTableComponent.new(
            headers: ["#", "Title", "Total Time", "Plays", "Avg Duration"],
            rows: rows
          )
        end
      end

      if content_breakdown.empty? && top_songs.empty?
        v.p { "No song data recorded for this period." }
      end
    }
    render view
  end

  def format_duration(seconds)
    "#{seconds / 60}m #{seconds % 60}s"
  end
end
