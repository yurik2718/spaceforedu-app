import { Controller } from "@hotwired/stimulus"

// Scrolls the element to the bottom on connect and whenever children are added
// (used by chat to follow new messages, including those arriving via Turbo broadcasts).
export default class extends Controller {
  connect() {
    this.scrollToBottom()
    this.observer = new MutationObserver(() => this.scrollToBottom())
    this.observer.observe(this.element, { childList: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }
}
