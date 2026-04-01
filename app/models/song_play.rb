class SongPlay < ApplicationRecord
  scope :music, -> { where(category: "music") }
  scope :news, -> { where(category: "news") }
  scope :ads, -> { where(category: "ads") }
  scope :for_station, ->(station) { where(station: station) }

  CATEGORY_PATTERNS = {
    "news" => "BBC World News",
    "ads" => "SURF RADIO - www.surf.radio"
  }.freeze

  def self.categorize(title)
    CATEGORY_PATTERNS.each do |category, pattern|
      return category if title == pattern
    end
    "music"
  end

  def self.parse_artist_and_song(title)
    parts = title.split(" - ", 2)
    if parts.length == 2
      {artist: parts[0].strip, song: parts[1].strip}
    else
      {artist: nil, song: nil}
    end
  end
end
