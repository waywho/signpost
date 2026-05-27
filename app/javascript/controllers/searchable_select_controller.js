import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "select"]

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()
    const options = this.selectTarget.querySelectorAll("option[data-name]")

    options.forEach(option => {
      option.hidden = query.length > 0 && !option.dataset.name.includes(query)
    })
  }
}
