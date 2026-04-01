class Stat < ApplicationRecord
  scope :surf_radio, -> { where(station: "Surf Radio") }
  scope :talay_fm, -> { where(station: "Talay FM") }
  scope :hourly, -> { where("\"to\" - \"from\" = interval '1 hour'") }
  scope :daily, -> { where("\"to\" - \"from\" = interval '1 day'") }
  scope :monthly, -> { where("\"to\" - \"from\" > interval '27 days'") }

  def self.on(date)
    from = date.beginning_of_day
    to = from.next_day

    where(from:, to:)
  end
end
