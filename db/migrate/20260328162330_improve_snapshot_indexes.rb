class ImproveSnapshotIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    remove_index :snapshots, :stats, using: :gin
    add_index :snapshots, :created_at, algorithm: :concurrently
  end
end
