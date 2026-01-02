#!/bin/bash

# Test rate limiting on npoint API
# Should hit rate limit at 600 requests per minute per document

TOKEN="${1:-97c09787d7cd21c68763}"
URL="http://api.localhost:3001/${TOKEN}"
MAX_REQUESTS=650

echo "Testing rate limiting..."
echo "URL: $URL"
echo "Sending $MAX_REQUESTS requests rapidly..."
echo ""

success_count=0
rate_limited_count=0
error_count=0

for i in $(seq 1 $MAX_REQUESTS); do
  response=$(curl -s -w "\n%{http_code}" "$URL" 2>/dev/null)
  status_code=$(echo "$response" | tail -n 1)

  if [ "$status_code" = "200" ]; then
    ((success_count++))
  elif [ "$status_code" = "429" ]; then
    ((rate_limited_count++))
    if [ $rate_limited_count -eq 1 ]; then
      echo "🛑 RATE LIMITED at request #$i"
      echo "Response: $(echo "$response" | head -n -1)"
    fi
  else
    ((error_count++))
  fi

  # Show progress every 50 requests
  if [ $((i % 50)) -eq 0 ]; then
    echo "Progress: $i/$MAX_REQUESTS | Success: $success_count | Rate-limited: $rate_limited_count | Errors: $error_count"
  fi
done

echo ""
echo "=== Results ==="
echo "Total requests: $MAX_REQUESTS"
echo "✅ Successful: $success_count"
echo "🛑 Rate limited: $rate_limited_count"
echo "❌ Errors: $error_count"
echo ""

if [ $rate_limited_count -gt 0 ]; then
  echo "✅ Rate limiting is WORKING!"
else
  echo "⚠️  Rate limiting NOT triggered - may not be enabled or limit too high"
fi
