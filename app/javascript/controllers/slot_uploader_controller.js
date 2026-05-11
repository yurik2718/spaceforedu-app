import { Controller } from "@hotwired/stimulus"

// Drives one document slot. The slot's empty state is the whole card; clicking
// or dropping a file submits the inner form. While a file is being dragged
// anywhere over the page, every slot with this controller marks the document
// element so empty slots can highlight (see CSS in application.css).
export default class extends Controller {
  connect() {
    this._onWindowDragEnter = this._onWindowDragEnter.bind(this)
    this._onWindowDragLeave = this._onWindowDragLeave.bind(this)
    this._onWindowDrop = this._onWindowDrop.bind(this)
    window.addEventListener("dragenter", this._onWindowDragEnter)
    window.addEventListener("dragleave", this._onWindowDragLeave)
    window.addEventListener("drop", this._onWindowDrop)
  }

  disconnect() {
    window.removeEventListener("dragenter", this._onWindowDragEnter)
    window.removeEventListener("dragleave", this._onWindowDragLeave)
    window.removeEventListener("drop", this._onWindowDrop)
    delete document.documentElement.dataset.draggingFiles
  }

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

  _onWindowDragEnter(event) {
    if (this._hasFiles(event)) document.documentElement.dataset.draggingFiles = "true"
  }

  _onWindowDragLeave(event) {
    if (event.relatedTarget == null) delete document.documentElement.dataset.draggingFiles
  }

  _onWindowDrop() {
    delete document.documentElement.dataset.draggingFiles
  }

  _hasFiles(event) {
    return Array.from(event.dataTransfer?.types || []).includes("Files")
  }
}
