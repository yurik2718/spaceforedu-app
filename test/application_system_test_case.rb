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

  # Dump the rendered HTML next to the failure screenshot so we can see what
  # the browser actually had when an assertion blew up. Lives alongside the
  # auto-screenshot in tmp/capybara/, which the CI workflow uploads on failure.
  def after_teardown
    super
    return if passed?
    File.write(Rails.root.join("tmp/capybara/failures_#{name}.html"), page.html)
  rescue StandardError
    # best-effort; never let a dump failure mask the real test failure
  end
end
