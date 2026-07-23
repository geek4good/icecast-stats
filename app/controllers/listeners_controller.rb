class ListenersController < ApplicationController
  include StationScoped

  VALID_INTERVALS = LISTENER_INTERVALS

  def show
    case @interval
    when "daily" then show_daily
    when "weekly" then show_weekly
    when "monthly" then show_monthly
    when "patterns" then show_patterns
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

    day_start = Time.zone.local(@date.year, @date.month, @date.day)
    day_end = day_start + 1.day

    scope = station_scope(Stat).hourly
    stats, tooltip_labels = hourly_stats(scope, day_start, day_end)
    summary = daily_period_summary(scope, day_start, day_end)
    date_label = @date.strftime("%A, %-d %B %Y")

    prev_date = (@date - 1.day).strftime("%Y-%m-%d")
    next_date = ((@date + 1.day) <= Date.current) ? @date.next_day.strftime("%Y-%m-%d") : nil

    date_nav = {
      prev_href: listeners_path(station: @station_slug, interval: "daily", date: prev_date),
      label: "#{date_label} (ICT, UTC+7)",
      next_href: next_date ? listeners_path(station: @station_slug, interval: "daily", date: next_date) : nil
    }

    view = Listeners::ShowView.new(
      station_slug: @station_slug,
      interval: "daily",
      date_nav: date_nav,
      summary: summary
    ) { |v|
      if stats.any?
        v.render ChartCardComponent.new(title: @station_name, subtitle: "Listeners per hour") do
          v.render BarChartComponent.new(stats: stats, tooltip_labels: tooltip_labels)
        end
      else
        v.p { "No stats recorded yet." }
      end
    }
    render view
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

    @week_end = @week_start + 7.days
    week_label = "#{@week_start.strftime("%-d %b")} – #{(@week_end - 1.day).strftime("%-d %b %Y")}"

    week_start_time = Time.zone.local(@week_start.year, @week_start.month, @week_start.day)
    week_end_time = Time.zone.local(@week_end.year, @week_end.month, @week_end.day)

    scope = station_scope(Stat).daily
    stats, tooltip_labels = fetch_daily_stats(scope, week_start_time, week_end_time, @week_start)
    summary = daily_period_summary(scope, week_start_time, week_end_time, in_hours: true)

    next_week_start = @week_start + 1.week
    date_nav = {
      prev_href: listeners_path(station: @station_slug, interval: "weekly", week: (@week_start - 1.week).strftime("%G-W%V")),
      label: "Week of #{week_label} (ICT, UTC+7)",
      next_href: (next_week_start <= Date.current) ? listeners_path(station: @station_slug, interval: "weekly", week: next_week_start.strftime("%G-W%V")) : nil
    }

    view = Listeners::ShowView.new(
      station_slug: @station_slug,
      interval: "weekly",
      date_nav: date_nav,
      summary: summary
    ) { |v|
      if stats.any? { |s| s[1] > 0 }
        v.render ChartCardComponent.new(title: @station_name, subtitle: "Daily averages") do
          v.render BarChartComponent.new(stats: stats, tooltip_labels: tooltip_labels)
        end
      else
        v.p { "No stats recorded for this week." }
      end
    }
    render view
  end

  def show_monthly
    @month_start = parse_month_param || (Date.current - 1.month).beginning_of_month

    @month_end = @month_start.next_month
    month_label = @month_start.strftime("%B %Y")

    month_start_time = Time.zone.local(@month_start.year, @month_start.month, @month_start.day)
    month_end_time = Time.zone.local(@month_end.year, @month_end.month, @month_end.day)

    scope = station_scope(Stat).daily
    stats, tooltip_labels = fetch_daily_stats(scope, month_start_time, month_end_time, @month_start)
    summary = daily_period_summary(scope, month_start_time, month_end_time, in_hours: true)

    date_nav = {
      prev_href: listeners_path(station: @station_slug, interval: "monthly", month: (@month_start - 1.month).strftime("%Y-%m")),
      label: "#{month_label} (ICT, UTC+7)",
      next_href: (@month_end <= Date.current) ? listeners_path(station: @station_slug, interval: "monthly", month: @month_end.strftime("%Y-%m")) : nil
    }

    view = Listeners::ShowView.new(
      station_slug: @station_slug,
      interval: "monthly",
      date_nav: date_nav,
      summary: summary
    ) { |v|
      if stats.any? { |s| s[1] > 0 }
        v.render ChartCardComponent.new(title: @station_name, subtitle: "Daily averages") do
          v.render BarChartComponent.new(stats: stats, tooltip_labels: tooltip_labels)
        end
      else
        v.p { "No stats recorded for this month." }
      end
    }
    render view
  end

  def show_patterns
    @month_start = parse_month_param || (Date.current - 1.month).beginning_of_month

    @month_end = @month_start.next_month
    prev_month = (@month_start - 1.month).strftime("%Y-%m")
    next_month = @month_end.strftime("%Y-%m")
    month_label = @month_start.strftime("%B %Y")

    local_ts = %("from" AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Bangkok')
    from_time = @month_start.to_time(:utc).iso8601
    to_time = @month_end.to_time(:utc).iso8601
    time_filter = Stat.sanitize_sql(["WHERE \"from\" >= :from AND \"from\" < :to AND station = :station", {from: from_time, to: to_time, station: @station_name}])

    # Single query at hour×day granularity — dow_averages and weekend_weekday derived in Ruby
    granularity_raw = Stat.connection.select_all(<<~SQL).to_a
      SELECT
        EXTRACT(DOW FROM #{local_ts}) AS dow,
        EXTRACT(HOUR FROM #{local_ts}) AS hour,
        ROUND(AVG(average))::int AS avg_listeners,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY median))::int AS avg_median,
        ROUND(AVG(maximum))::int AS avg_peak
      FROM stats
      #{time_filter}
      GROUP BY EXTRACT(DOW FROM #{local_ts}), EXTRACT(HOUR FROM #{local_ts})
      ORDER BY dow, hour
    SQL

    # Remap DOW so Monday=0 ... Sunday=6
    granularity_raw.each { |r| r["dow"] = (r["dow"].to_i + 6) % 7 }

    day_names = %w[Mon Tue Wed Thu Fri Sat Sun]

    # Derive heatmap data (hour×dow grid)
    heatmap_data = {}
    granularity_raw.each do |row|
      heatmap_data[[row["dow"].to_i, row["hour"].to_i]] = row["avg_listeners"].to_i
    end

    # Derive day-of-week averages by aggregating hour-level data
    dow_groups = granularity_raw.group_by { |row| row["dow"].to_i }
    dow_averages = dow_groups.sort.map do |dow, rows|
      avg = (rows.sum { |r| r["avg_listeners"].to_i * 1.0 } / rows.size).round
      median = (rows.sum { |r| r["avg_median"].to_i * 1.0 } / rows.size).round
      peak = (rows.sum { |r| r["avg_peak"].to_i * 1.0 } / rows.size).round
      {"dow" => dow, "avg_listeners" => avg, "avg_median" => median, "avg_peak" => peak}
    end

    # Derive weekend vs weekday by splitting the hour-level data
    wkend = granularity_raw.select { |r| [5, 6].include?(r["dow"].to_i) }
    wkday = granularity_raw.select { |r| ![5, 6].include?(r["dow"].to_i) }
    weekend_weekday = [
      ["weekend", wkend],
      ["weekday", wkday]
    ].filter_map do |period, rows|
      next if rows.empty?
      avg = (rows.sum { |r| r["avg_listeners"].to_i * 1.0 } / rows.size).round
      median = (rows.sum { |r| r["avg_median"].to_i * 1.0 } / rows.size).round
      peak = (rows.sum { |r| r["avg_peak"].to_i * 1.0 } / rows.size).round
      {"period" => period, "avg_listeners" => avg, "avg_median" => median, "avg_peak" => peak}
    end
    weekend_weekday.sort_by! { |r| (r["period"] == "weekend") ? 0 : 1 }

    # Build day-of-week chart data
    dow_chart = dow_averages.map do |row|
      [day_names[row["dow"].to_i], row["avg_listeners"].to_i, row["avg_peak"].to_i, row["avg_median"].to_i]
    end

    # Build weekend/weekday cards
    ww_cards = weekend_weekday.map do |row|
      {
        title: row["period"].capitalize,
        stats: {
          "Avg" => row["avg_listeners"].to_s,
          "Median" => row["avg_median"].to_s,
          "Peak" => row["avg_peak"].to_s
        }
      }
    end

    date_nav = {
      prev_href: listeners_path(station: @station_slug, interval: "patterns", month: prev_month),
      label: month_label,
      next_href: (@month_end <= Date.current) ? listeners_path(station: @station_slug, interval: "patterns", month: next_month) : nil
    }

    view = Listeners::ShowView.new(
      station_slug: @station_slug,
      interval: "patterns",
      date_nav: date_nav
    ) { |v|
      if granularity_raw.any? && dow_averages.any?
        v.render ChartCardComponent.new(title: "Day-of-Week Averages", subtitle: "Average listeners by day") do
          v.render BarChartComponent.new(stats: dow_chart, tooltip_labels: dow_averages.map { |row| %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday][row["dow"].to_i] })
        end
      end

      if granularity_raw.any?
        v.render ChartCardComponent.new(title: "Hour × Day Heatmap", subtitle: "Average listeners (darker = more)") do
          v.render HeatmapComponent.new(data: heatmap_data, day_names: day_names)
        end
      end

      if weekend_weekday.any?
        v.render ChartCardComponent.new(title: "Weekend vs Weekday") do
          v.render SummaryCardsComponent.new(cards: ww_cards)
        end
      end

      if granularity_raw.empty?
        v.p { "No stats recorded for #{month_label}." }
      end
    }
    render view
  end

  def hourly_stats(scope, day_start, day_end)
    stats = []
    labels = []
    scope
      .where(from: day_start...day_end)
      .order(:from)
      .each do |stat|
        local = stat.from.in_time_zone
        stats << [local.strftime("%-k"), stat.average || 0, stat.maximum || 0, stat.median || 0]
        labels << local.strftime("%a %-d %b, %-k:00")
      end
    [stats, labels]
  end

  def fetch_daily_stats(scope, period_start, period_end, date_start)
    rows = scope
      .where(from: period_start...period_end)
      .index_by { |s| s.from.in_time_zone.to_date }

    num_days = ((period_end - period_start) / 1.day).to_i
    days = (date_start...(date_start + num_days.days)).to_a

    stats = days.map do |date|
      stat = rows[date]
      if stat
        [date.strftime("%-d"), stat.average, stat.maximum, stat.median]
      else
        [date.strftime("%-d"), 0, 0, 0]
      end
    end
    labels = days.map { |date| date.strftime("%a %-d %b") }
    [stats, labels]
  end

  def daily_period_summary(scope, period_start, period_end, in_hours: false)
    row = scope.where(from: period_start...period_end)
      .pick(
        Arel.sql("COUNT(*)"),
        Arel.sql("COALESCE(ROUND(AVG(average)), 0)"),
        Arel.sql("COALESCE(MAX(maximum), 0)"),
        Arel.sql("COALESCE(ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY median))::int, 0)"),
        Arel.sql("COALESCE(SUM(total_time), 0)")
      )
    return nil if row.nil? || row[0].zero?

    minutes = row[4].to_i
    {avg: row[1].to_i, peak: row[2].to_i, median: row[3].to_i,
     minutes: in_hours ? minutes / 60 : minutes,
     unit: in_hours ? "Hours" : "Minutes"}
  end
end
