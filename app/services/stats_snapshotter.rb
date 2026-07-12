require "net/http"

class StatsSnapshotter
  def snapshot_stats
    res = Net::HTTP.get_response(uri, headers)
    res.value # raises error if request was unsuccessful

    Snapshot.create(stats: JSON.parse(res.body))
  rescue => e
    Rails.logger.error(e.to_s)
  end

  private

  def uri
    @uri ||= URI(Rails.application.credentials.stats_url)
  end

  def
    @headers ||= {"Accept" => "application/json"}
  end
end
