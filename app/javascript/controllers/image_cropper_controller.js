import { Controller } from '@hotwired/stimulus';
import Cropper from 'cropperjs';

export default class extends Controller {
  static targets = [
    'input',
    'preview',
    'modal',
    'image',
    'cancelButton',
    'cropButton'
  ];

  static values = {
    aspectRatio: Number, // 16/9 または 1200/630
    uploadCallback: String
  };

  connect() {
    this.cropper = null;
    this.selectedFile = null;
  }

  disconnect() {
    this.destroyCropper();
  }

  // ファイル選択時
  async fileSelected(event) {
    const file = event.target.files[0];
    if (!file) return;

    // ファイル形式チェック
    if (!file.type.startsWith('image/')) {
      alert('画像ファイルを選択してください');
      return;
    }

    // ファイルサイズチェック (5MB)
    if (file.size > 5 * 1024 * 1024) {
      alert('ファイルサイズは5MB以下にしてください');
      return;
    }

    this.selectedFile = file;
    await this.showCropModal(file);
  }

  // クロップモーダルを表示
  async showCropModal(file) {
    const reader = new FileReader();

    reader.onload = (e) => {
      // モーダル内の画像に読み込んだ画像を設定
      this.imageTarget.src = e.target.result;

      // モーダルを表示
      this.modalTarget.classList.remove('is--hidden');
      document.body.style.overflow = 'hidden';

      // Cropperインスタンスを初期化
      this.initCropper();
    };

    reader.readAsDataURL(file);
  }

  // Cropperを初期化
  initCropper() {
    this.destroyCropper();

    const aspectRatio = this.hasAspectRatioValue
      ? this.aspectRatioValue
      : 16 / 9; // デフォルトは16:9

    this.cropper = new Cropper(this.imageTarget, {
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
    });
  }

  // Cropperを破棄
  destroyCropper() {
    if (this.cropper) {
      this.cropper.destroy();
      this.cropper = null;
    }
  }

  // キャンセルボタン
  cancel() {
    this.closeModal();
    this.inputTarget.value = ''; // ファイル選択をリセット
  }

  // クロップ確定
  async crop() {
    if (!this.cropper) return;

    try {
      // クロップデータを取得
      const cropData = this.cropper.getData();

      // クロップされた画像をCanvasとして取得
      const canvas = this.cropper.getCroppedCanvas();

      // Canvasをblobに変換
      canvas.toBlob(async (blob) => {
        // コールバック関数を呼び出し
        if (this.hasUploadCallbackValue) {
          const callbackFnName = this.uploadCallbackValue;
          const callbackController = this.getParentController();

          if (callbackController && typeof callbackController[callbackFnName] === 'function') {
            await callbackController[callbackFnName](blob, cropData);
          }
        }

        this.closeModal();
      }, this.selectedFile.type);

    } catch (error) {
      console.error('Crop error:', error);
      alert('クロップ処理に失敗しました');
    }
  }

  // モーダルを閉じる
  closeModal() {
    this.modalTarget.classList.add('is--hidden');
    document.body.style.overflow = '';
    this.destroyCropper();
    this.selectedFile = null;
    this.inputTarget.value = '';
  }

  // 親コントローラを取得
  getParentController() {
    const controllerElement = this.element.closest('[data-controller*="thumbnail-upload"]');
    if (!controllerElement) return null;

    return this.application.getControllerForElementAndIdentifier(
      controllerElement,
      'thumbnail-upload'
    );
  }
}
