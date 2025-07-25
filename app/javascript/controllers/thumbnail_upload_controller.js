import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['input', 'preview', 'dropzone', 'url', 'clearButton', 'previewArea'];
  static values = { uploadUrl: String };

  connect() {
    this.setupDropzone();
  }

  setupDropzone() {
    const dropzone = this.dropzoneTarget;

    dropzone.addEventListener('dragover', this.handleDragOver.bind(this));
    dropzone.addEventListener('dragleave', this.handleDragLeave.bind(this));
    dropzone.addEventListener('drop', this.handleDrop.bind(this));
  }

  handleDragOver(event) {
    event.preventDefault();
    this.dropzoneTarget.classList.add('border-blue-500', 'bg-blue-50');
  }

  handleDragLeave(event) {
    event.preventDefault();
    this.dropzoneTarget.classList.remove('border-blue-500', 'bg-blue-50');
  }

  async handleDrop(event) {
    event.preventDefault();
    this.dropzoneTarget.classList.remove('border-blue-500', 'bg-blue-50');

    const files = event.dataTransfer.files;
    if (files.length > 0) {
      await this.uploadFile(files[0]);
    }
  }

  async fileSelected(event) {
    const file = event.target.files[0];
    if (file) {
      await this.uploadFile(file);
    }
  }

  async uploadFile(file) {
    // ファイル形式チェック
    if (!file.type.startsWith('image/')) {
      this.showError('画像ファイルを選択してください');
      return;
    }

    // ファイルサイズチェック (5MB)
    if (file.size > 5 * 1024 * 1024) {
      this.showError('ファイルサイズは5MB以下にしてください');
      return;
    }

    this.showLoading();

    try {
      const formData = new FormData();
      formData.append('image', file);

      const response = await fetch(this.uploadUrlValue, {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      });

      if (response.ok) {
        const data = await response.json();
        this.handleUploadSuccess(data);
      } else {
        const errorData = await response.json();
        this.showError(errorData.error || 'アップロードに失敗しました');
      }
    } catch (error) {
      console.error('Upload error:', error);
      this.showError('アップロードに失敗しました');
    } finally {
      this.hideLoading();
    }
  }

  handleUploadSuccess(data) {
    // URLをinputに設定
    this.urlTarget.value = data.url;

    // プレビュー画像を表示
    this.previewTarget.src = data.url;
    this.previewTarget.classList.remove('hidden');

    // プレビューエリア全体を表示
    if (this.hasPreviewAreaTarget) {
      this.previewAreaTarget.classList.remove('hidden');
    }

    // ドロップゾーンを非表示
    this.dropzoneTarget.classList.add('hidden');

    // 削除ボタンを表示
    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.classList.remove('hidden');
      // 削除ボタンの親要素も表示
      if (this.clearButtonTarget.parentElement) {
        this.clearButtonTarget.parentElement.classList.remove('hidden');
      }
    }

    // 成功メッセージ
    this.showSuccess('画像がアップロードされました');
  }

  showLoading() {
    this.dropzoneTarget.innerHTML = `
      <div class="flex items-center justify-center">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
        <span class="ml-2 text-gray-600">アップロード中...</span>
      </div>
    `;
  }

  hideLoading() {
    this.resetDropzone();
  }

  resetDropzone() {
    this.dropzoneTarget.innerHTML = `
      <div class="flex flex-col items-center justify-center text-center px-4">
        <span class="material-symbols-outlined text-gray-400 mb-4 text-4xl">
          cloud_upload
        </span>
        <p class="text-gray-600 text-center mb-2">
          画像をドラッグ&ドロップ
        </p>
        <button type="button" class="a--button is-md is-primary" data-action="click->thumbnail-upload#selectFile">
          ファイルを選択
        </button>
        <div class="a--form-help mt-2">
          <p>JPG、PNG、GIF（最大5MB）。</p>
        </div>
      </div>
    `;
  }

  selectFile() {
    this.inputTarget.click();
  }

  clearThumbnail() {
    this.urlTarget.value = '';
    this.previewTarget.classList.add('hidden');

    // プレビューエリア全体を非表示
    if (this.hasPreviewAreaTarget) {
      this.previewAreaTarget.classList.add('hidden');
    }

    // ドロップゾーンを再表示
    this.dropzoneTarget.classList.remove('hidden');

    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.classList.add('hidden');
      // 削除ボタンの親要素も非表示
      if (this.clearButtonTarget.parentElement) {
        this.clearButtonTarget.parentElement.classList.add('hidden');
      }
    }
    this.resetDropzone();
  }

  showError(message) {
    // Simple error display - you might want to use a more sophisticated toast system
    alert(message);
  }

  showSuccess(message) {
    // Simple success display - you might want to use a more sophisticated toast system
    console.log(message);
  }
}
