# Gap Analysis: E-commerce

> Online store / marketplace. Weights: UX 40% · Security 30% · Performance 30%.

## 🎨 UI/UX
- [ ] Product discovery: search, filters, categories, recommendations?
- [ ] Product page: images, variants, price, stock, reviews, CTA clear?
- [ ] Cart: persistent? editable? stock-checked? shipping shown?
- [ ] Checkout: guest checkout? progress indicator? saved addresses?
- [ ] Payment: multiple methods? saved cards? 3D Secure?
- [ ] Order confirmation: clear? email notification? tracking?
- [ ] Empty states: cart, orders, wishlist — helpful CTAs?

## 🔒 Security
- [ ] PCI DSS 4.0.1: card data NOT stored? SAQ filled? Tokenization?
- [ ] Payment: iframe/redirect for PCI scope? (NEVER raw card in your server)
- [ ] Auth: MFA for admin? Rate limiting on login?
- [ ] HTTPS + HSTS + CSP? Form CSRF?
- [ ] User data: PII encrypted? GDPR: data export/deletion?

## ⚡ Optimization
- [ ] Product images: optimized? WebP? lazy load? CDN?
- [ ] Bundle: critical path only? Route-based splitting?
- [ ] Search: full-text index? Typo tolerance? Faceted filter performance?
- [ ] Category pages: infinite scroll vs pagination? Performance at scale?

## 📈 Performance
- [ ] Page load: LCP < 2.5s on product/category pages?
- [ ] Search results rendered in < 500ms?
- [ ] Checkout: each step loads in < 1s?
- [ ] Inventory queries: cached? Redis? Stock sync real-time?

## 💾 Resource Usage
- [ ] Product catalog size? DB indexed for search?
- [ ] Session storage? Redis vs database?
- [ ] Image storage: CDN? Auto-resize pipeline? Cost per GB?

## 🚀 Project Velocity
- [ ] Product updates: CMS? Bulk import? API for vendors?
- [ ] Promotions: coupon system? Flash sales? Configurable without deploy?
- [ ] CI/CD: deploy to production without downtime?
- [ ] Release cadence: how often can you ship?

## 📱 Responsive Design
- [ ] Mobile-first: >60% traffic is mobile typically?
- [ ] Touch: swipe for galleries? Pinch to zoom? Tap targets ≥48px?
- [ ] Checkout on mobile: seamless? Apple Pay / Google Pay?
- [ ] Hamburger menu? Bottom nav? Filter drawer?

## 🏗️ Infrastructure
- [ ] Cloud: handles Black Friday / Cyber Monday spikes?
- [ ] Auto-scaling: triggers defined? Tested?
- [ ] CDN: static assets? Product images? Edge caching?
- [ ] Monitoring: conversion rate? Cart abandonment? Error rate?
- [ ] Backup: orders, users, products — RPO/RTO defined?
