import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "hiddenField", "nameInput"]

  connect() {
    this.skills = JSON.parse(this.hiddenFieldTarget.value || "[]")
    this.render()
  }

  add() {
    const name = this.nameInputTarget.value.trim()
    if (!name) return
    this.skills.push({ name, rating: 3 })
    this.nameInputTarget.value = ""
    this.sync()
    this.render()
  }

  remove(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.skills.splice(index, 1)
    this.sync()
    this.render()
  }

  rate(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    const rating = parseInt(event.currentTarget.dataset.rating)
    this.skills[index].rating = rating
    this.sync()
    this.render()
  }

  sync() {
    this.hiddenFieldTarget.value = JSON.stringify(this.skills)
  }

  render() {
    this.listTarget.innerHTML = this.skills.map((skill, i) => `
      <div class="flex items-center gap" style="padding-block: var(--size-1); border-block-end: 1px solid var(--color-border)">
        <span class="text-sm flex-1">${skill.name}</span>
        <div class="flex gap-half">
          ${[1,2,3,4,5].map(r => `
            <button type="button" data-action="skills#rate" data-index="${i}" data-rating="${r}"
                    style="cursor: pointer; color: ${r <= skill.rating ? 'var(--color-primary)' : 'var(--color-border)'}; font-size: var(--text-lg)">
              <i class="ph ${r <= skill.rating ? 'ph-star-fill' : 'ph-star'}"></i>
            </button>
          `).join("")}
        </div>
        <button type="button" data-action="skills#remove" data-index="${i}"
                style="color: var(--color-text-subtle)">
          <i class="ph ph-x"></i>
        </button>
      </div>
    `).join("")
  }
}
