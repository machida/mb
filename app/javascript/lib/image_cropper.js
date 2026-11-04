import Cropper, { DEFAULT_TEMPLATE } from 'cropperjs';

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
    const template = DEFAULT_TEMPLATE
      .replace('<cropper-canvas background>', '<cropper-canvas>')
      .replace(' rotatable scalable skewable translatable', '')
      .replace('initial-coverage="0.5"', `aspect-ratio="${aspectRatio}" zoomable`);
    this.cropper = new Cropper(this.imageElement, { template });
    const image = this.cropper.getCropperImage();
    const canvas = this.cropper.getCropperCanvas();
    const selection = this.cropper.getCropperSelection();

    // Wait for image scaling to settle before measuring the initial crop bounds.
    image.$ready().then(() => requestAnimationFrame(() => {
      if (!image.isConnected) return;
      const bounds = image.getBoundingClientRect();
      const container = canvas.getBoundingClientRect();
      const width = Math.min(bounds.width, bounds.height * aspectRatio) * 0.9;
      const height = width / aspectRatio;
      selection.$change(
        bounds.left - container.left + (bounds.width - width) / 2,
        bounds.top - container.top + (bounds.height - height) / 2,
        width, height
      );
    }));

    // Keep the selection inside the image, including portrait sources with gutters.
    selection.addEventListener('change', (event) => {
      const bounds = image.getBoundingClientRect();
      const container = canvas.getBoundingClientRect();
      const { x, y, width, height } = event.detail;
      if (x < bounds.left - container.left - 1 ||
          y < bounds.top - container.top - 1 ||
          x + width > bounds.right - container.left + 1 ||
          y + height > bounds.bottom - container.top + 1) {
        event.preventDefault();
      }
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
    const selection = this.cropper?.getCropperSelection();
    if (!selection || selection.width <= 0 || selection.height <= 0) {
      throw new Error('No crop selection');
    }
    const image = this.cropper.getCropperImage();
    const source = await image.$ready();
    const scale = source.naturalWidth / image.getBoundingClientRect().width;
    const canvas = await selection.$toCanvas({ width: Math.round(selection.width * scale) });

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
