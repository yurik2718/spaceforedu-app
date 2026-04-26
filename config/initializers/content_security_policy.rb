# Be sure to restart your server when you modify this file.

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none
    policy.script_src  :self, :https
    policy.style_src   :self, :https, :unsafe_inline  # Tailwind/DaisyUI requires inline styles
    policy.connect_src :self, :https,
                       "ws://localhost:3000",   # Action Cable in development
                       "wss://localhost:3000"
    policy.frame_ancestors :none  # Clickjacking protection
  end

  # Nonce for importmap inline script tags
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w(script-src)
end
