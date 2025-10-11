import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "dialog"]

  connect() {
    // ESCキーでモーダルを閉じる
    this.handleKeydown = this.handleKeydown.bind(this)
  }

  open(event) {
    event.preventDefault()
    this.modalTarget.classList.remove("hidden")
    this.modalTarget.classList.add("flex")
    document.body.style.overflow = "hidden"
    document.addEventListener("keydown", this.handleKeydown)
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }
    this.modalTarget.classList.add("hidden")
    this.modalTarget.classList.remove("flex")
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this.handleKeydown)
  }

  closeOnBackdrop(event) {
    // モーダルの背景をクリックした時のみ閉じる（ダイアログ内のクリックは無視）
    if (event.target === this.modalTarget) {
      this.close()
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
    document.body.style.overflow = ""
  }
}
