class SongPlay < ApplicationRecord
  scope :music, -> { where(category: "music") }
  scope :news, -> { where(category: "news") }
  scope :ads, -> { where(category: "ads") }
  scope :for_station, ->(station) { where(station: station) }

  NEWS_TITLES = ["BBC World News", "Local and Regional News"].freeze
  AD_TITLES = ["SURF RADIO - www.surf.radio"].freeze

  def self.categorize(title)
    return "news" if NEWS_TITLES.include?(title)
    return "ads" if AD_TITLES.include?(title)
    return "music" if title.include?(" - ")
    "ads"
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
