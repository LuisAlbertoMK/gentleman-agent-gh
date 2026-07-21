/**
 * API Integration Layer — demonstrates best practices
 * - Type-safe fetch wrapper
 * - Error handling
 * - Retry logic
 * - Abort controller for cancellation
 */

const BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

// ── Custom Error ───────────────────────────────────────────

/**
 * Custom API error with status code and details
 * @class ApiError
 * @extends Error
 */
export class ApiError extends Error {
  /**
   * @param {string} message - Error message
   * @param {number} status - HTTP status code
   * @param {*} [details] - Additional error details from server
   */
  constructor(message, status, details) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.details = details;
  }
}

// ── Core fetch wrapper ─────────────────────────────────────

/**
 * Core request function with error handling
 * @param {string} endpoint - API endpoint path
 * @param {RequestInit & { signal?: AbortSignal }} [options={}] - Fetch options
 * @returns {Promise<*>} Parsed response body
 * @throws {ApiError} On HTTP errors
 */
async function request(endpoint, options = {}) {
  const { signal, ...fetchOptions } = options;
  const url = `${BASE_URL}${endpoint}`;

  const config = {
    headers: { 'Content-Type': 'application/json' },
    ...fetchOptions,
  };

  if (signal) config.signal = signal;

  try {
    const res = await fetch(url, config);

    // Handle 204 No Content
    if (res.status === 204) return null;

    const body = await res.json();

    if (!res.ok) {
      throw new ApiError(
        body.error || `HTTP ${res.status}`,
        res.status,
        body.details
      );
    }

    return body;
  } catch (err) {
    if (err.name === 'AbortError') throw err; // Re-throw cancellation
    if (err instanceof ApiError) throw err;
    throw new ApiError('Network error — check your connection', 0);
  }
}

// ── Retry wrapper ──────────────────────────────────────────

/**
 * Retry a function with exponential backoff
 * Skips retry for client errors (4xx)
 * @param {Function} fn - Async function to retry
 * @param {{ retries?: number, delay?: number, backoff?: number }} [options] - Retry config
 * @param {number} [options.retries=3] - Max retry attempts
 * @param {number} [options.delay=1000] - Initial delay in ms
 * @param {number} [options.backoff=2] - Backoff multiplier
 * @returns {Promise<*>} Result of fn()
 */
async function withRetry(fn, { retries = 3, delay = 1000, backoff = 2 } = {}) {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      return await fn();
    } catch (err) {
      if (attempt === retries || err.status >= 400 && err.status < 500) {
        throw err; // Don't retry client errors
      }
      await new Promise((r) => setTimeout(r, delay * Math.pow(backoff, attempt - 1)));
    }
  }
}

// ── API methods ────────────────────────────────────────────

export const api = {
  health: () => request('/api/health'),

  users: {
    list: (signal) => request('/api/users', { signal }),
    get: (id, signal) => request(`/api/users/${id}`, { signal }),
    create: (data, signal) =>
      request('/api/users', {
        method: 'POST',
        body: JSON.stringify(data),
        signal,
      }),
    update: (id, data, signal) =>
      request(`/api/users/${id}`, {
        method: 'PUT',
        body: JSON.stringify(data),
        signal,
      }),
    delete: (id, signal) =>
      request(`/api/users/${id}`, {
        method: 'DELETE',
        signal,
      }),
  },
};

// ── React Hook (optional) ─────────────────────────────────

/**
 * Usage in React component:
 *
 * const { data, loading, error } = useApi(() => api.users.list());
 *
 * function useApi(fetchFn) {
 *   const [state, setState] = useState({ data: null, loading: true, error: null });
 *   useEffect(() => {
 *     const controller = new AbortController();
 *     fetchFn(controller.signal)
 *       .then(data => setState({ data, loading: false, error: null }))
 *       .catch(err => {
 *         if (err.name !== 'AbortError') {
 *           setState({ data: null, loading: false, error: err });
 *         }
 *       });
 *     return () => controller.abort();
 *   }, []);
 *   return state;
 * }
 */

export default api;
