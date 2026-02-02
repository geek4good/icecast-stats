class Snapshot < ApplicationRecord
  def self.hourly_stats_for(date_string)
    query = <<~SQL.squish
      SELECT date, hour, stream_name, 
             avg_listeners, max_listeners, snapshot_count
      FROM hourly_listener_stats
      WHERE date = ?
      ORDER BY hour, stream_name
    SQL

    ActiveRecord::Base.connection.exec_query(query, "Hourly Stats", [date_string])
  end
end
