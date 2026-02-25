class CreateListenerStats < ActiveRecord::Migration[8.1]
  def change
    create_table :listener_stats do |t|
      t.text :station
      t.datetime :from
      t.datetime :to
      t.integer :average
      t.integer :median
      t.integer :maximum
      t.integer :total_time

      t.timestamps
    end

    add_index :listener_stats, [:station, :from, :to], unique: true
  end
end
