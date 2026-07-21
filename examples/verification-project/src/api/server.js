/**
 * Express REST API — verification example
 * Demonstrates: clean architecture, error handling, validation, security
 */

const express = require('express');
const crypto = require('crypto');
const app = express();
const PORT = process.env.PORT || 3001;

// ── Middleware ──────────────────────────────────────────────
app.use(express.json({ limit: '10kb' })); // Body limit
app.use((_req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  next();
});

// ── In-memory store (demo — use DB in production) ──────────
const users = new Map();
let idCounter = 1;

/**
 * Validate user creation/update payload
 * @param {Object} body - Request body
 * @param {string} body.name - User name (min 2 chars)
 * @param {string} body.email - Valid email address
 * @param {'admin'|'editor'|'viewer'} [body.role] - User role
 * @returns {string[]} Array of validation error messages (empty if valid)
 */
function validateUser(body) {
  const errors = [];
  if (!body.name || typeof body.name !== 'string' || body.name.trim().length < 2) {
    errors.push('name: required, min 2 characters');
  }
  if (!body.email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(body.email)) {
    errors.push('email: required, valid format');
  }
  if (body.role && !['admin', 'editor', 'viewer'].includes(body.role)) {
    errors.push('role: must be admin, editor, or viewer');
  }
  return errors;
}

// ── Routes ─────────────────────────────────────────────────

// GET /api/health
app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// GET /api/users
app.get('/api/users', (_req, res) => {
  const list = Array.from(users.values());
  res.json({ data: list, total: list.length });
});

// GET /api/users/:id
app.get('/api/users/:id', (req, res) => {
  const user = users.get(Number(req.params.id));
  if (!user) return res.status(404).json({ error: 'User not found' });
  res.json({ data: user });
});

// POST /api/users
app.post('/api/users', (req, res) => {
  const errors = validateUser(req.body);
  if (errors.length > 0) {
    return res.status(400).json({ error: 'Validation failed', details: errors });
  }

  const user = {
    id: idCounter++,
    name: req.body.name.trim(),
    email: req.body.email.toLowerCase().trim(),
    role: req.body.role || 'viewer',
    createdAt: new Date().toISOString(),
  };
  users.set(user.id, user);
  res.status(201).json({ data: user });
});

// PUT /api/users/:id
app.put('/api/users/:id', (req, res) => {
  const existing = users.get(Number(req.params.id));
  if (!existing) return res.status(404).json({ error: 'User not found' });

  const errors = validateUser(req.body);
  if (errors.length > 0) {
    return res.status(400).json({ error: 'Validation failed', details: errors });
  }

  const updated = {
    ...existing,
    name: req.body.name.trim(),
    email: req.body.email.toLowerCase().trim(),
    role: req.body.role || existing.role,
    updatedAt: new Date().toISOString(),
  };
  users.set(updated.id, updated);
  res.json({ data: updated });
});

// DELETE /api/users/:id
app.delete('/api/users/:id', (req, res) => {
  const deleted = users.delete(Number(req.params.id));
  if (!deleted) return res.status(404).json({ error: 'User not found' });
  res.status(204).end();
});

// ── 404 catch-all ──────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// ── Error handler ──────────────────────────────────────────
/**
 * Global error handler middleware
 * @param {Error} err - Thrown error
 * @param {import('express').Request} _req - Request (unused)
 * @param {import('express').Response} res - Response object
 * @param {import('express').NextFunction} _next - Next middleware (unused)
 */
app.use((err, _req, res, _next) => {
  console.error('[ERROR]', err.message);
  res.status(500).json({ error: 'Internal server error' });
});

// ── Start ──────────────────────────────────────────────────
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`API running on http://localhost:${PORT}`);
  });
}

module.exports = app; // For testing
