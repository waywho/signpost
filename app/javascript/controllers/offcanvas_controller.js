import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "frame"]

  open(event) {
    event.preventDefault()
    const url = event.params.url
    if (url) {
      this.frameTarget.src = url
    }
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
    this.frameTarget.removeAttribute("src")
    this.frameTarget.innerHTML = ""
  }

  backdropClick(event) {
    if (event.target === this.dialogTarget) {
      this.close()
    }
  }
}
