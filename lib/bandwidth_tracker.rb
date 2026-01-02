# Redis-backed bandwidth tracking for API requests
class BandwidthTracker
  class << self
    REDIS_KEY_PREFIX = 'bandwidth'.freeze
    RETENTION_PERIOD = 24.hours

    # Track bandwidth for a document token
    def track(token, bytes)
      return unless token.present? && bytes.positive?

      timestamp = Time.current.to_i
      key = redis_key(token)

      # Store as sorted set with timestamp as score
      REDIS.zadd(key, timestamp, "#{timestamp}:#{bytes}")

      # Set expiration to auto-cleanup old data
      REDIS.expire(key, RETENTION_PERIOD.to_i)

      # Periodic cleanup of old entries
      cleanup_old_data(key)
    end

    # Get bandwidth stats for last N hours (default 24)
    def stats(hours: 24)
      cutoff = hours.hours.ago.to_i
      tokens = all_tokens

      results = tokens.map do |token|
        key = redis_key(token)
        entries = REDIS.zrangebyscore(key, cutoff, '+inf')
        next if entries.empty?

        parsed_entries = entries.map do |entry|
          timestamp, bytes = entry.split(':').map(&:to_i)
          { timestamp: Time.at(timestamp), bytes: bytes }
        end

        {
          token: token,
          total_bytes: parsed_entries.sum { |e| e[:bytes] },
          request_count: parsed_entries.size,
          first_seen: parsed_entries.map { |e| e[:timestamp] }.min,
          last_seen: parsed_entries.map { |e| e[:timestamp] }.max
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
      keys = REDIS.keys("#{REDIS_KEY_PREFIX}:*")
      REDIS.del(*keys) if keys.any?
    end

    private

    # Get Redis key for a token
    def redis_key(token)
      "#{REDIS_KEY_PREFIX}:#{token}"
    end

    # Get all tracked tokens
    def all_tokens
      keys = REDIS.keys("#{REDIS_KEY_PREFIX}:*")
      keys.map { |key| key.sub("#{REDIS_KEY_PREFIX}:", '') }
    end

    # Remove entries older than retention period
    def cleanup_old_data(key)
      cutoff = RETENTION_PERIOD.ago.to_i
      REDIS.zremrangebyscore(key, '-inf', cutoff)
    end
  end
end
