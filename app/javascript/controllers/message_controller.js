import { Controller } from "@hotwired/stimulus"

// Flips the bubble to the right side when the message belongs to the current user.
// We can't do this server-side because broadcast_append_to renders without a session context.
export default class extends Controller {
  connect() {
    const container   = document.getElementById("messages")
    const currentUser = container?.dataset.currentUserId

    if (currentUser && this.element.dataset.userId === currentUser) {
      this.element.classList.replace("chat-start", "chat-end")
    }
  }
}
