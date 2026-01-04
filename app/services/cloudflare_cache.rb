require 'net/http'
require 'json'

class CloudflareCache
  CLOUDFLARE_API_URL = "https://api.cloudflare.com/client/v4"

  def self.purge_by_prefix(prefix)
    return unless ENV['CLOUDFLARE_API_TOKEN'].present? && ENV['CLOUDFLARE_ZONE_ID'].present?

    new.purge_by_prefix(prefix)
  end

  def purge_by_prefix(prefix)
    zone_id = ENV['CLOUDFLARE_ZONE_ID']
    api_token = ENV['CLOUDFLARE_API_TOKEN']

    uri = URI("#{CLOUDFLARE_API_URL}/zones/#{zone_id}/purge_cache")
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{api_token}"
    request['Content-Type'] = 'application/json'
    request.body = { prefixes: [prefix] }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    response_data = JSON.parse(response.body)

    if response_data['success']
      Rails.logger.info("CloudFlare cache purged successfully for prefix: #{prefix}")
    else
      Rails.logger.error("CloudFlare cache purge failed for #{prefix}")
      Rails.logger.error("Errors: #{response_data['errors']}")
      Rails.logger.error("Full response: #{response.body}")
    end
  rescue => e
    # Don't fail the request if cache purge fails
    Rails.logger.error("CloudFlare cache purge error for #{prefix}: #{e.message}")
  end
end
