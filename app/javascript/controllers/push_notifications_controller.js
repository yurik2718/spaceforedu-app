import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "status"]

  connect() {
    if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
      this.element.hidden = true
      return
    }
    this.syncCheckboxState()
  }

  async syncCheckboxState() {
    const registration = await navigator.serviceWorker.ready
    const subscription = await registration.pushManager.getSubscription()
    this.checkboxTarget.checked = !!subscription
  }

  async toggle(event) {
    const checkbox = event.target
    try {
      if (checkbox.checked) {
        await this.#subscribe()
      } else {
        await this.#unsubscribe()
      }
    } catch {
      checkbox.checked = !checkbox.checked
    }
  }

  async #subscribe() {
    const permission = await Notification.requestPermission()
    if (permission !== "granted") throw new Error("denied")

    const registration = await navigator.serviceWorker.ready
    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: this.#vapidKey()
    })

    const { endpoint, keys } = subscription.toJSON()
    await this.#send("POST", { endpoint, p256dh_key: keys.p256dh, auth_key: keys.auth })
  }

  async #unsubscribe() {
    const registration = await navigator.serviceWorker.ready
    const subscription = await registration.pushManager.getSubscription()
    if (!subscription) return

    const { endpoint } = subscription.toJSON()
    await this.#send("DELETE", { endpoint })
    await subscription.unsubscribe()
  }

  async #send(method, body) {
    const response = await fetch("/push_subscription", {
      method,
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name=csrf-token]").content
      },
      body: JSON.stringify(body)
    })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
  }

  #vapidKey() {
    const key = document.querySelector("meta[name=vapid-public-key]")?.content
    if (!key) throw new Error("VAPID public key not found")
    const padding = "=".repeat((4 - key.length % 4) % 4)
    const base64 = (key + padding).replace(/-/g, "+").replace(/_/g, "/")
    return new Uint8Array([...atob(base64)].map(c => c.charCodeAt(0)))
  }
}
