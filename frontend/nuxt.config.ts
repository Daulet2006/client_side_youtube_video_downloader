export default defineNuxtConfig({
  compatibilityDate: '2026-08-02',
  devtools: { enabled: false },
  css: ['~/assets/css/main.css'],
  runtimeConfig: {
    public: {
      apiBase: process.env.NUXT_PUBLIC_API_BASE || 'http://localhost:8000'
    }
  },
  typescript: {
    strict: true,
    typeCheck: false
  }
})
