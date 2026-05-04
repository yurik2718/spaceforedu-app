import { Controller } from "@hotwired/stimulus"

// Drag-and-drop file uploads. Click "Choose files" or drag files onto the
// zone — either way the form auto-submits with the selected files.
export default class extends Controller {
  static targets = ["input", "form", "label"]

  connect() {
    this.element.addEventListener("dragover",  this.dragOver.bind(this))
    this.element.addEventListener("dragleave", this.dragLeave.bind(this))
    this.element.addEventListener("dragend",   this.dragLeave.bind(this))
    this.element.addEventListener("drop",      this.drop.bind(this))
  }

  dragOver(event) {
    event.preventDefault()
    this.element.dataset.over = "true"
  }

  dragLeave() {
    delete this.element.dataset.over
  }

  drop(event) {
    event.preventDefault()
    delete this.element.dataset.over
    if (!event.dataTransfer?.files?.length) return
    this.inputTarget.files = event.dataTransfer.files
    this.submit()
  }

  selected() {
    if (this.inputTarget.files.length) this.submit()
  }

  submit() {
    if (this.hasLabelTarget) this.labelTarget.textContent = this.busyMessage()
    this.formTarget.requestSubmit()
  }

  busyMessage() {
    const n = this.inputTarget.files.length
    return this.element.dataset.busyMessage?.replace("%{count}", n) || `Uploading ${n}…`
  }
}
