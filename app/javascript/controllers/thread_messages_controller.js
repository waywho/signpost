import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["overflow", "toggle"]
  showAll() {
    this.overflowTarget.style.display = "block"
    this.toggleTarget.remove()
  }
}
