require "test_helper"
require "capybara/rails"
require "capybara/minitest"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # The block enables Chrome's browser-log channel so we can grab the JS
  # console (and uncaught network errors) on failure — Selenium's default
  # turns it off, which is the difference between a useful and a useless
  # CI failure dump.
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1000 ] do |options|
    options.add_option("goog:loggingPrefs", { browser: "ALL" })
  end

  def sign_in_as(user, password: "password")
    visit new_session_path
    find_field("email_address").set(user.email_address)
    find_field("password").set(password)
    find('input[type="submit"]').click
  end

  # Dump page.html + URL + browser console logs alongside the auto-screenshot.
  # Has to live in `before_teardown` AFTER `super` — Rails' base class snaps
  # the screenshot in `before_teardown`, then `Capybara.reset_sessions!` runs
  # in `after_teardown` and blanks the page. Doing it here keeps the browser
  # alive for inspection.
  def before_teardown
    super
    return if passed?

    dir = Rails.root.join("tmp/capybara")
    base = "failures_#{name}"

    File.write(dir.join("#{base}.html"), page.html)
    File.write(dir.join("#{base}.url"), "#{page.current_url}\n")

    logs = page.driver.browser.logs.get(:browser).map { |e| "[#{e.level}] #{e.timestamp} #{e.message}" }.join("\n")
    File.write(dir.join("#{base}.console.log"), logs)
  rescue StandardError => e
    File.write(dir.join("#{base}.dump_error.txt"), "#{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}") rescue nil
  end
end
