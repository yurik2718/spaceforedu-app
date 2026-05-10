import { Controller } from "@hotwired/stimulus"

// Click a pill → fill (or append to) the textarea, then focus and place caret at end.
// Empty textarea: replace. Non-empty: append after a blank line, so an accidental click
// never destroys typed text.
export default class extends Controller {
  static targets = ["textarea"]

  insert(event) {
    const body = event.currentTarget.dataset.body || ""
    const ta   = this.textareaTarget
    const cur  = ta.value.trim()

    ta.value = cur.length === 0 ? body : `${cur}\n\n${body}`
    ta.focus()
    ta.setSelectionRange(ta.value.length, ta.value.length)
    ta.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
