import { Controller } from '@hotwired/stimulus';
import Cropper from 'cropperjs';

export default class extends Controller {
  static targets = [
    'input',
    'preview',
    'dropzone',
    'url',
    'clearButton',
    'previewArea',
    'cropModal',
    'cropImage'
  ];
  static values = {
    uploadUrl: String,
    aspectRatio: Number,
    enableCrop: { type: Boolean, default: false }
  };

  connect() {
    this.setupDropzone();
    this.cropper = null;
    this.selectedFile = null;
  }

  disconnect() {
    this.destroyCropper();
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
      const file = files[0];
      if (this.enableCropValue && this.hasCropModalTarget) {
        await this.showCropModal(file);
      } else {
        await this.uploadFile(file);
      }
    }
  }

  async fileSelected(event) {
    const file = event.target.files[0];
    if (file) {
      if (this.enableCropValue && this.hasCropModalTarget) {
        await this.showCropModal(file);
      } else {
        await this.uploadFile(file);
      }
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
      // Upload error - show error to user via showError method
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
    this.previewTarget.classList.remove('is--hidden');

    // プレビューエリア全体を表示
    if (this.hasPreviewAreaTarget) {
      this.previewAreaTarget.classList.remove('is--hidden');
    }

    // ドロップゾーンを非表示
    this.dropzoneTarget.classList.add('is--hidden');

    // 削除ボタンを表示
    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.classList.remove('is--hidden');
      // 削除ボタンの親要素も表示
      if (this.clearButtonTarget.parentElement) {
        this.clearButtonTarget.parentElement.classList.remove('is--hidden');
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
        <button type="button" class="a--button is--md is--primary" data-action="click->thumbnail-upload#selectFile">
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
    this.previewTarget.classList.add('is--hidden');

    // プレビューエリア全体を非表示
    if (this.hasPreviewAreaTarget) {
      this.previewAreaTarget.classList.add('is--hidden');
    }

    // ドロップゾーンを再表示
    this.dropzoneTarget.classList.remove('is--hidden');

    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.classList.add('is--hidden');
      // 削除ボタンの親要素も非表示
      if (this.clearButtonTarget.parentElement) {
        this.clearButtonTarget.parentElement.classList.add('is--hidden');
      }
    }
    this.resetDropzone();
  }

  showError(message) {
    // Simple error display - you might want to use a more sophisticated toast system
    alert(message);
  }

  showSuccess() {
    // Success message already shown in UI update - no additional action needed
  }

  // Crop機能
  async showCropModal(file) {
    this.selectedFile = file;

    const reader = new FileReader();
    reader.onload = (e) => {
      this.cropImageTarget.src = e.target.result;
      this.cropModalTarget.classList.remove('is--hidden');
      document.body.style.overflow = 'hidden';
      this.initCropper();
    };
    reader.onerror = () => {
      this.showError('画像の読み込みに失敗しました');
      this.inputTarget.value = '';
    };
    reader.readAsDataURL(file);
  }

  initCropper() {
    this.destroyCropper();

    const aspectRatio = this.hasAspectRatioValue
      ? this.aspectRatioValue
      : 16 / 9;

    this.cropper = new Cropper(this.cropImageTarget, {
      aspectRatio: aspectRatio,
      viewMode: 1,
      autoCropArea: 0.9,
      responsive: true,
      restore: false,
      guides: true,
      center: true,
      highlight: false,
      cropBoxMovable: true,
      cropBoxResizable: true,
      toggleDragModeOnDblclick: false,
      background: false,
      modal: true
    });
  }

  destroyCropper() {
    if (this.cropper) {
      this.cropper.destroy();
      this.cropper = null;
    }
  }

  cancelCrop() {
    this.closeCropModal();
    this.inputTarget.value = '';
  }

  async confirmCrop() {
    if (!this.cropper) return;

    try {
      const canvas = this.cropper.getCroppedCanvas();

      if (!canvas) {
        console.error('Crop error: getCroppedCanvas returned null');
        this.showError('クロップ処理に失敗しました');
        return;
      }

      // Wrap toBlob in a Promise to properly handle errors
      const blob = await new Promise((resolve, reject) => {
        canvas.toBlob(
          (blob) => {
            if (!blob) {
              reject(new Error('toBlob returned null'));
            } else {
              resolve(blob);
            }
          },
          this.selectedFile.type,
          0.9 // quality parameter for image compression
        );
      });

      if (!blob) {
        console.error('Crop error: blob is null');
        this.showError('クロップ処理に失敗しました');
        return;
      }

      const file = new File([blob], this.selectedFile.name, {
        type: this.selectedFile.type,
        lastModified: Date.now()
      });

      this.closeCropModal();
      await this.uploadFile(file);

    } catch (error) {
      console.error('Crop error:', error);
      this.showError('クロップ処理に失敗しました');
    }
  }

  closeCropModal() {
    if (this.hasCropModalTarget) {
      this.cropModalTarget.classList.add('is--hidden');
      document.body.style.overflow = '';
    }
    this.destroyCropper();
    this.selectedFile = null;
    this.inputTarget.value = '';
  }
}
