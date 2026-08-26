import { defineConfig } from 'vitepress'
export default defineConfig({
  title: "Gentleman Agent GH",
  description: "Mejoras, ciclos y arquitectura",
  ignoreDeadLinks: true,
  markdown: {
    html: false
  },
  themeConfig: {
    nav: [{ text: 'Mejoras', link: '/mejoras/' }],
    sidebar: [{ text: 'Mejoras', items: [{ text: 'Priority Verify', link: '/mejoras/priority-verify-2026-08-27' }] }],
    search: { provider: 'local' }
  }
})