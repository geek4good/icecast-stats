class CreateStreamOutages < ActiveRecord::Migration[8.1]
  def change
    create_table :stream_outages do |t|
      t.text :station, null: false
      t.datetime :detected_at, null: false
      t.text :previous_stream_start
      t.text :new_stream_start
      t.integer :estimated_downtime_seconds
      t.timestamps
    end
    add_index :stream_outages, [:station, :detected_at]
  end
end
