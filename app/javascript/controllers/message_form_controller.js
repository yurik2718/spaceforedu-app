import { Controller } from "@hotwired/stimulus"

// Resets the chat form after a successful send so the textarea clears
// without re-rendering the form (avoids focus jitter and layout shift).
export default class extends Controller {
  reset(event) {
    if (event.detail.success) this.element.reset()
  }
}
