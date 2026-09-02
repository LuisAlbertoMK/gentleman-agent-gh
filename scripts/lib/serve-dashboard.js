#!/usr/bin/env node
const http = require('http');
const fs = require('fs');
const path = require('path');

const port = 4173;
const root = path.join(__dirname, '..', '..', 'docs', 'dashboard');

const types = {
  '.html': 'text/html; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8'
};

const server = http.createServer((req, res) => {
  let urlPath = decodeURIComponent(req.url.split('?')[0]);
  if (urlPath === '/') urlPath = '/index.html';
  const resolved = path.resolve(path.join(root, urlPath));
  if (resolved !== path.resolve(root) && !resolved.startsWith(path.resolve(root) + path.sep)) {
    res.writeHead(403); res.end('Forbidden'); return;
  }
  const filePath = resolved;
  fs.stat(filePath, (err, stat) => {
    if (err || !stat.isFile()) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('Not found');
      return;
    }
    const ext = path.extname(filePath).toLowerCase();
    const ct = types[ext] || 'application/octet-stream';
    res.writeHead(200, { 'Content-Type': ct });
    const stream = fs.createReadStream(filePath);
    stream.pipe(res);
    res.on('close', () => stream.destroy());
  });
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.warn('Port 4173 in use');
    process.exit(1);
  }
  console.error(err.message);
  process.exit(1);
});

server.listen(port, () => {
  console.log(`Dashboard serving ${root} on http://localhost:${port}/`);
});
