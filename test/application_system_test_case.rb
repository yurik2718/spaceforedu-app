require "test_helper"
require "capybara/rails"
require "capybara/minitest"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1000 ]

  def sign_in_as(user, password: "password")
    visit new_session_path
    find_field("email_address").set(user.email_address)
    find_field("password").set(password)
    find('input[type="submit"]').click
  end
end
