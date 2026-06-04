import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  showLoader(e) {
    const target = e.currentTarget.dataset.target
    const targetDom = document.querySelector(`#${target}`)
    targetDom.querySelector(".loaderCard").classList.remove("hidden")
    targetDom.querySelector(".content").classList.add("hidden")
  }
}
