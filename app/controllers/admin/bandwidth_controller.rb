module Admin
  class BandwidthController < ApplicationController
    # Skip CSRF for this admin endpoint
    skip_before_action :verify_authenticity_token

    # Require HTTP Basic Auth (must set ADMIN_USERNAME and ADMIN_PASSWORD env vars)
    before_action :authenticate_admin

    def index
      hours = (params[:hours] || 24).to_i
      limit = (params[:limit] || 20).to_i

      stats = BandwidthTracker.top(limit, hours: hours)

      # Format for display
      formatted_stats = stats.map do |stat|
        {
          token: stat[:token],
          total_mb: (stat[:total_bytes] / 1024.0 / 1024.0).round(2),
          total_bytes: stat[:total_bytes],
          request_count: stat[:request_count],
          avg_bytes_per_request: (stat[:total_bytes] / stat[:request_count].to_f).round(0),
          first_seen: stat[:first_seen].iso8601,
          last_seen: stat[:last_seen].iso8601,
          document_url: "http://localhost:3001/documents/#{stat[:token]}"
        }
      end

      render json: {
        period_hours: hours,
        total_documents: formatted_stats.size,
        stats: formatted_stats,
        total_bandwidth_mb: formatted_stats.sum { |s| s[:total_mb] }.round(2),
        total_requests: formatted_stats.sum { |s| s[:request_count] }
      }
    end

    def clear
      BandwidthTracker.clear!
      render json: { message: 'Bandwidth tracking data cleared' }
    end

    private

    def authenticate_admin
      unless ENV['ADMIN_USERNAME'].present? && ENV['ADMIN_PASSWORD'].present?
        render json: { error: 'Admin endpoint disabled. Set ADMIN_USERNAME and ADMIN_PASSWORD environment variables.' },
               status: :service_unavailable
        return
      end

      authenticate_or_request_with_http_basic('Admin') do |username, password|
        ActiveSupport::SecurityUtils.secure_compare(username, ENV['ADMIN_USERNAME']) &&
          ActiveSupport::SecurityUtils.secure_compare(password, ENV['ADMIN_PASSWORD'])
      end
    end
  end
end
