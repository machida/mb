import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "preview", "dropzone", "url", "clearButton"];
  static values = { uploadUrl: String };

  connect() {
    this.setupDropzone();
  }

  setupDropzone() {
    const dropzone = this.dropzoneTarget;

    dropzone.addEventListener("dragover", this.handleDragOver.bind(this));
    dropzone.addEventListener("dragleave", this.handleDragLeave.bind(this));
    dropzone.addEventListener("drop", this.handleDrop.bind(this));
  }

  handleDragOver(event) {
    event.preventDefault();
    this.dropzoneTarget.classList.add("border-blue-500", "bg-blue-50");
  }

  handleDragLeave(event) {
    event.preventDefault();
    this.dropzoneTarget.classList.remove("border-blue-500", "bg-blue-50");
  }

  async handleDrop(event) {
    event.preventDefault();
    this.dropzoneTarget.classList.remove("border-blue-500", "bg-blue-50");

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
    if (!file.type.startsWith("image/")) {
      this.showError("画像ファイルを選択してください");
      return;
    }

    // ファイルサイズチェック (5MB)
    if (file.size > 5 * 1024 * 1024) {
      this.showError("ファイルサイズは5MB以下にしてください");
      return;
    }

    this.showLoading();

    try {
      const formData = new FormData();
      formData.append("image", file);

      const response = await fetch(this.uploadUrlValue, {
        method: "POST",
        body: formData,
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name=\"csrf-token\"]").content
        }
      });

      if (response.ok) {
        const data = await response.json();
        this.handleUploadSuccess(data);
      } else {
        const errorData = await response.json();
        this.showError(errorData.error || "アップロードに失敗しました");
      }
    } catch (error) {
      console.error("Upload error:", error);
      this.showError("アップロードに失敗しました");
    } finally {
      this.hideLoading();
    }
  }

  handleUploadSuccess(data) {
    // URLをinputに設定
    this.urlTarget.value = data.url;

    // プレビュー画像を表示
    this.previewTarget.src = data.url;
    this.previewTarget.classList.remove("hidden");

    // 削除ボタンを表示
    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.classList.remove("hidden");
      // 削除ボタンの親要素も表示
      if (this.clearButtonTarget.parentElement) {
        this.clearButtonTarget.parentElement.classList.remove("hidden");
      }
    }

    // 成功メッセージ
    this.showSuccess("画像がアップロードされました");
  }

  showLoading() {
    this.dropzoneTarget.innerHTML = `
      <div class="flex items-center justify-center py-8">
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
      <div class="flex flex-col items-center justify-center py-8">
        <svg class="w-12 h-12 text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"></path>
        </svg>
        <p class="text-gray-600 text-center mb-2">
          画像をドラッグ&ドロップするか
        </p>
        <button type="button" class="a-button is-md is-primary" data-action="click->thumbnail-upload#selectFile">
          ファイルを選択
        </button>
        <p class="text-xs text-gray-500 mt-2">JPG, PNG, GIF (最大5MB)</p>
      </div>
    `;
  }

  selectFile() {
    this.inputTarget.click();
  }

  clearThumbnail() {
    this.urlTarget.value = "";
    this.previewTarget.classList.add("hidden");
    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.classList.add("hidden");
      // 削除ボタンの親要素も非表示
      if (this.clearButtonTarget.parentElement) {
        this.clearButtonTarget.parentElement.classList.add("hidden");
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
