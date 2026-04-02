namespace :snapshots do
  desc "Archive snapshots for a given month (e.g., rake snapshots:archive MONTH=2026-01)"
  task archive: :environment do
    month = parse_month!
    SnapshotArchiver.new(month:).archive
  end

  desc "Restore snapshots for a given month (e.g., rake snapshots:restore MONTH=2026-01)"
  task restore: :environment do
    month = parse_month!
    SnapshotArchiver.new(month:).restore
  end

  def parse_month!
    raw = ENV.fetch("MONTH") { abort "Usage: rake snapshots:archive MONTH=2026-01" }
    Date.strptime(raw, "%Y-%m")
  rescue Date::Error
    abort "Invalid MONTH format '#{raw}'. Expected YYYY-MM (e.g., 2026-01)"
  end
end
