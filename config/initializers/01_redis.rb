# Redis/Valkey connection configuration
# Connects to Valkey locally and in production via REDIS_URL env var

REDIS = Redis.new(
  url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
  timeout: 1,
  reconnect_attempts: 3
)
