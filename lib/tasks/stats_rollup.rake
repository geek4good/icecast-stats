namespace :stats do
  desc "Backfill daily stats from hourly stats"
  task backfill_daily: :environment do
    dates = Stat.hourly
      .select("DATE(\"from\" AT TIME ZONE 'UTC' AT TIME ZONE '#{Time.zone.tzinfo.identifier}')")
      .distinct
      .pluck(Arel.sql("DATE(\"from\" AT TIME ZONE 'UTC' AT TIME ZONE '#{Time.zone.tzinfo.identifier}')"))
      .sort

    puts "Backfilling daily stats for #{dates.size} days..."
    dates.each do |date|
      from = Time.zone.local(date.year, date.month, date.day)
      to = from + 1.day
      stats = StatsCalculator.new(from:, to:).persist_stats
      print stats&.any? ? "." : "s"
    end
    puts "\nDone."
  end

  desc "Backfill monthly stats from daily stats"
  task backfill_monthly: :environment do
    months = Stat.daily
      .select("DATE_TRUNC('month', \"from\" AT TIME ZONE 'UTC' AT TIME ZONE '#{Time.zone.tzinfo.identifier}')")
      .distinct
      .pluck(Arel.sql("DATE_TRUNC('month', \"from\" AT TIME ZONE 'UTC' AT TIME ZONE '#{Time.zone.tzinfo.identifier}')"))
      .sort

    puts "Backfilling monthly stats for #{months.size} months..."
    months.each do |month_start|
      from = Time.zone.local(month_start.year, month_start.month)
      to = from.next_month
      stats = StatsAggregator.new(from:, to:).persist_stats
      print stats&.any? ? "." : "s"
    end
    puts "\nDone."
  end

  desc "Backfill stream outages from snapshots"
  task backfill_outages: :environment do
    first = Snapshot.minimum(:created_at)
    last = Snapshot.maximum(:created_at)

    unless first && last
      puts "No snapshots found."
      next
    end

    puts "Backfilling outages from #{first} to #{last}..."
    current = first.beginning_of_hour
    while current < last
      next_hour = current + 1.hour
      OutageDetector.new(from: current, to: next_hour).detect
      print "."
      current = next_hour
    end
    puts "\nDone."
  end

  desc "Backfill all stats (daily, monthly, outages)"
  task backfill: :environment do
    Rake::Task["stats:backfill_daily"].invoke
    Rake::Task["stats:backfill_monthly"].invoke
    Rake::Task["stats:backfill_outages"].invoke
  end
end
