require "test_helper"
require "capybara/rails"
require "capybara/minitest"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Browser-log channel + diagnostic event capture so CI failures yield
  # something we can actually read instead of a screenshot and a shrug.
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1000 ] do |options|
    options.add_option("goog:loggingPrefs", { browser: "ALL" })
  end

  # Document-level capture of click + submit events. Lets us see *whether*
  # the submit fired, *which* element actually received the click, and
  # whether anyone called preventDefault. Persists across Turbo navigation
  # because the listeners attach to `document`, but a full page navigation
  # (e.g. redirect after login) wipes them — so we re-install after every
  # explicit `visit`.
  DIAG_JS = <<~JS
    (() => {
      if (window._diag_installed) return
      window._diag_installed = true
      window._diag = []
      const log = (...args) => window._diag.push([Date.now(), ...args])
      const desc = el => el.tagName + (el.id ? "#" + el.id : "") + " text=" + (el.textContent || "").trim().slice(0, 40)
      ;["pointerdown", "pointerup", "mousedown", "mouseup", "click"].forEach(type => {
        document.addEventListener(type, e => log(type, desc(e.target), "prevented=" + e.defaultPrevented), true)
      })
      document.addEventListener("submit", e => log("submit", e.target.action || "", "prevented=" + e.defaultPrevented), true)
      window.addEventListener("error", e => log("js-error", e.message, e.filename + ":" + e.lineno))
      window.addEventListener("unhandledrejection", e => log("rejection", String(e.reason)))
    })()
  JS

  def visit(path)
    super
    page.execute_script(DIAG_JS)
  rescue StandardError
    # Diagnostic injection must never mask the real test outcome.
  end

  # Breadcrumb around click_on so we can correlate the Capybara call with
  # what (if anything) the browser actually saw. If diag shows
  # "before_click_on" / "after_click_on" but no pointer/mouse/click
  # between them, Capybara reports success but Selenium delivered nothing.
  def click_on(*args, **opts, &block)
    label = args.first.to_s
    page.execute_script("if (window._diag) window._diag.push([Date.now(), 'before_click_on', #{label.to_json}])") rescue nil
    super
    page.execute_script("if (window._diag) window._diag.push([Date.now(), 'after_click_on'])") rescue nil
  end

  def sign_in_as(user, password: "password")
    visit new_session_path
    find_field("email_address").set(user.email_address)
    find_field("password").set(password)
    find('input[type="submit"]').click
  end

  # Dump page.html + URL + browser console + captured DOM events alongside
  # the auto-screenshot. Lives in before_teardown AFTER super so it runs
  # post-screenshot but before Capybara.reset_sessions! blanks the page.
  def before_teardown
    super
    return if passed?

    dir  = Rails.root.join("tmp/capybara")
    base = "failures_#{name}"

    File.write(dir.join("#{base}.html"), page.html)
    File.write(dir.join("#{base}.url"),  "#{page.current_url}\n")

    logs = page.driver.browser.logs.get(:browser).map { |e| "[#{e.level}] #{e.timestamp} #{e.message}" }.join("\n")
    File.write(dir.join("#{base}.console.log"), logs)

    # Control dispatch: send a synthetic click on the submit button to verify
    # the listener is still alive at failure time. If THIS shows up in diag
    # but the real Capybara click_on didn't, Capybara/Selenium silently
    # ate the click. We use dispatchEvent so no form submission actually fires.
    page.execute_script(<<~JS) rescue nil
      (() => {
        const btn = document.querySelector('form[action$="/submission"] button[type="submit"]')
        if (!btn || !window._diag) return
        window._diag.push([Date.now(), "control_dispatch_attempt"])
        btn.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true }))
        window._diag.push([Date.now(), "control_dispatch_done"])
      })()
    JS

    diag = page.evaluate_script("window._diag || []")
    File.write(dir.join("#{base}.diag.json"), JSON.pretty_generate(diag))

    state = page.evaluate_script(<<~JS)
      (() => {
        const sub = document.querySelector('form[action$="/submission"] button')
        const r = sub && sub.getBoundingClientRect()
        return {
          activeElement: document.activeElement && document.activeElement.tagName + " text=" + (document.activeElement.textContent || "").trim().slice(0, 40),
          viewport: { w: window.innerWidth, h: window.innerHeight, scrollY: window.scrollY },
          submitButton: sub ? {
            outerHTML: sub.outerHTML,
            visible: r.width > 0 && r.height > 0,
            rect: { x: r.x, y: r.y, w: r.width, h: r.height },
            inViewport: r.bottom > 0 && r.top < window.innerHeight && r.right > 0 && r.left < window.innerWidth,
            elementAtCenter: (() => { const el = document.elementFromPoint(r.x + r.width/2, r.y + r.height/2); return el ? el.tagName + " text=" + (el.textContent || "").trim().slice(0, 40) : null })()
          } : null
        }
      })()
    JS
    File.write(dir.join("#{base}.state.json"), JSON.pretty_generate(state))
  rescue StandardError => e
    File.write(dir.join("#{base}.dump_error.txt"), "#{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}") rescue nil
  end
end
