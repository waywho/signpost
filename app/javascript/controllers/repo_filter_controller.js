import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list"]

  filter({ params: { org } }) {
    this.listTarget.querySelectorAll("label[data-org]").forEach(label => {
      label.style.display = (!org || label.dataset.org === org) ? "" : "none"
    })
  }
}
