class SongPlayExtractionJob < ApplicationJob
  queue_as :default

  def perform(*args)
    to = Time.current.utc.beginning_of_day
    from = to - 1.day
    SongPlayExtractor.new(from: from, to: to).extract
  end
end
