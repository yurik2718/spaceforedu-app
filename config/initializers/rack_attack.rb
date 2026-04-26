class Rack::Attack
  # 5 login attempts per 20 seconds per IP
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/session" && req.post?
  end

  # 10 login attempts per hour per email address
  throttle("logins/email", limit: 10, period: 1.hour) do |req|
    if req.path == "/session" && req.post?
      req.params.dig("email_address").to_s.downcase.strip.presence
    end
  end
end
