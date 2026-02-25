namespace :migrate do
  desc "Migrate data from SQLite to PostgreSQL"
  task sqlite_to_postgres: :environment do
    require "sqlite3"

    @total_migrated = 0
    @total_skipped = 0

    migrate_snapshots
    migrate_listener_stats

    puts "\n=== Migration Complete ==="
    puts "Total migrated: #{@total_migrated}"
    puts "Total skipped:  #{@total_skipped}"
  end

  desc "Migrate snapshots from SQLite to PostgreSQL"
  task snapshots: :environment do
    require "sqlite3"
    migrate_snapshots
  end

  desc "Migrate listener_stats from SQLite to PostgreSQL"
  task listener_stats: :environment do
    require "sqlite3"
    migrate_listener_stats
  end

  def migrate_snapshots
    sqlite_path = ENV.fetch("SQLITE_PATH", "storage/production.sqlite3")

    unless File.exist?(sqlite_path)
      puts "SQLite file not found: #{sqlite_path}"
      return
    end

    puts "Migrating snapshots from #{sqlite_path}..."

    sqlite_db = SQLite3::Database.new(sqlite_path, readonly: true)
    sqlite_db.results_as_hash = true

    batch_size = ENV.fetch("BATCH_SIZE", "10_000").to_i
    offset = ENV.fetch("OFFSET", "0").to_i

    total_count = sqlite_db.get_first_value("SELECT COUNT(*) FROM snapshots")
    puts "Total snapshots in SQLite: #{total_count}"

    loop do
      rows = sqlite_db.execute("SELECT stats, created_at, updated_at FROM snapshots ORDER BY id LIMIT ? OFFSET ?", [batch_size, offset])
      break if rows.empty?

      batch_migrated = 0
      batch_skipped = 0

      rows.each do |row|
        stats = row["stats"]
        created_at = row["created_at"]
        updated_at = row["updated_at"]

        if stats.nil? || stats.start_with?("<")
          batch_skipped += 1
          next
        end

        begin
          Snapshot.create!(
            stats: JSON.parse(stats),
            created_at: parse_time(created_at),
            updated_at: parse_time(updated_at)
          )
          batch_migrated += 1
        rescue JSON::ParserError
          batch_skipped += 1
        rescue => e
          puts "Error: #{e.message}"
          batch_skipped += 1
        end
      end

      @total_migrated += batch_migrated
      @total_skipped += batch_skipped
      offset += batch_size

      progress = [offset, total_count].min
      puts "Progress: #{progress}/#{total_count} (#{(progress.to_f / total_count * 100).round(1)}%) - Migrated: #{batch_migrated}, Skipped: #{batch_skipped}"
    end

    sqlite_db.close
    puts "Snapshots migration completed."
  end

  def migrate_listener_stats
    sqlite_path = ENV.fetch("SQLITE_PATH", "storage/production.sqlite3")

    unless File.exist?(sqlite_path)
      puts "SQLite file not found: #{sqlite_path}"
      return
    end

    puts "Migrating listener_stats from #{sqlite_path}..."

    sqlite_db = SQLite3::Database.new(sqlite_path, readonly: true)
    sqlite_db.results_as_hash = true

    rows = sqlite_db.execute("SELECT station, from, to, average, median, maximum, total_time, created_at, updated_at FROM listener_stats")

    batch_migrated = 0
    batch_skipped = 0

    rows.each do |row|
      ListenerStat.create!(
        station: row["station"],
        from: parse_time(row["from"]),
        to: parse_time(row["to"]),
        average: row["average"],
        median: row["median"],
        maximum: row["maximum"],
        total_time: row["total_time"],
        created_at: parse_time(row["created_at"]),
        updated_at: parse_time(row["updated_at"])
      )
      batch_migrated += 1
    rescue => e
      puts "Error: #{e.message}"
      batch_skipped += 1
    end

    @total_migrated += batch_migrated
    @total_skipped += batch_skipped

    sqlite_db.close
    puts "Listener stats migration completed. Migrated: #{batch_migrated}, Skipped: #{batch_skipped}"
  end

  def parse_time(value)
    return nil if value.nil?
    Time.parse(value)
  rescue ArgumentError
    nil
  end
end
