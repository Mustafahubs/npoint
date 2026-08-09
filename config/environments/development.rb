Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Eager load code. Solved problem where the server was hanging after startup
  config.eager_load = true

  # Show full error reports.
  config.consider_all_requests_local = true

  # Disable general caching (Redis used only for Rack::Attack and BandwidthTracker)
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  config.log_level = :debug

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # https://github.com/rspec/rspec-rails/issues/1275
  #
  # HOST/PUBLIC_PORT/PUBLIC_PROTOCOL drive every URL this app generates
  # (api_url, sample_update_url, password-reset links, etc - these use
  # Rails.application.routes.url_helpers directly, not the current request,
  # so they can't infer any of this on their own). They default to sensible
  # values for a bare local `docker compose up` (see docker-compose.yml) but
  # should be set to your real public hostname/port/scheme when exposing
  # this over the internet, e.g. via a Cloudflare Tunnel - see
  # docs/cloudflare-tunnel.md. PUBLIC_PORT/PUBLIC_PROTOCOL are separate from
  # PORT (what Puma actually binds to inside the container) because a
  # reverse proxy/tunnel/Docker port mapping can put a different port and
  # protocol in front of that.
  public_host = ENV['HOST'] || 'localhost'
  public_port = ENV.fetch('PUBLIC_PORT', ENV.fetch('PORT', 3001)).to_i
  public_protocol = ENV.fetch('PUBLIC_PROTOCOL', 'http')

  config.action_controller.default_url_options = {
    host: public_host,
    port: public_port,
    protocol: public_protocol,
  }

  # Subdomain routing (used for the API_SUBDOMAIN.<host> public API - see
  # config/routes.rb) needs to know how many trailing host segments form the
  # "domain" vs. the subdomain. localhost has no real TLD, so 0. A real
  # domain like yourdomain.com, or a single dedicated subdomain of one like
  # npoint.yourdomain.com paired with api-npoint.yourdomain.com, is
  # correctly handled by Rails' own default of 1 - no override needed
  # either way, since in both cases the API host is exactly one label under
  # a 2-label domain. Set TLD_LENGTH explicitly if your domain needs
  # something else (e.g. a co.uk-style domain needs 2).
  config.action_dispatch.tld_length =
    ENV.fetch('TLD_LENGTH', public_host == 'localhost' ? 0 : 1).to_i

  # Rails' Host Authorization middleware only allows .localhost/.test/IP
  # hosts by default in development - a real domain (e.g. behind a
  # Cloudflare Tunnel) would otherwise get a 403 Blocked Host error. Allow
  # HOST itself plus every subdomain of its registrable (last-two-label)
  # domain, so both the main app and the API_SUBDOMAIN.<host> public API
  # work - including when the API host is a *sibling* of HOST rather than a
  # subdomain of it (e.g. HOST=npoint.yourdomain.com with
  # API_SUBDOMAIN=api-npoint, giving api-npoint.yourdomain.com - see
  # docs/cloudflare-tunnel.md). Only handles standard 2-label domains
  # (yourdomain.com); a co.uk-style domain needs its own config.hosts entry
  # added manually.
  if public_host != 'localhost'
    config.hosts << public_host
    registrable_domain = public_host.split('.').last(2).join('.')
    config.hosts << ".#{registrable_domain}"
  end
end

# https://github.com/rspec/rspec-rails/issues/1275
Rails.application.routes.default_url_options[:host] = ENV['HOST'] || 'localhost'
Rails.application.routes.default_url_options[:port] = ENV.fetch('PUBLIC_PORT', ENV.fetch('PORT', 3001)).to_i
Rails.application.routes.default_url_options[:protocol] = ENV.fetch('PUBLIC_PROTOCOL', 'http')
