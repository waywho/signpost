import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["repoTab", "searchInput", "item"]

  connect() {
    this.activeRepo = ""
  }

  filterRepo(event) {
    this.activeRepo = event.currentTarget.dataset.repo || ""
    this.repoTabTargets.forEach(tab => {
      tab.ariaCurrent = tab.dataset.repo === this.activeRepo ? "page" : null
    })
    this.applyFilters()
  }

  search() {
    this.applyFilters()
  }

  applyFilters() {
    const query = (this.searchInputTarget.value || "").toLowerCase().trim()
    const words = query.split(/\s+/).filter(w => w.length > 0)

    this.itemTargets.forEach(item => {
      const repo = item.dataset.repo || ""
      const title = (item.dataset.title || "").toLowerCase()

      const matchesRepo = !this.activeRepo || repo === this.activeRepo
      const matchesSearch = words.length === 0 || words.every(w => title.includes(w))

      item.style.display = (matchesRepo && matchesSearch) ? "" : "none"
    })
  }
}
