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
      Rails.logger.error(res.body)
    end
  rescue => e
    Rails.logger.error(e.to_s)
  end
end
