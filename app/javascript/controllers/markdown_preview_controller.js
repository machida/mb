import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview"]

  connect() {
    // 初期値をプレビューに設定
    this.update()
  }

  async update(event) {
    // textarea を見つけて値を取得
    const textarea = event?.target || this.element.querySelector('textarea')
    
    if (!textarea) {
      console.error('Textarea not found')
      return
    }

    const content = textarea.value
    
    if (!content.trim()) {
      this.previewTarget.innerHTML = '<p class="text-gray-500 italic">プレビューがここに表示されます...</p>'
      return
    }

    try {
      const response = await fetch('/admin/articles/preview', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ content: content })
      })

      if (response.ok) {
        const data = await response.json()
        this.previewTarget.innerHTML = data.html
      } else {
        this.previewTarget.innerHTML = '<p class="text-red-500">プレビューの生成に失敗しました</p>'
      }
    } catch (error) {
      console.error('Preview error:', error)
      this.previewTarget.innerHTML = '<p class="text-red-500">プレビューの生成に失敗しました</p>'
    }
  }
}