class CreateSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :snapshots do |t|
      t.jsonb :stats

      t.timestamps
    end

    add_index :snapshots, :stats, using: :gin
  end
end
