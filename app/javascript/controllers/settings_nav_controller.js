import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link", "panel"]

  connect() {
    const anchor = new URLSearchParams(window.location.search).get("anchor") || window.location.hash.replace("#", "")
    if (anchor) {
      const index = this.panelTargets.findIndex(p => p.id === anchor || p.dataset.section === anchor)
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
