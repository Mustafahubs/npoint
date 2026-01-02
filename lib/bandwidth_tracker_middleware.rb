require_relative 'bandwidth_tracker'

class BandwidthTrackerMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    # Only track API subdomain GET requests
    request = ActionDispatch::Request.new(env)

    is_api = api_request?(request)
    is_get = request.get?

    Rails.logger.info "[BandwidthTracker] Request: host=#{request.host} path=#{request.path} is_api=#{is_api} is_get=#{is_get}"

    if is_api && is_get
      track_bandwidth(env, request)
    else
      @app.call(env)
    end
  end

  private

  def api_request?(request)
    # Check if this is an api.* subdomain request
    request.host =~ /^api\./
  end

  def track_bandwidth(env, request)
    status, headers, body = @app.call(env)

    # Extract document token from path
    token = extract_token(request.path)

    if token
      # Calculate response size
      response_size = calculate_size(body)
      BandwidthTracker.track(token, response_size)
      Rails.logger.info "[BandwidthTracker] Tracked #{response_size} bytes for token #{token}"
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
