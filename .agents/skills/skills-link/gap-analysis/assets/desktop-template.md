# Gap Analysis: Desktop App

> Native/electron desktop application. Weights: UX 40% · Functional 30% · Ops 30%.

## 🎨 UI/UX
- [ ] Native OS conventions: menus, shortcuts, drag-drop, system tray?
- [ ] Multi-window: management? State persistence? Focus handling?
- [ ] Install/uninstall experience: clean? User data preserved on uninstall?
- [ ] Offline: full functionality without internet? Sync when online?
- [ ] Keyboard shortcuts: comprehensive? Customizable? Discoverable?
- [ ] Dark/light mode: OS preference respected?

## 🔒 Security
- [ ] Auto-updates: signed? Verified? Rollback safe?
- [ ] Local storage: user data encrypted at rest?
- [ ] Process isolation: sandbox? Separate renderer?
- [ ] Telemetry: what's collected? Opt-out? GDPR compliant?
- [ ] File access: restricted to app data? Path traversal prevented?

## ⚡ Optimization
- [ ] Startup time: cold < 3s? Background preload?
- [ ] Memory: idle memory < 200MB? Leak detection?
- [ ] CPU: background work throttled? Idle usage < 5%?
- [ ] Installer size: < 200MB? Compression? On-demand modules?

## 📈 Performance
- [ ] UI responsiveness: input lag < 16ms? Main thread non-blocking?
- [ ] Large file operations: async? Progress bar? Cancelable?
- [ ] Database queries (local): SQLite performance? Indexes?
- [ ] Search: full-text across local data? < 1s results?

## 💾 Resource Usage
- [ ] Memory: profiling done? Heap snapshots? No leaks?
- [ ] Disk: cache management? User can clear? Data size monitored?
- [ ] CPU: background tasks? Throttled when minimized?

## 🚀 Project Velocity
- [ ] Dev loop: hot reload? Build time < 5min?
- [ ] CI/CD: build for Win/Mac/Linux? Code signing? Notarization?
- [ ] Versioning: semantic? Changelog maintained?
- [ ] Auto-update: rollout? Staged? Kill switch?

## 📱 Responsive Design
- [ ] Window resizing: layout adapts? Minimum size defined?
- [ ] HiDPI/Retina: assets for 2x/3x? UI scales correctly?
- [ ] Multi-monitor: window position saved? DPI per monitor?

## 🏗️ Infrastructure
- [ ] Distribution: store (MS Store, Mac App Store) vs direct download?
- [ ] Crash reporting: symbolicated? Grouped by stack trace?
- [ ] Logging: user can access? Log level configurable?
- [ ] Analytics: feature usage? Error rates? Performance metrics?
- [ ] Licensing: license key validation? Offline activation?
