import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["priorityList"]

  addPriority() {
    const index = this.priorityListTarget.children.length
    const li = document.createElement("li")
    li.className = "flex items-center gap-half"
    li.innerHTML = `
      <input type="text" name="daily_log[tomorrow_priorities][]"
             placeholder="Priority ${index + 1}" class="input flex-1 text-sm" autofocus>
      <button type="button" data-action="daily-log#removePriority"
              style="color: var(--color-text-subtle)"><i class="ph ph-x"></i></button>
    `
    this.priorityListTarget.appendChild(li)
    li.querySelector("input").focus()
  }

  removePriority(event) {
    event.target.closest("li").remove()
  }
}
