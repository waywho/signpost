import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link", "panel"]

  connect() {
    const hash = window.location.hash.replace("#", "")
    if (hash) {
      const index = this.panelTargets.findIndex(p => p.id === hash || p.dataset.section === hash)
      this.show(index >= 0 ? index : 0)
    } else {
      this.show(0)
    }
  }

  select(event) {
    event.preventDefault()
    const index = this.linkTargets.indexOf(event.currentTarget)
    this.show(index)
    const panel = this.panelTargets[index]
    if (panel?.id) {
      history.replaceState(null, "", `#${panel.id}`)
    }
  }

  show(index) {
    if (index < 0 || index >= this.linkTargets.length) index = 0
    this.linkTargets.forEach((link, i) => {
      link.ariaCurrent = i === index ? "page" : null
    })
    this.panelTargets.forEach((panel, i) => {
      panel.hidden = i !== index
    })
  }
}
