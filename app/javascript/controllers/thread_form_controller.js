import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["slackUrl", "channelId", "threadTs"]
  parseUrl() {
    const url = this.slackUrlTarget.value.trim()
    const match = url.match(/\/archives\/([A-Z0-9]+)\/p(\d+)/)
    if (!match) return
    if (!this.channelIdTarget.value) this.channelIdTarget.value = match[1]
    this.threadTsTarget.value = match[2].slice(0, 10) + "." + match[2].slice(10)
  }
}
