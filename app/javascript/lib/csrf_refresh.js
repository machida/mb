// Refresh before submitting an open admin form: another tab may have rotated
// the session after a password change. The server still verifies every token.
document.addEventListener('turbo:before-fetch-request', async (event) => {
  const { fetchOptions, url, resume } = event.detail;
  const endpoint = document.querySelector('meta[name="admin-csrf-url"]')?.content;
  if (!endpoint || ['GET', 'HEAD'].includes(fetchOptions.method.toUpperCase()) ||
      url.origin !== window.location.origin) return;

  event.preventDefault();
  try {
    const response = await fetch(endpoint, {
      credentials: 'same-origin',
      cache: 'no-store',
      redirect: 'error',
      headers: { Accept: 'application/json' },
    });
    if (!response.ok) return;
    const { token } = await response.json();
    if (typeof token !== 'string' || !token) return;

    document.querySelectorAll('meta[name="csrf-token"]').forEach((meta) => {
      meta.content = token;
    });
    document.querySelectorAll('input[name="authenticity_token"]').forEach((input) => {
      input.value = token;
    });
    fetchOptions.headers['X-CSRF-Token'] = token;
    // Turbo has already constructed the body before dispatching this event.
    if (fetchOptions.body instanceof FormData || fetchOptions.body instanceof URLSearchParams) {
      fetchOptions.body.set('authenticity_token', token);
    }
  } catch {
    // Keep normal server-side rejection on network errors or expired sessions.
  } finally {
    resume();
  }
});
