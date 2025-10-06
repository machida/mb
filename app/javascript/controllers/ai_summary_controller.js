import { Controller } from "@hotwired/stimulus"

// AI概要生成コントローラー
export default class extends Controller {
  static values = {
    url: String
  }

  async generate(event) {
    event.preventDefault()

    const button = event.currentTarget
    const form = this.element.closest("form")
    const titleInput = form.querySelector(".spec--title-input")
    const bodyInput = form.querySelector(".spec--body-input")
    const summaryInput = form.querySelector(".spec--summary-input")

    if (!titleInput || !bodyInput || !summaryInput) {
      this.showError("フォーム要素が見つかりません")
      return
    }

    const title = titleInput.value.trim()
    const body = bodyInput.value.trim()
    const currentSummary = summaryInput.value.trim()

    // タイトルと本文の入力チェック
    if (!title || !body) {
      alert("タイトルと本文を入力してください")
      return
    }

    // 既存の概要がある場合は確認
    if (currentSummary) {
      if (!confirm("既存の概要が上書きされます。よろしいですか？")) {
        return
      }
    }

    // ボタンを無効化して生成中を表示
    const originalText = button.innerHTML
    button.disabled = true
    button.innerHTML = `
      <svg class="animate-spin h-4 w-4 inline-block mr-1" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      生成中...
    `

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify({ title, body })
      })

      const data = await response.json()

      if (response.ok) {
        summaryInput.value = data.summary
        this.showSuccess("概要を生成しました")
      } else {
        this.showError(data.error || "概要の生成に失敗しました")
      }
    } catch (error) {
      console.error("AI Summary generation error:", error)
      this.showError("ネットワークエラーが発生しました")
    } finally {
      button.disabled = false
      button.innerHTML = originalText
    }
  }

  createToast(message, type = "success") {
    const toastContainer = document.querySelector(".a--toast-container")
    if (toastContainer) {
      // XSS対策のため、メッセージをエスケープ
      const escapedMessage = message
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;")

      const icons = {
        success: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>',
        error: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>'
      }

      const toast = document.createElement("div")
      toast.className = `a--toast is-${type}`
      toast.setAttribute("data-controller", "toast")
      toast.setAttribute("data-toast-auto-dismiss-value", "true")
      toast.innerHTML = `
        <div class="a--toast-content">
          <svg class="a--toast-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            ${icons[type]}
          </svg>
          <span>${escapedMessage}</span>
        </div>
      `
      toastContainer.appendChild(toast)
    } else {
      alert(message)
    }
  }

  showError(message) {
    this.createToast(message, "error")
  }

  showSuccess(message) {
    this.createToast(message, "success")
  }
}
