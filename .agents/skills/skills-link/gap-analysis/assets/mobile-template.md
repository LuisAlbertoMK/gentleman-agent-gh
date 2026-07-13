# Gap Analysis: Mobile App

> Native/cross-platform mobile application. Weights: UX 45% · Performance 35% · Resource 20%.

## 🎨 UI/UX
- [ ] Platform conventions: navigation patterns, gestures, typography?
- [ ] Onboarding: first-run experience? Permission requests timed well?
- [ ] Loading states: skeleton screens? Pull-to-refresh? Infinite scroll?
- [ ] Error states: offline detection? Retry? Snackbar/banner?
- [ ] Touch: swipe, long-press, pinch — appropriate feedback?
- [ ] Notifications: push? Local? Categories? Deep linking?

## 🔒 Security
- [ ] Local storage: sensitive data encrypted? Keychain/Keystore used?
- [ ] Network: certificate pinning? HTTPS enforced?
- [ ] Auth: biometric? OAuth2? Token storage secure?
- [ ] API: rate limiting handled client-side? Retry with backoff?
- [ ] Deep linking: validated? Open redirects prevented?

## ⚡ Optimization
- [ ] App size: APK/IPA size? App thinning? On-demand resources?
- [ ] Images: cached? Resized per device? Progressive loading?
- [ ] Bundle: code splitting? Dynamic imports? Tree shaking?

## 📈 Performance
- [ ] Startup time: cold start < 2s? Warm start < 1s?
- [ ] Scroll: 60fps? RecyclerView/FlatList optimization?
- [ ] Network: request batching? Prefetching? Offline-first?
- [ ] Animations: 60fps? GPU accelerated? No jank?
- [ ] Memory: profiling done? No leaks? < 200MB peak?

## 💾 Resource Usage
- [ ] Battery: background work minimized? Push vs polling?
- [ ] Storage: cache size managed? User can clear? DB size?
- [ ] Network: data usage optimized for metered connections?
- [ ] Memory: images deallocated off-screen? Profiled?

## 🚀 Project Velocity
- [ ] Dev loop: hot reload? Fast build (< 5 min)?
- [ ] CI/CD: build→test→deploy to TestFlight/Play Console?
- [ ] Code push: Over-the-air updates? (CodePush/Expo Updates)
- [ ] Test automation: device farm? E2E tests on real devices?

## 📱 Responsive Design
- [ ] Device sizes: tested on small (SE), medium, large, tablet?
- [ ] Orientation: portrait and landscape supported?
- [ ] Dynamic type: font scaling? Accessibility sizes?
- [ ] Dark mode? System preference respected?

## 🏗️ Infrastructure
- [ ] Crash reporting: real-time? Symbolicated? Grouped?
- [ ] Analytics: events tracked? Funnels? User properties?
- [ ] Remote config: feature flags? A/B testing?
- [ ] API: backend scaling for mobile traffic? Push notification service?
- [ ] App review: CI checks for App Store/Play Store guidelines?
