import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link", "panel"]

  connect() {
    this.show(0)
  }

  select(event) {
    event.preventDefault()
    const index = this.linkTargets.indexOf(event.currentTarget)
    this.show(index)
  }

  show(index) {
    this.linkTargets.forEach((link, i) => {
      link.ariaCurrent = i === index ? "page" : null
    })
    this.panelTargets.forEach((panel, i) => {
      panel.hidden = i !== index
    })
  }
}
