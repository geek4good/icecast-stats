class HourlyListenerStat < ApplicationRecord
  scope :surf_radio, -> { where(stream_name: "Surf Radio") }
  scope :talay_fm, -> { where(stream_name: "Talay FM") }

  def self.on(date)
    where(date:)
  end
end

