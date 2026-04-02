require "test_helper"

class SnapshotArchiverTest < ActiveSupport::TestCase
  setup do
    @tmpdir = Dir.mktmpdir("snapshot_archiver_test")
    @archive_dir = Pathname.new(@tmpdir)

    @old_month = Time.utc(2025, 10, 1)
    @sample_stats = {"icestats" => {"source" => []}}

    # Create snapshots for October 2025
    @october_snapshots = 3.times.map do |i|
      Snapshot.create!(
        stats: @sample_stats,
        created_at: @old_month + i.days + 1.hour,
        updated_at: @old_month + i.days + 1.hour
      )
    end

    # Create daily stats covering every day of October 2025
    31.times do |i|
      day = @old_month + i.days
      Stat.create!(
        station: "Surf Radio",
        from: day,
        to: day + 1.day,
        average: 50, median: 45, maximum: 100, total_time: 72_000
      )
    end
  end

  teardown do
    FileUtils.rm_rf(@tmpdir)
  end

  test "archive exports snapshots to gzipped JSONL and deletes from DB" do
    archiver = new_archiver(@old_month)

    archiver.archive

    # Snapshots removed from DB
    assert_equal 0, Snapshot.where(id: @october_snapshots.map(&:id)).count

    # File exists with correct line count
    path = @archive_dir.join("2025-10.jsonl.gz")
    assert path.exist?

    lines = read_gzip_lines(path)
    assert_equal 3, lines.size

    # Each line is valid JSON with expected keys
    parsed = JSON.parse(lines.first)
    assert parsed.key?("id")
    assert parsed.key?("stats")
    assert parsed.key?("created_at")
  end

  test "archive skips month with missing daily stats" do
    Stat.daily.where(from: @old_month...@old_month.next_month).limit(5).delete_all

    archiver = new_archiver(@old_month)
    archiver.archive

    # Snapshots should still be in DB
    assert_equal 3, Snapshot.where(id: @october_snapshots.map(&:id)).count

    # No file created
    refute @archive_dir.join("2025-10.jsonl.gz").exist?
  end

  test "archive skips month with no snapshots" do
    archiver = new_archiver(Time.utc(2020, 1, 1))
    archiver.archive

    refute @archive_dir.join("2020-01.jsonl.gz").exist?
  end

  test "archive is idempotent — re-running after archive is a no-op" do
    archiver = new_archiver(@old_month)
    archiver.archive

    path = @archive_dir.join("2025-10.jsonl.gz")
    assert path.exist?

    # Second run — no snapshots remain, should be a no-op
    archiver.archive

    # File still exists with same content
    assert_equal 3, read_gzip_lines(path).size
  end

  test "restore inserts snapshots from archive" do
    october_ids = @october_snapshots.map(&:id)
    archiver = new_archiver(@old_month)
    archiver.archive

    assert_equal 0, Snapshot.where(id: october_ids).count

    archiver.restore

    assert_equal 3, Snapshot.where(id: october_ids).count
  end

  test "restore skips existing records" do
    archiver = new_archiver(@old_month)
    archiver.archive
    archiver.restore

    # Restoring again should not raise or duplicate
    assert_nothing_raised { archiver.restore }
    assert_equal 3, Snapshot.where(id: @october_snapshots.map(&:id)).count
  end

  test "restore with no archive file does nothing" do
    archiver = new_archiver(Time.utc(2020, 1, 1))
    assert_nothing_raised { archiver.restore }
  end

  private

  def new_archiver(month)
    SnapshotArchiver.new(month: month, base_dir: @archive_dir)
  end

  def read_gzip_lines(path)
    lines = []
    Zlib::GzipReader.open(path) { |gz| gz.each_line { |line| lines << line.strip } }
    lines
  end
end
