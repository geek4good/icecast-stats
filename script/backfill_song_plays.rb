# Run in Rails console: load "script/backfill_song_plays.rb"
#
# Generates SongPlay records for every day that has snapshots.
# Safe to re-run — skips duplicates.

first = Snapshot.minimum(:created_at)
last = Snapshot.maximum(:created_at)

unless first && last
  puts "No snapshots found."
  return
end

day_start = first.beginning_of_day
day_end = last.beginning_of_day

total = ((day_end - day_start) / 1.day).to_i
processed = 0
created = 0

puts "Backfilling song plays from #{day_start} to #{day_end} (#{total} days)..."

current = day_start
while current < day_end
  processed += 1
  results = SongPlayExtractor.new(from: current, to: current + 1.day).extract
  created += results&.size || 0

  if processed % 10 == 0
    puts "  #{processed}/#{total} days processed, #{created} song plays created..."
  end

  current += 1.day
end

puts "Done. #{processed} days processed, #{created} song plays created."
