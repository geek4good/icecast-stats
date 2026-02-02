class CreateHourlyListenerStatsView < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL
      CREATE VIEW hourly_listener_stats AS
      SELECT 
        date(snapshots.created_at) as date,
        CAST(strftime('%H', snapshots.created_at) AS INTEGER) as hour,
        json_extract(stream_data.value, '$.server_name') as stream_name,
        CAST(ROUND(AVG(json_extract(stream_data.value, '$.listeners'))) AS INTEGER) as avg_listeners,
        MAX(CAST(json_extract(stream_data.value, '$.listeners') AS INTEGER)) as max_listeners,
        COUNT(*) as snapshot_count
      FROM snapshots
      CROSS JOIN json_each(
        json_extract(snapshots.stats, '$.icestats.source')
      ) as stream_data
      WHERE json_valid(snapshots.stats) > 0
      AND json_extract(snapshots.stats, '$.icestats.source[0]') NOT NULL
      GROUP BY date, hour, stream_name
      ORDER BY date, hour, stream_name;
    SQL
  end

  def down
    execute "DROP VIEW IF EXISTS hourly_listener_stats"
  end
end
