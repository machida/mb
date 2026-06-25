import Cropper from 'cropperjs';

// Thin wrapper around Cropper.js that owns its lifecycle and turns the current
// crop selection into a File. Keeps the cropping concern out of the upload
// controller so each stays focused and small.
export class ImageCropper {
  constructor(imageElement) {
    this.imageElement = imageElement;
    this.cropper = null;
  }

  get active() {
    return this.cropper !== null;
  }

  start(aspectRatio = 16 / 9) {
    this.destroy();
    this.cropper = new Cropper(this.imageElement, {
      aspectRatio,
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
      modal: true,
    });
  }

  destroy() {
    if (this.cropper) {
      this.cropper.destroy();
      this.cropper = null;
    }
  }

  // Returns a File built from the current crop box, preserving the source
  // file's name and type. Throws on failure so callers can surface an error.
  async toFile(sourceFile) {
    const canvas = this.cropper && this.cropper.getCroppedCanvas();
    if (!canvas) {
      throw new Error('getCroppedCanvas returned null');
    }

    const blob = await new Promise((resolve, reject) => {
      canvas.toBlob(
        (result) => {
          if (result) {
            resolve(result);
          } else {
            reject(new Error('toBlob returned null'));
          }
        },
        sourceFile.type,
        0.9 // quality for image compression
      );
    });

    return new File([blob], sourceFile.name, {
      type: sourceFile.type,
      lastModified: Date.now(),
    });
  }
}
