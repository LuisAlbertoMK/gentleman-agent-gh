# Gap Analysis: Desktop Application

> Weighted checklist for native desktop applications.

## Layer Weights
UX ████████ 40% · Functional ███████ 30% · Security █████ 20%
Technical ██████ 25% · Ops ███████ 30% · Business ████ 15%

## Functional
- [ ] Offline capability? Conflict resolution on sync?
- [ ] File handling: open/save/recent? autosave? versioning?
- [ ] System integration: file associations? clipboard? drag-drop?
- [ ] Multi-window support? Tabbed interface?
- [ ] Printing? Export to PDF/CSV/Excel?
- [ ] Shortcuts: common operations? configurable?

## Technical
- [ ] Startup time measured? Background loading?
- [ ] Memory management? Leaks tested?
- [ ] Multi-threading: UI non-blocking? background workers?
- [ ] Native APIs: file system? notifications? system tray?
- [ ] Cross-platform? (Win/Mac/Linux) or single?
- [ ] DPI scaling? High-DPI displays?

## Security
- [ ] Auto-update: signed updates? secure channel?
- [ ] Local data: encrypted? Keychain/Windows Credential Manager?
- [ ] Input validation: all entry points?
- [ ] Crash reporting: user consent? PII stripped?
- [ ] Sandboxing? Process isolation?

## UX
- [ ] Install/uninstall: clean? user data preserved on uninstall?
- [ ] First-run experience: tutorial? sample data?
- [ ] System tray: minimize? notifications? quick actions?
- [ ] Multi-monitor: correct behavior on secondary screens?
- [ ] Keyboard: full navigation? shortcuts documented?
- [ ] Dark mode? System theme integration?
- [ ] Undo/redo: consistent across all operations?
- [ ] Progress: long operations show progress + cancel?

## Ops
- [ ] Distribution: App Store? MSI? Package manager? Sideload?
- [ ] Auto-update: silent? delta updates? rollback?
- [ ] Telemetry: usage? crashes? performance? (opt-in)
- [ ] Logs: user-accessible? debug mode? log level config?
- [ ] Support: remote diagnostics? config export?
- [ ] Licensing: activation? offline validation? floating licenses?

## Business
- [ ] Trial/demo: feature-limited? time-limited? fully functional?
- [ ] Pricing: perpetual? subscription? tiered by features?
- [ ] Upgrade path: from free to paid? from old version?
- [ ] Ecosystem: plugins? extensions? marketplace?
- [ ] Support: self-service? community? paid support tiers?
