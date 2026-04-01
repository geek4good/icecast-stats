class RenameListenerStatsToStats < ActiveRecord::Migration[8.1]
  def change
    rename_table :listener_stats, :stats
    add_column :stats, :snapshot_count, :integer
  end
end
