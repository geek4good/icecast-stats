class StatsController < ApplicationController
  def index
    @count = Snapshot.count
  end
end
