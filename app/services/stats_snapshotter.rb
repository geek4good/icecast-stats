require "faraday"

class StatsSnapshotter
  def snapshot_stats
    url = ENV["STATS_URL"]
    params = {}
    headers = {"Accept" => "application/json"}
    res = Faraday.get(url, params, headers)

    if res.success?
      Snapshot.create(stats: res.body)
    else
      logger.error(res.body)
    end
  rescue => e
    logger.error(e.to_s)
  end
end
