require "faraday"

class SnapshotJob < ApplicationJob
  queue_as :default

  def perform(*args)
    url = ENV["STATS_URL"]
    params = {}
    headers = { "Accept" => "application/json" }
    res = Faraday.get(url, params, headers)

    Snapshot.create(stats: res.body)
  rescue => e
    logger.error(e.to_s)
  end
end
