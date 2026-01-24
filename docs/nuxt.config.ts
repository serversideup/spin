// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  modules: [
    '@nuxt/ui-pro',
    '@nuxt/content',
    '@vueuse/nuxt',
    'nuxt-og-image',
    '@nuxtjs/plausible',
    '@nuxtjs/sitemap'
  ],

  future: {
    compatibilityVersion: 4
  },

  compatibilityDate: '2025-01-01',

  ui: {
    colorMode: false,
    icons: ['heroicons', 'simple-icons', 'lucide']
  },

  colorMode: {
    preference: 'dark',
    fallback: 'dark'
  },

  content: {
    build: {
      markdown: {
        highlight: {
          theme: { default: 'github-dark', dark: 'github-dark' },
          langs: ['dockerfile', 'ini', 'bash', 'yaml', 'json', 'typescript', 'javascript', 'php', 'vue', 'html', 'css', 'shell']
        }
      }
    }
  },

  css: [
    '~/assets/css/tailwind.css'
  ],

  sitemap: {
    siteUrl: 'https://serversideup.net/open-source/spin'
  },

  ogImage: {
    componentDirs: ['~/components/Global/OgImage'],
  },

  plausible: {
    apiHost: 'https://a.521dimensions.com'
  },

  runtimeConfig: {
    public: {
      domain: process.env.TOP_LEVEL_DOMAIN || 'https://serversideup.net'
    }
  },

  site: {
    url: process.env.SITE_URL || 'https://serversideup.net',
  }
})
