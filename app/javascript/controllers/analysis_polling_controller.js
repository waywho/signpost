import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, interval: { type: Number, default: 5000 } }

  connect() {
    this.poll()
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  poll() {
    this.timer = setTimeout(async () => {
      try {
        const response = await fetch(this.urlValue, {
          headers: { Accept: "text/html" }
        })
        if (response.ok) {
          const html = await response.text()
          this.element.outerHTML = html
        } else {
          this.poll()
        }
      } catch {
        this.poll()
      }
    }, this.intervalValue)
  }
}
