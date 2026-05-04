import { Controller } from "@hotwired/stimulus"

// Click-toggle dropdown. Closes on outside click, Escape, or after activating
// any link/button inside the menu (so navigation/forms work as expected).
export default class extends Controller {
  static targets = ["menu"]
  static classes = ["open"]

  connect() {
    this.boundOutsideClick = this.outsideClick.bind(this)
    this.boundKeydown      = this.keydown.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundOutsideClick, true)
    document.removeEventListener("keydown", this.boundKeydown)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.element.dataset.open = "true"
    document.addEventListener("click", this.boundOutsideClick, true)
    document.addEventListener("keydown", this.boundKeydown)
  }

  close() {
    delete this.element.dataset.open
    document.removeEventListener("click", this.boundOutsideClick, true)
    document.removeEventListener("keydown", this.boundKeydown)
  }

  get isOpen() {
    return this.element.dataset.open === "true"
  }

  outsideClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  keydown(event) {
    if (event.key === "Escape") this.close()
  }
}
