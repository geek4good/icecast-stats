# Seeds development database with 2 months of realistic-looking stats data.
# Dates are relative to the current date, so the dashboard always shows
# "current month" and "previous month" with data.
#
# Run with: bin/rails db:seed (or db:setup)

return unless Rails.env.development?

STATIONS = ["Surf Radio", "Talay FM"].freeze
START_DATE = 2.months.ago.to_date
DAYS = (Date.current - START_DATE).to_i + 1

# ── Stats: hourly, daily, and monthly intervals ──────────────
# The stats table uses interval-based scopes to distinguish granularity:
#   Stat.hourly  => "to" - "from" = 1 hour
#   Stat.daily   => "to" - "from" = 1 day
#   Stat.monthly => "to" - "from" > 27 days

puts "Seeding #{DAYS} days of stats for #{STATIONS.size} stations..."

DAYS.times do |day_offset|
  date = START_DATE + day_offset
  weekday = date.wday

  STATIONS.each do |station|
    base_listeners = (station == "Surf Radio") ? 25 : 15
    weekend_boost = [0, 6].include?(weekday) ? 5 : 0

    # Hourly stats — 24 per day per station
    # Simulate a daily curve: low overnight, rising through the day,
    # peaking in the evening.
    24.times do |hour|
      hour_curve = case hour
      when 0..5 then 0.3 # Late night
      when 6..9 then 0.6 # Morning ramp-up
      when 10..14 then 0.9 # Midday
      when 15..18 then 1.0 # Afternoon peak
      when 19..22 then 0.8 # Evening
      else 0.4 # Late evening
      end

      listeners = (base_listeners * hour_curve + weekend_boost + rand(-3..3)).round
      listeners = [listeners, 1].max

      from = Time.current.change(day: date.day, hour: hour, min: 0, sec: 0)
      to = from + 1.hour

      Stat.find_or_create_by!(station: station, from: from, to: to) do |s|
        s.average = listeners
        s.median = [listeners - rand(0..3), 1].max
        s.maximum = listeners + rand(3..10)
        s.snapshot_count = rand(500..720) # ~5s intervals in an hour
        s.total_time = 3600
      end
    end

    # Daily stats — 1 per day per station
    daily_from = date.beginning_of_day
    daily_to = daily_from + 1.day

    Stat.find_or_create_by!(station: station, from: daily_from, to: daily_to) do |s|
      daily_avg = (base_listeners * 0.75 + weekend_boost).round
      s.average = daily_avg
      s.median = daily_avg - rand(0..3)
      s.maximum = (base_listeners * 1.4 + weekend_boost).round
      s.snapshot_count = rand(14000..17000)
      s.total_time = 86400
    end
  end
end

# Monthly stats — aggregates for the full previous month
previous_month = 1.month.ago.beginning_of_month
STATIONS.each do |station|
  base_listeners = (station == "Surf Radio") ? 25 : 15
  Stat.find_or_create_by!(station: station, from: previous_month, to: previous_month.next_month) do |s|
    s.average = base_listeners
    s.median = base_listeners - 2
    s.maximum = (base_listeners * 1.5).round
    s.snapshot_count = rand(500_000..520_000)
    s.total_time = previous_month.next_month - previous_month
  end
end

puts "Created #{Stat.count} stat records."

# ── Song plays ───────────────────────────────────────────────
# Generate realistic song plays across the same period.

ARTISTS = [
  ["Khruangbin", "Mr. White"],
  ["Mac DeMarco", "Salad Days"],
  ["Tame Impala", "The Less I Know The Better"],
  ["Beach House", "Space Song"],
  ["Cigarettes After Sex", "Apocalypse"],
  ["Real Estate", "It's Real"],
  ["Men I Trust", "Show Me How"],
  ["Homeshake", "Give Me a Kiss"],
  ["Glass Beams", "Heatwave"],
  ["Crumb", "Locket"]
].freeze

AD_TITLES = ["SURF RADIO - www.surf.radio"].freeze
NEWS_TITLES = ["BBC World News", "Local and Regional News"].freeze

puts "Seeding song plays..."

DAYS.times do |day_offset|
  date = START_DATE + day_offset

  STATIONS.each do |station|
    # ~8-15 songs per day per station, interspersed with ads and news
    play_time = date.beginning_of_day + rand(6..23).hours

    rand(8..15).times do
      artist, song = ARTISTS.sample
      duration = rand(180..300) # 3-5 minutes

      SongPlay.create!(
        title: "#{artist} - #{song}",
        artist: artist,
        song: song,
        category: "music",
        station: station,
        started_at: play_time,
        ended_at: play_time + duration,
        duration_seconds: duration,
        snapshot_count: duration / 5 # ~5s snapshot interval
      )

      play_time += duration

      # Occasionally insert an ad or news break
      if rand < 0.3
        ad_title = AD_TITLES.sample
        ad_duration = rand(30..60)
        SongPlay.create!(
          title: ad_title,
          artist: nil,
          song: nil,
          category: "ads",
          station: station,
          started_at: play_time,
          ended_at: play_time + ad_duration,
          duration_seconds: ad_duration,
          snapshot_count: ad_duration / 5
        )
        play_time += ad_duration
      end

      if play_time.hour.between?(7, 9) && rand < 0.2
        news_title = NEWS_TITLES.sample
        news_duration = rand(180..300)
        SongPlay.create!(
          title: news_title,
          artist: nil,
          song: nil,
          category: "news",
          station: station,
          started_at: play_time,
          ended_at: play_time + news_duration,
          duration_seconds: news_duration,
          snapshot_count: news_duration / 5
        )
        play_time += news_duration
      end
    end
  end
end

puts "Created #{SongPlay.count} song play records."

# ── Stream outages ───────────────────────────────────────────
# A handful of outages spread across the period.

puts "Seeding stream outages..."

OUTAGE_COUNT = 5
OUTAGE_COUNT.times do
  station = STATIONS.sample
  detected_at = START_DATE.beginning_of_day + rand(0..(DAYS * 24)).hours
  StreamOutage.create!(
    station: station,
    detected_at: detected_at,
    estimated_downtime_seconds: rand(60..1800),
    previous_stream_start: "http://stream.example.com/#{station.downcase.parameterize}-128.mp3",
    new_stream_start: "http://stream.example.com/#{station.downcase.parameterize}-128.mp3"
  )
end

puts "Created #{StreamOutage.count} outage records."
puts
puts "Done! Start the server with: bin/dev"
