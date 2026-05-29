import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  add() {
    const row = this.templateTarget.content.cloneNode(true)
    this.listTarget.appendChild(row)
  }

  remove(event) {
    event.target.closest("[data-repo-paths-target='row']").remove()
  }
}
