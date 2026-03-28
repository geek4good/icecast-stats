// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Store browser timezone in a cookie so the server can localize times
const tz = Intl.DateTimeFormat().resolvedOptions().timeZone
if (tz && document.cookie.indexOf("tz=") === -1) {
  document.cookie = `tz=${tz};path=/;max-age=${365 * 24 * 3600};SameSite=Lax`
}
