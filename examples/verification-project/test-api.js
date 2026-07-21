/**
 * API Server Integration Tests
 * Run: node examples/verification-project/test-api.js
 */
const app = require('./src/api/server.js');
const http = require('http');

const srv = app.listen(0, async () => {
  const port = srv.address().port;

  const run = (method, path, body) => new Promise((resolve) => {
    const opts = {
      hostname: 'localhost',
      port,
      path,
      method,
      headers: body ? { 'Content-Type': 'application/json' } : {},
    };
    const req = http.request(opts, (res) => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, body: data ? JSON.parse(data) : null });
        } catch {
          resolve({ status: res.statusCode, body: null, raw: data });
        }
      });
    });
    req.on('error', (err) => resolve({ status: 0, error: err.message }));
    if (body) req.write(JSON.stringify(body));
    req.end();
  });

  const tests = [];

  // Happy paths
  tests.push({ name: 'GET /api/health', expect: 200, result: await run('GET', '/api/health') });
  tests.push({ name: 'POST /api/users (valid)', expect: 201, result: await run('POST', '/api/users', { name: 'Juan', email: 'juan@test.com', role: 'admin' }) });
  tests.push({ name: 'GET /api/users', expect: 200, result: await run('GET', '/api/users') });
  tests.push({ name: 'GET /api/users/1', expect: 200, result: await run('GET', '/api/users/1') });
  tests.push({ name: 'PUT /api/users/1', expect: 200, result: await run('PUT', '/api/users/1', { name: 'Juan Updated', email: 'juan@test.com' }) });
  tests.push({ name: 'DELETE /api/users/1', expect: 204, result: await run('DELETE', '/api/users/1') });

  // Validation errors
  tests.push({ name: 'POST invalid email', expect: 400, result: await run('POST', '/api/users', { name: 'X', email: 'bad' }) });
  tests.push({ name: 'POST short name', expect: 400, result: await run('POST', '/api/users', { name: 'A', email: 'a@b.com' }) });
  tests.push({ name: 'POST bad role', expect: 400, result: await run('POST', '/api/users', { name: 'Test', email: 't@t.com', role: 'hacker' }) });

  // Not found
  tests.push({ name: 'GET /api/users/999', expect: 404, result: await run('GET', '/api/users/999') });
  tests.push({ name: 'DELETE /api/users/999', expect: 404, result: await run('DELETE', '/api/users/999') });
  tests.push({ name: 'GET /api/nonexistent', expect: 404, result: await run('GET', '/api/nonexistent') });

  let pass = 0, fail = 0;
  tests.forEach(t => {
    const ok = t.result.status === t.expect;
    const detail = t.result.body ? JSON.stringify(t.result.body).slice(0, 80) : '';
    console.log(`${ok ? 'PASS' : 'FAIL'} ${t.name} → ${t.result.status} (expected ${t.expect}) ${detail}`);
    if (ok) pass++; else fail++;
  });

  console.log(`\nAPI Tests: ${pass}/${tests.length} passed`);
  srv.close();
  process.exit(fail > 0 ? 1 : 0);
});
