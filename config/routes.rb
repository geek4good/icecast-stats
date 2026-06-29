Rails.application.routes.draw do
  # Reveal health status on /up — must be before the /:station scope
  # to avoid being caught as station: "up".
  get "up" => "rails/health#show", :as => :rails_health_check

  # Legacy route redirects (before scope to avoid :station capture)
  get "stats/index", to: redirect("/surf-radio/listeners/daily")
  get "stats/weekly", to: redirect("/surf-radio/listeners/weekly")
  get "stats/monthly", to: redirect("/surf-radio/listeners/monthly")
  get "stats/patterns", to: redirect("/surf-radio/listeners/patterns")
  get "songs", to: redirect("/surf-radio/songs/daily"), as: :legacy_songs

  # Root redirects to default station/view/interval
  root "listeners#show", station: "surf-radio", interval: "daily"

  scope "/:station" do
    get "listeners/:interval", to: "listeners#show", as: :listeners
    get "songs/:interval", to: "songs#show", as: :songs

    # Convenience redirects
    get "listeners", to: redirect { |params| "/#{params[:station]}/listeners/daily" }
    get "songs", to: redirect { |params| "/#{params[:station]}/songs/daily" }
    get "", to: redirect { |params| "/#{params[:station]}/listeners/daily" }
  end
end
