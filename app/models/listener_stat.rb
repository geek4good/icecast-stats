class ListenerStat < ApplicationRecord
  scope :surf_radio, -> { where(station: "Surf Radio") }
  scope :talay_fm, -> { where(station: "Talay FM") }

  def self.on(date)
    from = date.beginning_of_day
    to = from.next_day

    where(from:, to:)
  end
end
