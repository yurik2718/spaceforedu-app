import { Controller } from "@hotwired/stimulus"

// Drives one document slot: the slot's empty state is the whole card, clicking
// or dropping a file submits the inner form. Page-wide drag state — the
// data-dragging-files attribute on <html> — is owned by drag_indicator.
export default class extends Controller {
  submit(event) {
    if (event.target.files?.length) this._submit()
  }

  dragover(event) {
    if (!this._hasFiles(event)) return
    event.preventDefault()
    this.element.dataset.dragOver = "true"
  }

  dragleave(event) {
    if (event.relatedTarget && this.element.contains(event.relatedTarget)) return
    delete this.element.dataset.dragOver
  }

  drop(event) {
    event.preventDefault()
    delete this.element.dataset.dragOver
    const file = event.dataTransfer?.files?.[0]
    const input = this.element.querySelector('input[type="file"]')
    if (!file || !input) return
    const transfer = new DataTransfer()
    transfer.items.add(file)
    input.files = transfer.files
    this._submit()
  }

  _submit() {
    this.element.dataset.uploading = "true"
    this.element.requestSubmit()
  }

  _hasFiles(event) {
    return Array.from(event.dataTransfer?.types || []).includes("Files")
  }
}
