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

  # 60 Stripe webhook posts per minute per IP. Stripe retries failures, but a flood
  # from a single source is suspicious — drop it before the controller runs the verifier.
  throttle("stripe/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path == "/stripe/webhooks" && req.post?
  end

  # 30 document uploads per minute per IP — a real student rarely uploads more.
  throttle("uploads/ip", limit: 30, period: 1.minute) do |req|
    req.ip if req.path.match?(%r{\A/homologation_requests/\d+/documents\z}) && req.post?
  end
end
