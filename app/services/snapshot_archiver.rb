class SnapshotArchiver
  attr_reader :month, :base_dir

  def initialize(month:, base_dir: nil)
    @month = month.in_time_zone.beginning_of_month
    @base_dir = base_dir || Rails.root.join("storage/snapshots")
  end

  def archive
    scope = snapshots_for_month

    if scope.none?
      log "No snapshots found for #{month_label}"
      return
    end

    db_count = scope.count

    if already_archived?(db_count)
      log "#{month_label} already archived (#{db_count} snapshots)"
      return
    end

    unless daily_stats_complete?
      log "Skipping #{month_label}: daily stats incomplete"
      return
    end

    export(scope)

    unless verified?(db_count)
      log "Skipping #{month_label}: export verification failed"
      return
    end

    delete(scope)
    log "Archived #{month_label}: #{db_count} snapshots"
  end

  def restore
    unless File.exist?(archive_path)
      log "No archive found for #{month_label}"
      return
    end

    count = 0
    Zlib::GzipReader.open(archive_path) do |gz|
      gz.each_line do |line|
        attrs = JSON.parse(line)
        next if Snapshot.exists?(attrs["id"])

        Snapshot.insert(
          {id: attrs["id"], stats: attrs["stats"], created_at: attrs["created_at"], updated_at: attrs["created_at"]},
          record_timestamps: false
        )
        count += 1
      end
    end

    log "Restored #{count} snapshots for #{month_label}"
  end

  private

  def month_end
    month.next_month
  end

  def snapshots_for_month
    Snapshot.where(created_at: month...month_end)
  end

  def daily_stats_complete?
    expected_days = (month.to_date...month_end.to_date).count
    actual_days = Stat.daily
      .where(from: month...month_end)
      .select(:from).distinct.count
    actual_days >= expected_days
  end

  def already_archived?(db_count)
    File.exist?(archive_path) && line_count == db_count
  end

  def export(scope)
    FileUtils.mkdir_p(archive_dir)

    Zlib::GzipWriter.open(archive_path) do |gz|
      scope.find_each(order: :asc) do |snapshot|
        gz.puts({
          id: snapshot.id,
          stats: snapshot.stats,
          created_at: snapshot.created_at.utc.iso8601
        }.to_json)
      end
    end
  end

  def verified?(expected_count)
    line_count == expected_count
  end

  def delete(scope)
    scope.in_batches(of: 10_000).delete_all
  end

  def line_count
    return 0 unless File.exist?(archive_path)

    count = 0
    Zlib::GzipReader.open(archive_path) { |gz| gz.each_line { count += 1 } }
    count
  end

  def archive_path
    archive_dir.join("#{month_label}.jsonl.gz")
  end

  def archive_dir
    base_dir
  end

  def month_label
    month.strftime("%Y-%m")
  end

  def log(message)
    Rails.logger.info("[SnapshotArchiver] #{message}")
  end
end
