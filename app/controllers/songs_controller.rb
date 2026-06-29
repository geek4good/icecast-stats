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
    range = Date.current.beginning_of_day..Time.current
    period_label = "#{Date.current.strftime("%A, %-d %B %Y")} (ICT)"
    load_and_render(range, period_label)
  end

  def show_weekly
    range = Date.current.beginning_of_week(:monday).beginning_of_day..Time.current
    period_label = "Week of #{range.begin.strftime("%-d %b")} – #{Date.current.strftime("%-d %b %Y")}"
    load_and_render(range, period_label)
  end

  def show_monthly
    range = Date.current.beginning_of_month.beginning_of_day..Time.current
    period_label = Date.current.strftime("%B %Y")
    load_and_render(range, period_label)
  end

  def load_and_render(range, period_label)
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
      .order("total_duration DESC")
      .limit(25)

    top_artists = plays.music
      .where.not(artist: nil)
      .group(:artist)
      .select(
        "artist",
        "SUM(duration_seconds) AS total_duration",
        "COUNT(*) AS play_count"
      )
      .order("total_duration DESC")
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
      .order("total_duration DESC")
      .limit(25)

    title = "Songs — #{@station_name} — #{period_label}"

    view = Songs::ShowView.new(station_slug: @station_slug, interval: @interval, title: title) { |v|
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
