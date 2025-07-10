import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea"]
  static values = { uploadUrl: String }

  connect() {
    this.dragCounter = 0
  }

  dragover(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dragCounter++
    this.addDragStyle()
  }

  dragleave(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dragCounter--
    if (this.dragCounter === 0) {
      this.removeDragStyle()
    }
  }

  drop(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dragCounter = 0
    this.removeDragStyle()

    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.uploadFiles(files)
    }
  }

  addDragStyle() {
    this.textareaTarget.classList.add('border-blue-500', 'border-2', 'bg-blue-50')
    this.textareaTarget.classList.remove('border-gray-300')
  }

  removeDragStyle() {
    this.textareaTarget.classList.remove('border-blue-500', 'border-2', 'bg-blue-50')
    this.textareaTarget.classList.add('border-gray-300')
  }

  async uploadFiles(files) {
    for (const file of files) {
      if (file.type.startsWith('image/')) {
        await this.uploadImage(file)
      }
    }
  }

  async uploadImage(file) {
    const formData = new FormData()
    formData.append('image', file)

    // アップロード中の表示
    const uploadingText = `![アップロード中...](uploading-${Date.now()})`
    this.insertTextAtCursor(uploadingText)

    try {
      const response = await fetch(this.uploadUrlValue, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('.js-csrf-token').content
        },
        body: formData
      })

      if (response.ok) {
        const data = await response.json()
        // アップロード中テキストを実際のMarkdownに置換
        this.replaceText(uploadingText, data.markdown)
        
        // プレビューを更新
        this.textareaTarget.dispatchEvent(new Event('input'))
        
        // 成功メッセージを表示
        this.showToast('画像をアップロードしました', 'success')
      } else {
        const errorData = await response.json()
        this.replaceText(uploadingText, '')
        this.showToast(errorData.error || 'アップロードに失敗しました', 'error')
      }
    } catch (error) {
      this.replaceText(uploadingText, '')
      this.showToast('アップロードに失敗しました', 'error')
    }
  }

  insertTextAtCursor(text) {
    const textarea = this.textareaTarget
    const start = textarea.selectionStart
    const end = textarea.selectionEnd
    const before = textarea.value.substring(0, start)
    const after = textarea.value.substring(end)
    
    textarea.value = before + text + after
    textarea.selectionStart = textarea.selectionEnd = start + text.length
  }

  replaceText(oldText, newText) {
    const textarea = this.textareaTarget
    textarea.value = textarea.value.replace(oldText, newText)
  }

  showToast(message, type) {
    // 既存のトーストコンテナを取得
    const container = document.querySelector('.js-toast-container')
    if (!container) return

    // トーストの色を決定
    const bgColor = type === 'success' ? 'bg-green-500' : 'bg-red-500'
    const icon = type === 'success' 
      ? '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>'
      : '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 15.5c-.77.833.192 2.5 1.732 2.5z"></path>'

    // トースト要素を作成
    const toast = document.createElement('div')
    toast.className = 'toast-notification js-toast-notification'
    toast.innerHTML = `
      <div class="${bgColor} text-white px-6 py-3 rounded-lg transform translate-x-full transition-transform duration-300 ease-in-out max-w-sm js-toast-element">
        <div class="flex items-center justify-between">
          <div class="flex items-center">
            <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              ${icon}
            </svg>
            <span>${message}</span>
          </div>
          <button class="ml-4 hover:opacity-70 js-toast-close">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>
      </div>
    `

    container.appendChild(toast)

    // アニメーションで表示
    setTimeout(() => {
      const toastElement = toast.querySelector('.js-toast-element')
      toastElement.classList.add('translate-x-0')
      toastElement.classList.remove('translate-x-full')
    }, 100)

    // クローズボタンのイベント
    toast.querySelector('.js-toast-close').addEventListener('click', () => {
      this.hideToast(toast)
    })

    // 4秒後に自動で消す
    setTimeout(() => {
      this.hideToast(toast)
    }, 4000)
  }

  hideToast(toast) {
    const toastElement = toast.querySelector('.js-toast-element')
    toastElement.classList.add('translate-x-full')
    toastElement.classList.remove('translate-x-0')
    
    setTimeout(() => {
      toast.remove()
    }, 300)
  }
}