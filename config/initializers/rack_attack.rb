# frozen_string_literal: true

# Configure Rack::Attack for rate limiting and request throttling
# Documentation: https://github.com/rack/rack-attack

class Rack::Attack
  ### Configure Cache ###

  # Use Rails cache store for tracking request rates
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Throttle Configuration ###

  # Throttle login attempts by IP address
  # Limit: 5 requests per 20 seconds per IP
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email address
  # Limit: 5 requests per 20 seconds per email
  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      # Normalize email to lowercase
      req.params["user"]&.dig("email")&.to_s&.downcase&.presence
    end
  end

  # Throttle registration attempts
  # Limit: 3 registrations per hour per IP
  throttle("registrations/ip", limit: 3, period: 1.hour) do |req|
    if req.path == "/users" && req.post?
      req.ip
    end
  end

  # Throttle password reset requests
  # Limit: 3 requests per hour per IP
  throttle("password_resets/ip", limit: 3, period: 1.hour) do |req|
    if req.path == "/users/password" && req.post?
      req.ip
    end
  end

  # Throttle email confirmation resend requests
  # Limit: 3 requests per hour per IP
  throttle("confirmations/ip", limit: 3, period: 1.hour) do |req|
    if req.path == "/users/confirmation" && req.post?
      req.ip
    end
  end

  # General API/request throttling
  # Limit: 300 requests per 5 minutes per IP
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  ### Custom Throttle Response ###

  # Customize throttle response
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = match_data[:epoch_time]

    headers = {
      "RateLimit-Limit" => match_data[:limit].to_s,
      "RateLimit-Remaining" => "0",
      "RateLimit-Reset" => (now + (match_data[:period] - (now % match_data[:period]))).to_s,
      "Content-Type" => "text/html"
    }

    # Return Korean error message
    [ 429, headers, [ <<~HTML.html_safe
      <!DOCTYPE html>
      <html>
      <head>
        <title>요청 제한 초과</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Helvetica Neue', Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          }
          .container {
            background: white;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.1);
            text-align: center;
            max-width: 500px;
          }
          h1 { color: #dc3545; margin-top: 0; }
          p { color: #6c757d; line-height: 1.6; }
          .retry-after { font-weight: bold; color: #495057; margin-top: 20px; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>⚠️ 요청 제한 초과</h1>
          <p>
            너무 많은 요청이 감지되었습니다.<br>
            보안을 위해 일시적으로 요청이 차단되었습니다.
          </p>
          <p class="retry-after">
            잠시 후 다시 시도해주세요.
          </p>
        </div>
      </body>
      </html>
    HTML
    ] ]
  end

  ### Blocklist & Safelist ###

  # Always allow requests from localhost
  safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1"
  end

  # Block suspicious requests (optional - can be configured later)
  # blocklist("block-ip") do |req|
  #   # Check if IP is in a blocklist (could be stored in database)
  #   # BlockedIp.where(ip: req.ip).exists?
  # end

  ### Logging ###

  # Track throttled requests in logs
  ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
    req = payload[:request]
    if [ :throttle, :blocklist ].include?(req.env["rack.attack.match_type"])
      Rails.logger.warn "[Rack::Attack] #{req.env['rack.attack.match_type']} #{req.ip} #{req.request_method} #{req.fullpath}"
    end
  end
end
