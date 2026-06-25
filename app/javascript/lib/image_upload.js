// Shared helpers for admin image uploads, used by the thumbnail and the
// in-editor (Markdown) upload controllers so the POST/validation logic lives
// in one place.

export const IMAGE_MAX_BYTES = 5 * 1024 * 1024; // 5MB

// Returns an error message string, or null when the file is acceptable.
export function validateImageFile(file) {
  if (!file.type.startsWith('image/')) {
    return '画像ファイルを選択してください';
  }
  if (file.size > IMAGE_MAX_BYTES) {
    return 'ファイルサイズは5MB以下にしてください';
  }
  return null;
}

// POSTs the image and returns the parsed JSON response.
// Throws an Error (with the server-provided message when available) on failure.
export async function postImage(
  uploadUrl,
  file,
  { csrfSelector = 'meta[name="csrf-token"]' } = {}
) {
  const formData = new FormData();
  formData.append('image', file);

  const response = await fetch(uploadUrl, {
    method: 'POST',
    body: formData,
    headers: {
      'X-CSRF-Token': document.querySelector(csrfSelector).content,
    },
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(data.error || 'アップロードに失敗しました');
  }
  return data;
}
