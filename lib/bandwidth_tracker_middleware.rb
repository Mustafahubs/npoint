require_relative 'bandwidth_tracker'

class BandwidthTrackerMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    # Only track API subdomain GET requests
    request = ActionDispatch::Request.new(env)

    if api_request?(request) && request.get?
      track_bandwidth(env, request)
    else
      @app.call(env)
    end
  end

  private

  def api_request?(request)
    # Check if this is an API-subdomain request. See API_SUBDOMAIN in
    # config/routes.rb - defaults to "api" (api.<host>) but may be
    # something like "api-npoint" (api-npoint.<host>) on deployments where
    # a two-level subdomain isn't usable (e.g. Cloudflare's free-plan
    # certificate coverage - see docs/cloudflare-tunnel.md).
    request.host.downcase.start_with?("#{ENV.fetch('API_SUBDOMAIN', 'api')}.")
  end

  def track_bandwidth(env, request)
    status, headers, body = @app.call(env)

    # Extract document token from path
    token = extract_token(request.path)

    if token
      # Calculate response size
      response_size = calculate_size(body)
      BandwidthTracker.track(token, response_size)
    end

    [status, headers, body]
  end

  def extract_token(path)
    # Match 20-character alphanumeric tokens
    path.match(/\/([A-Za-z0-9]{20})/)&.[](1)
  end

  def calculate_size(body)
    size = 0
    body.each { |chunk| size += chunk.bytesize }
    size
  end
end
