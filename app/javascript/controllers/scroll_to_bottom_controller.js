import { Controller } from "@hotwired/stimulus"

// Follows new messages to the bottom — but only if the user is already there.
// If they've scrolled up to read history, leave them alone.
export default class extends Controller {
  static threshold = 80

  connect() {
    this.scrollToBottom()
    this.observer = new MutationObserver(() => this.maybeScroll())
    this.observer.observe(this.element, { childList: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  maybeScroll() {
    if (this.nearBottom) this.scrollToBottom()
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }

  get nearBottom() {
    const { scrollTop, scrollHeight, clientHeight } = this.element
    return scrollHeight - scrollTop - clientHeight < this.constructor.threshold
  }
}
