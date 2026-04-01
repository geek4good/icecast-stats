class CreateSongPlays < ActiveRecord::Migration[8.1]
  def change
    create_table :song_plays do |t|
      t.text :title, null: false
      t.text :artist
      t.text :song
      t.text :category, null: false
      t.text :station, null: false
      t.datetime :started_at, null: false
      t.datetime :ended_at, null: false
      t.integer :duration_seconds, null: false
      t.integer :snapshot_count, null: false
      t.timestamps
    end
    add_index :song_plays, [:station, :started_at]
    add_index :song_plays, [:artist, :station]
    add_index :song_plays, [:title, :station]
    add_index :song_plays, [:category, :station]
  end
end
