import { Controller } from "@hotwired/stimulus"

// Flips bubble orientation + colors it for the current user.
// Done client-side because broadcast_append_to renders without session context.
export default class extends Controller {
  connect() {
    const container   = document.getElementById("messages")
    const currentUser = container?.dataset.currentUserId

    if (currentUser && this.element.dataset.userId === currentUser) {
      this.element.classList.replace("chat-start", "chat-end")
      this.element.querySelector(".chat-bubble")?.classList.add("chat-bubble-primary")
    }
  }
}
