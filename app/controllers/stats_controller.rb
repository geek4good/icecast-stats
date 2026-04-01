class StatsController < ApplicationController
  def index
    @date = params[:date] ? Date.parse(params[:date]) : Date.current - 1.day

    day_start = Time.zone.local(@date.year, @date.month, @date.day)
    day_end = day_start + 1.day

    @surf_radio_stats = hourly_stats(Stat.surf_radio, day_start, day_end)
    @talay_fm_stats = hourly_stats(Stat.talay_fm, day_start, day_end)
    @date_label = @date.strftime("%A, %-d %B %Y")
  end

  def weekly
    if params[:week].present?
      year, week_num = params[:week].split("-W").map(&:to_i)
      @week_start = Date.commercial(year, week_num, 1)
    else
      @week_start = (Date.current - 1.week).beginning_of_week(:monday)
    end

    @week_end = @week_start + 7.days
    @week_label = "#{@week_start.strftime("%-d %b")} – #{(@week_end - 1.day).strftime("%-d %b %Y")}"

    week_start_time = Time.zone.local(@week_start.year, @week_start.month, @week_start.day)
    week_end_time = Time.zone.local(@week_end.year, @week_end.month, @week_end.day)

    @surf_radio_stats = daily_stats(Stat.surf_radio, week_start_time, week_end_time, @week_start)
    @talay_fm_stats = daily_stats(Stat.talay_fm, week_start_time, week_end_time, @week_start)

    @surf_radio_summary = period_summary(Stat.surf_radio, week_start_time, week_end_time)
    @talay_fm_summary = period_summary(Stat.talay_fm, week_start_time, week_end_time)
  end

  def monthly
    if params[:month].present?
      year, month = params[:month].split("-").map(&:to_i)
      @month_start = Date.new(year, month, 1)
    else
      @month_start = (Date.current - 1.month).beginning_of_month
    end

    @month_end = @month_start.next_month
    @month_label = @month_start.strftime("%B %Y")

    month_start_time = Time.zone.local(@month_start.year, @month_start.month, @month_start.day)
    month_end_time = Time.zone.local(@month_end.year, @month_end.month, @month_end.day)

    @surf_radio_stats = daily_stats(Stat.surf_radio, month_start_time, month_end_time, @month_start)
    @talay_fm_stats = daily_stats(Stat.talay_fm, month_start_time, month_end_time, @month_start)

    @surf_radio_summary = period_summary(Stat.surf_radio, month_start_time, month_end_time)
    @talay_fm_summary = period_summary(Stat.talay_fm, month_start_time, month_end_time)
  end

  def patterns
    if params[:month].present?
      year, month = params[:month].split("-").map(&:to_i)
      @month_start = Date.new(year, month, 1)
    else
      @month_start = (Date.current - 1.month).beginning_of_month
    end

    @month_end = @month_start.next_month
    @prev_month = (@month_start - 1.month).strftime("%Y-%m")
    @next_month = @month_end.strftime("%Y-%m")
    @month_label = @month_start.strftime("%B %Y")

    local_ts = %("from" AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Bangkok')
    from_time = @month_start.to_time(:utc).iso8601
    to_time = @month_end.to_time(:utc).iso8601
    time_filter = Stat.sanitize_sql(["WHERE \"from\" >= :from AND \"from\" < :to", { from: from_time, to: to_time }])

    @dow_averages = Stat.connection.select_all(<<~SQL).to_a
      SELECT
        station,
        EXTRACT(DOW FROM #{local_ts}) AS dow,
        ROUND(AVG(average))::int AS avg_listeners,
        ROUND(AVG(maximum))::int AS avg_peak
      FROM stats
      #{time_filter}
      GROUP BY station, EXTRACT(DOW FROM #{local_ts})
      ORDER BY station, dow
    SQL

    @heatmap = Stat.connection.select_all(<<~SQL).to_a
      SELECT
        station,
        EXTRACT(DOW FROM #{local_ts}) AS dow,
        EXTRACT(HOUR FROM #{local_ts}) AS hour,
        ROUND(AVG(average))::int AS avg_listeners
      FROM stats
      #{time_filter}
      GROUP BY station, EXTRACT(DOW FROM #{local_ts}), EXTRACT(HOUR FROM #{local_ts})
      ORDER BY station, dow, hour
    SQL

    @weekend_weekday = Stat.connection.select_all(<<~SQL).to_a
      SELECT
        station,
        CASE WHEN EXTRACT(DOW FROM #{local_ts}) IN (0, 6) THEN 'weekend' ELSE 'weekday' END AS period,
        ROUND(AVG(average))::int AS avg_listeners,
        ROUND(AVG(maximum))::int AS avg_peak
      FROM stats
      #{time_filter}
      GROUP BY station, period
      ORDER BY station, period DESC
    SQL

    @station_comparison = Stat.connection.select_all(<<~SQL).to_a
      SELECT
        station,
        EXTRACT(DOW FROM #{local_ts}) AS dow,
        ROUND(AVG(average))::int AS avg_listeners
      FROM stats
      #{time_filter}
      GROUP BY station, EXTRACT(DOW FROM #{local_ts})
      ORDER BY station, dow
    SQL

    @stations = (@dow_averages.map { |r| r["station"] } | @heatmap.map { |r| r["station"] }).uniq.sort
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

  def daily_stats(scope, period_start, period_end, date_start)
    rows = scope
      .where(from: period_start...period_end)
      .group_by { |s| s.from.in_time_zone.to_date }

    days = (date_start...(date_start + ((period_end - period_start) / 1.day).to_i.days)).to_a

    days.map do |date|
      day_stats = rows[date] || []
      if day_stats.any?
        avg = (day_stats.sum(&:average) / day_stats.size.to_f).round
        peak = day_stats.map(&:maximum).max
        median = (day_stats.sum(&:median) / day_stats.size.to_f).round
        [date.strftime("%-d"), avg, peak, median]
      else
        [date.strftime("%-d"), 0, 0, 0]
      end
    end
  end

  def period_summary(scope, period_start, period_end)
    stats = scope.where(from: period_start...period_end)
    return nil if stats.empty?

    {
      avg: (stats.average(:average) || 0).round,
      peak: stats.maximum(:maximum) || 0,
      median: (stats.average(:median) || 0).round,
      hours: stats.count
    }
  end
end
