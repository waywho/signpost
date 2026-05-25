import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "stream", "result"]
  static values = { url: String }

  connect() {
    this.startStream()
  }

  async startStream() {
    try {
      const response = await fetch(this.urlValue)
      const reader = response.body.getReader()
      const decoder = new TextDecoder()
      let buffer = ""

      while (true) {
        const { done, value } = await reader.read()
        if (done) break

        buffer += decoder.decode(value, { stream: true })
        const lines = buffer.split("\n")
        buffer = lines.pop() // keep incomplete line in buffer

        for (const line of lines) {
          const trimmed = line.trim()
          if (!trimmed || !trimmed.startsWith("data: ")) continue

          try {
            const data = JSON.parse(trimmed.slice(6))
            this.handleEvent(data)
          } catch (e) {
            // not JSON, skip
          }
        }
      }
    } catch (e) {
      this.statusTarget.textContent = `Error: ${e.message}`
    }
  }

  handleEvent(data) {
    switch (data.type) {
      case "status":
        this.statusTarget.textContent = data.text
        break
      case "chunk":
        this.streamTarget.hidden = false
        this.streamTarget.textContent += data.text
        this.streamTarget.scrollTop = this.streamTarget.scrollHeight
        break
      case "complete":
        this.resultTarget.innerHTML = data.html
        this.resultTarget.hidden = false
        this.streamTarget.hidden = true
        this.statusTarget.hidden = true
        // Hide the loading card
        const loader = this.element.querySelector("[data-loader]")
        if (loader) loader.hidden = true
        break
      case "error":
        this.statusTarget.textContent = `Analysis failed: ${data.text}`
        this.statusTarget.style.color = "var(--color-negative)"
        break
    }
  }

  disconnect() {
    // cleanup if needed
  }
}
