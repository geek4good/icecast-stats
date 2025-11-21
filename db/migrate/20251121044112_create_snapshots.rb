class CreateSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :snapshots do |t|
      t.text :stats

      t.timestamps
    end
  end
end
