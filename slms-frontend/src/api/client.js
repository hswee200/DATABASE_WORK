const BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000';
const STORAGE_KEY = 'slms_auth';

export class ApiError extends Error {
  constructor(message, status) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
  }
}

// Set once by AuthProvider so a 401 anywhere can clear the session and send the
// user back to login, without api/client.js importing React or the router.
let onUnauthorized = () => {};
export function registerUnauthorizedHandler(fn) {
  onUnauthorized = fn;
}

function getToken() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw).token : null;
  } catch {
    return null;
  }
}

// Every call goes through here so the token header and error handling stay in
// one place instead of being repeated per fetch call.
export async function apiFetch(path, { method = 'GET', body, skipAuth = false } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  const token = getToken();
  if (token && !skipAuth) {
    headers.Authorization = `Bearer ${token}`;
  }

  let response;
  try {
    response = await fetch(`${BASE_URL}${path}`, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  } catch {
    // fetch itself throws on network failure (server down, CORS block before a
    // response exists) - this is not the same as a 4xx/5xx from the API.
    throw new ApiError('Could not reach the server. Is the backend running?', 0);
  }

  let data = null;
  const text = await response.text();
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      // Non-JSON response body; leave data null and fall through to the
      // status-based message below.
    }
  }

  if (!response.ok) {
    // The backend always sends { error: "..." } - that message is shown
    // verbatim rather than replaced with a generic "request failed", per the
    // requirement that real API messages reach the user.
    const message = data?.error || `Request failed with status ${response.status}.`;

    if (response.status === 401 && !skipAuth) {
      onUnauthorized();
    }

    throw new ApiError(message, response.status);
  }

  return data;
}
