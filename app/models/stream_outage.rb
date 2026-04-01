class StreamOutage < ApplicationRecord
  scope :for_station, ->(station) { where(station: station) }
  scope :recent, -> { order(detected_at: :desc) }
end
