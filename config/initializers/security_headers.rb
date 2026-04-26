Rails.application.config.action_dispatch.default_headers.merge!(
  "Referrer-Policy"   => "strict-origin-when-cross-origin",
  "Permissions-Policy" => "camera=(), microphone=(), geolocation=(), payment=(self), usb=()"
)
