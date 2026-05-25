import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "selectAll", "actions"]

  connect() {
    this.updateActions()
  }

  toggleAll() {
    const checked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(cb => cb.checked = checked)
    this.updateActions()
  }

  toggle() {
    this.updateActions()
  }

  updateActions() {
    const count = this.selectedCount
    this.actionsTargets.forEach(el => {
      el.hidden = count === 0
      const label = el.querySelector("[data-count]")
      if (label) label.textContent = `${count} selected`
    })
  }

  get selectedCount() {
    return this.checkboxTargets.filter(cb => cb.checked).length
  }

  get selectedUrls() {
    return this.checkboxTargets.filter(cb => cb.checked).map(cb => cb.value)
  }
}
