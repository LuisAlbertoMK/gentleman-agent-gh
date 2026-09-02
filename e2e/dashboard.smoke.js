#!/usr/bin/env node
const { spawn } = require('child_process');
const path = require('path');

const PORT = 4173;
const serverPath = path.join(__dirname, '..', 'scripts', 'lib', 'serve-dashboard.js');
const base = `http://localhost:${PORT}`;

function fetchUrl(url) {
  return new Promise((resolve, reject) => {
    const http = require('http');
    http.get(url, (res) => {
      let body = '';
      res.on('data', (c) => body += c);
      res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, body }));
    }).on('error', reject);
  });
}

async function main() {
  const child = spawn(process.execPath, [serverPath], { stdio: ['ignore', 'pipe', 'pipe'] });
  let ready = false;
  child.stdout.on('data', () => { ready = true; });
  child.stderr.on('data', (d) => process.stderr.write(d));
  // wait for server ready
  for (let i = 0; i < 30; i++) {
    await new Promise(r => setTimeout(r, 200));
    try {
      const probe = await fetchUrl(base + '/');
      if (probe.status === 200) { ready = true; break; }
    } catch {}
    if (child.exitCode !== null) break;
  }
  if (!ready) {
    try { child.kill(); } catch {}
    console.error('Server did not start on 4173 (Port 4173 in use or error)');
    process.exit(1);
  }

  let exitCode = 0;
  try {
    // fetch /
    const home = await fetchUrl(base + '/');
    if (home.status !== 200) throw new Error(`GET / status ${home.status} expected 200`);
    if (!home.body.includes('Gentleman Dashboard')) throw new Error('GET / body missing Gentleman Dashboard');
    if (!home.headers['content-type'] || !home.headers['content-type'].includes('text/html')) {
      throw new Error(`GET / content-type ${home.headers['content-type']} expected text/html`);
    }
    console.log('GET / 200 + contains Gentleman Dashboard ✓');

    // fetch /data.json
    const data = await fetchUrl(base + '/data.json');
    if (data.status !== 200) throw new Error(`GET /data.json status ${data.status} expected 200 (run generator)`);
    if (!data.headers['content-type'] || !data.headers['content-type'].includes('application/json')) {
      throw new Error(`GET /data.json content-type ${data.headers['content-type']} expected application/json`);
    }
    let json;
    try { json = JSON.parse(data.body); } catch (e) { throw new Error('data.json invalid JSON: ' + e.message); }
    const keys = Object.keys(json);
    for (const k of ['generatedAt', 'agents', 'skills', 'gate']) {
      if (!keys.includes(k) && !(k === 'gate' && keys.includes('gate')) ) {
        // also allow projectScore/score alias
      }
      if (k === 'generatedAt' && !json.generatedAt) throw new Error('missing generatedAt');
    }
    if (!json.agents || typeof json.agents.total !== 'number' || json.agents.total <= 0) throw new Error(`agents.total invalid: ${JSON.stringify(json.agents)}`);
    if (!json.skills || typeof json.skills.total !== 'number' || json.skills.total <= 0) throw new Error(`skills.total invalid: ${JSON.stringify(json.skills)}`);
    console.log(`GET /data.json 200 JSON valid agents=${json.agents.total} skills=${json.skills.total} ✓`);
  } catch (e) {
    console.error('FAIL:', e.message);
    exitCode = 1;
  } finally {
    try { child.kill(); } catch {}
    // ensure port freed
    await new Promise(r => setTimeout(r, 300));
    try { child.kill('SIGKILL'); } catch {}
  }
  process.exit(exitCode);
}

main().catch(e => { console.error(e); process.exit(1); });
