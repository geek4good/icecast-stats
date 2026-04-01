# Run in Rails console: load "scripts/backfill_listener_stats.rb"
#
# Generates Stat records for every hour that has snapshots
# but no stats yet. Safe to re-run — skips hours already calculated.

first = Snapshot.minimum(:created_at)
last = Snapshot.maximum(:created_at)

unless first && last
  puts "No snapshots found."
  return
end

hour_start = first.beginning_of_hour
hour_end = last.beginning_of_hour

total = ((hour_end - hour_start) / 1.hour).to_i
processed = 0
created = 0

puts "Backfilling from #{hour_start} to #{hour_end} (#{total} hours)..."

current = hour_start
while current < hour_end
  processed += 1
  results = StatsCalculator.new(from: current, to: current + 1.hour).persist_stats
  created += results&.size || 0

  if processed % 100 == 0
    puts "  #{processed}/#{total} hours processed, #{created} stats created..."
  end

  current += 1.hour
end

puts "Done. #{processed} hours processed, #{created} listener stats created."
