# In-memory bandwidth tracking for API requests
class BandwidthTracker
  class << self
    # Store: { token => [{ timestamp: Time, bytes: Integer }, ...] }
    def data
      @data ||= {}
    end

    # Track bandwidth for a document token
    def track(token, bytes)
      return unless token.present? && bytes.positive?

      data[token] ||= []
      data[token] << { timestamp: Time.current, bytes: bytes }

      # Cleanup old data (keep last 24 hours)
      cleanup_old_data
    end

    # Get bandwidth stats for last N hours (default 24)
    def stats(hours: 24)
      cutoff = hours.hours.ago

      results = data.map do |token, entries|
        recent_entries = entries.select { |e| e[:timestamp] > cutoff }
        next if recent_entries.empty?

        {
          token: token,
          total_bytes: recent_entries.sum { |e| e[:bytes] },
          request_count: recent_entries.size,
          first_seen: recent_entries.map { |e| e[:timestamp] }.min,
          last_seen: recent_entries.map { |e| e[:timestamp] }.max
        }
      end.compact

      results.sort_by { |r| -r[:total_bytes] }
    end

    # Get top N bandwidth users
    def top(n = 10, hours: 24)
      stats(hours: hours).take(n)
    end

    # Clear all data
    def clear!
      @data = {}
    end

    private

    # Remove entries older than 24 hours
    def cleanup_old_data
      return if @last_cleanup && @last_cleanup > 1.hour.ago

      cutoff = 24.hours.ago
      data.each do |token, entries|
        data[token] = entries.select { |e| e[:timestamp] > cutoff }
      end

      # Remove tokens with no recent data
      data.delete_if { |_, entries| entries.empty? }

      @last_cleanup = Time.current
    end
  end
end
