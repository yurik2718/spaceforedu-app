import { Controller } from "@hotwired/stimulus"

// Singleton (mounted on <body>). Marks the document root with
// data-dragging-files="true" while the user drags a file over the page so
// any drop target — empty document slots, etc. — can highlight itself.
// Slot-level controllers handle their own dragover/drop; this one just owns
// the page-wide state so we don't attach N copies of the same listener.
export default class extends Controller {
  connect() {
    this._enter = this._enter.bind(this)
    this._leave = this._leave.bind(this)
    this._drop  = this._drop.bind(this)
    window.addEventListener("dragenter", this._enter)
    window.addEventListener("dragleave", this._leave)
    window.addEventListener("drop",      this._drop)
  }

  disconnect() {
    window.removeEventListener("dragenter", this._enter)
    window.removeEventListener("dragleave", this._leave)
    window.removeEventListener("drop",      this._drop)
    delete document.documentElement.dataset.draggingFiles
  }

  _enter(event) {
    if (this._hasFiles(event)) document.documentElement.dataset.draggingFiles = "true"
  }

  _leave(event) {
    if (event.relatedTarget == null) delete document.documentElement.dataset.draggingFiles
  }

  _drop() {
    delete document.documentElement.dataset.draggingFiles
  }

  _hasFiles(event) {
    return Array.from(event.dataTransfer?.types || []).includes("Files")
  }
}
