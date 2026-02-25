class ChangeListenerStatsUniqueIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :listener_stats, [:from, :to]
    add_index :listener_stats, [:station, :from, :to], unique: true
  end
end
