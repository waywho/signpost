import { Controller } from "@hotwired/stimulus"

// Mutual exclusion between "Create GitHub issue" checkbox and "Existing issue URL" field
export default class extends Controller {
  static targets = ["createCheckbox", "existingUrl"]

  urlChanged() {
    if (this.existingUrlTarget.value.trim() !== "") {
      this.createCheckboxTarget.checked = false
      this.createCheckboxTarget.disabled = true
    } else {
      this.createCheckboxTarget.disabled = false
    }
  }

  createChanged() {
    if (this.createCheckboxTarget.checked) {
      this.existingUrlTarget.value = ""
      this.existingUrlTarget.disabled = true
    } else {
      this.existingUrlTarget.disabled = false
    }
  }
}
