import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (localStorage.getItem("cookie_notice_dismissed")) {
      this.element.remove()
    }
  }

  dismiss() {
    localStorage.setItem("cookie_notice_dismissed", "1")
    this.element.remove()
  }
}
