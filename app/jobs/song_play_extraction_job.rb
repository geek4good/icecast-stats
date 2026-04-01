class SongPlayExtractionJob < ApplicationJob
  queue_as :default

  def perform(*args)
    yesterday = Time.current.utc.beginning_of_day - 1.day
    from = yesterday
    to = yesterday + 1.day
    SongPlayExtractor.new(from: from, to: to).extract
  end
end
