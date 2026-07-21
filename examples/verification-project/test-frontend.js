/**
 * HTML + React verification
 * Run: node examples/verification-project/test-frontend.js
 */
const fs = require('fs');
const path = require('path');

const results = [];

// ── HTML Landing Page ──
const html = fs.readFileSync(path.join(__dirname, 'public/index.html'), 'utf8');

// Structural
results.push(['HTML has <!DOCTYPE>', /<!DOCTYPE html>/i.test(html)]);
results.push(['HTML has lang attribute', /<html\s+lang="en">/.test(html)]);
results.push(['HTML has meta charset', /charset="UTF-8"/.test(html)]);
results.push(['HTML has viewport meta', /name="viewport"/.test(html)]);
results.push(['HTML has meta description', /name="description"/.test(html)]);
results.push(['HTML has title', /<title>/.test(html)]);

// Accessibility
results.push(['HTML has focus-visible', /:focus-visible/.test(html)]);
results.push(['HTML has prefers-reduced-motion', /prefers-reduced-motion/.test(html)]);
results.push(['HTML uses semantic tags', /<header|<section|<footer|<article/.test(html)]);
results.push(['HTML has CTA link', /<a.*class="cta"/.test(html)]);

// CSS best practices
results.push(['HTML uses design tokens (var)', /var\(--/.test(html)]);
results.push(['HTML uses OKLCH colors', /oklch/.test(html)]);
results.push(['HTML has responsive grid', /grid-template-columns.*repeat/.test(html)]);
results.push(['HTML has clamp for fluid typography', /clamp/.test(html)]);
results.push(['HTML has transition', /transition/.test(html)]);

// No external dependencies
results.push(['HTML has no external CSS links', !/<link.*rel="stylesheet".*href="http/.test(html)]);
results.push(['HTML has no external JS', !/<script.*src="http/.test(html)]);

// ── React Component ──
const jsx = fs.readFileSync(path.join(__dirname, 'src/components/UserCard.jsx'), 'utf8');

results.push(['JSX has JSDoc @param', /@param/.test(jsx)]);
results.push(['JSX has @typedef', /@typedef/.test(jsx)]);
results.push(['JSX uses semantic HTML', /<article|<section|<time/.test(jsx)]);
results.push(['JSX has aria-label', /aria-label/.test(jsx)]);
results.push(['JSX has role attribute', /role=/.test(jsx)]);
results.push(['JSX has mailto link', /mailto:/.test(jsx)]);
results.push(['JSX has dateTime attr', /dateTime=/.test(jsx)]);
results.push(['JSX exports named + default', /export\s+function|export\s+default/.test(jsx)]);
results.push(['JSX has OKLCH colors', /oklch/.test(jsx)]);
results.push(['JSX has empty state', /No users found/.test(jsx)]);
results.push(['JSX uses grid layout', /gridTemplateColumns|grid-template/.test(jsx)]);

// ── DB Schema ──
const schema = fs.readFileSync(path.join(__dirname, 'src/db/schema.js'), 'utf8');

results.push(['Schema has Prisma model User', /model User/.test(schema)]);
results.push(['Schema has Prisma model Post', /model Post/.test(schema)]);
results.push(['Schema has Prisma model Tag', /model Tag/.test(schema)]);
results.push(['Schema has Prisma model Profile', /model Profile/.test(schema)]);
results.push(['Schema has enum Role', /enum Role/.test(schema)]);
results.push(['Schema has @@map', /@@map/.test(schema)]);
results.push(['Schema has @@index', /@@index/.test(schema)]);
results.push(['Schema has @unique', /@unique/.test(schema)]);
results.push(['Schema has @default', /@default/.test(schema)]);
results.push(['Schema has relation fields', /@relation/.test(schema)]);
results.push(['Schema has soft delete', /deletedAt/.test(schema)]);
results.push(['Schema repo has JSDoc @param', /@param/.test(schema)]);
results.push(['Schema repo has try/catch', /try \{/.test(schema)]);
results.push(['Schema repo has findByEmail', /findByEmail/.test(schema)]);
results.push(['Schema repo has pagination', /pageSize|skip.*take/.test(schema)]);
results.push(['Schema PostRepo has tags', /connectOrCreate/.test(schema)]);

// ── API Client ──
const client = fs.readFileSync(path.join(__dirname, 'src/api/client.js'), 'utf8');

results.push(['Client has JSDoc @param', /@param/.test(client)]);
results.push(['Client has JSDoc @returns', /@returns/.test(client)]);
results.push(['Client has custom ApiError', /class ApiError/.test(client)]);
results.push(['Client has AbortController', /AbortController|signal/.test(client)]);
results.push(['Client has retry logic', /withRetry/.test(client)]);
results.push(['Client has backoff', /backoff/.test(client)]);
results.push(['Client skips retry on 4xx', /err\.status >= 400/.test(client)]);
results.push(['Client has 204 handling', /204/.test(client)]);
results.push(['Client has content-type header', /Content-Type/.test(client)]);
results.push(['Client exports named api', /export.*api|module\.exports/.test(client)]);

// Print
let pass = 0, fail = 0;
results.forEach(([name, ok]) => {
  console.log(`${ok ? 'PASS' : 'FAIL'} ${name}`);
  if (ok) pass++; else fail++;
});

console.log(`\nFrontend Verification: ${pass}/${results.length} passed`);
process.exit(fail > 0 ? 1 : 0);
