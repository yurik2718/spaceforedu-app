import { Controller } from "@hotwired/stimulus"

// Drag-and-drop file uploads. Click "Choose files" or drag files onto the
// zone — either way the form auto-submits with direct uploads, and a per-file
// progress bar shows bytes flying.
export default class extends Controller {
  static targets = ["input", "form", "label", "progress"]

  connect() {
    this.element.addEventListener("dragover",  this.dragOver.bind(this))
    this.element.addEventListener("dragleave", this.dragLeave.bind(this))
    this.element.addEventListener("dragend",   this.dragLeave.bind(this))
    this.element.addEventListener("drop",      this.drop.bind(this))

    this.inputTarget.addEventListener("direct-upload:initialize", this.initializeUpload.bind(this))
    this.inputTarget.addEventListener("direct-upload:progress",   this.progressUpload.bind(this))
    this.inputTarget.addEventListener("direct-upload:error",      this.errorUpload.bind(this))
    this.inputTarget.addEventListener("direct-upload:end",        this.endUpload.bind(this))
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

  initializeUpload(event) {
    if (!this.hasProgressTarget) return
    const { id, file } = event.detail
    const li = document.createElement("li")
    li.id = `direct-upload-${id}`
    li.className = "flex items-center gap-3 text-xs"
    li.innerHTML = `
      <span class="truncate flex-1" title="${file.name}">${file.name}</span>
      <progress class="progress progress-primary w-32" value="0" max="100"></progress>
    `
    this.progressTarget.appendChild(li)
  }

  progressUpload(event) {
    const { id, progress } = event.detail
    const bar = document.querySelector(`#direct-upload-${id} progress`)
    if (bar) bar.value = progress
  }

  endUpload(event) {
    const { id } = event.detail
    const bar = document.querySelector(`#direct-upload-${id} progress`)
    if (bar) bar.value = 100
  }

  errorUpload(event) {
    const { id, error } = event.detail
    event.preventDefault()
    const li = document.querySelector(`#direct-upload-${id}`)
    if (li) li.classList.add("text-error")
  }
}
