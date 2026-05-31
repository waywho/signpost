import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["stream"]

  streamTargetConnected() {
    this.observer = new MutationObserver(() => {
      this.streamTarget.hidden = false
      this.streamTarget.scrollTop = this.streamTarget.scrollHeight
    })
    this.observer.observe(this.streamTarget, { childList: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }
}
