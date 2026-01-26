// https://nuxt.com/docs/api/configuration/nuxt-config

// Site URL: SITE_URL > CF_PAGES_URL (CloudFlare preview) > localhost
const siteUrl = process.env.SITE_URL || process.env.CF_PAGES_URL || 'http://localhost:3000'
const basePath = new URL(siteUrl).pathname

export default defineNuxtConfig({
  app: {
    baseURL: basePath
  },

  modules: [
    '@nuxt/ui-pro',
    '@nuxt/content',
    '@vueuse/nuxt',
    'nuxt-og-image',
    '@nuxtjs/plausible',
    '@nuxtjs/sitemap',
    'nuxt-llms',
    './modules/pre-render-raw-routes'
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
    // Reads from site.url automatically
  },

  ogImage: {
    componentDirs: ['~/components/Global/OgImage'],
  },

  plausible: {
    apiHost: 'https://a.521dimensions.com'
  },

  runtimeConfig: {
    public: {
      baseUrl: basePath === '/' ? '' : basePath
    }
  },

  site: {
    url: siteUrl
  },

  llms: {
    domain: siteUrl.endsWith('/') ? siteUrl : `${siteUrl}/`,
    title: 'Spin - Server Side Up',
    description: 'The ultimate open-source solution for managing your server environments from development to production.',
    full: {
      title: 'Spin Documentation - Server Side Up',
      description: 'The ultimate open-source solution for managing your server environments from development to production. Simple, lightweight, and fast. Based on Docker.'
    },
    sections: [
      {
        title: 'Installation',
        contentCollection: 'docs',
        contentFilters: [
          { field: 'path', operator: 'LIKE', value: '/docs/installation%' }
        ]
      },
      {
        title: 'Getting Started',
        contentCollection: 'docs',
        contentFilters: [
          { field: 'path', operator: 'LIKE', value: '/docs/getting-started%' }
        ]
      },
      {
        title: 'Development Environment',
        contentCollection: 'docs',
        contentFilters: [
          { field: 'path', operator: 'LIKE', value: '/docs/development-environment%' }
        ]
      },
      {
        title: 'Server Configuration',
        contentCollection: 'docs',
        contentFilters: [
          { field: 'path', operator: 'LIKE', value: '/docs/server-configuration%' }
        ]
      },
      {
        title: 'Providers',
        contentCollection: 'docs',
        contentFilters: [
          { field: 'path', operator: 'LIKE', value: '/docs/providers%' }
        ]
      },
      {
        title: 'Deployment',
        contentCollection: 'docs',
        contentFilters: [
          { field: 'path', operator: 'LIKE', value: '/docs/deployment%' }
        ]
      },
      {
        title: 'Server Access',
        contentCollection: 'docs',
        contentFilters: [
          { field: 'path', operator: 'LIKE', value: '/docs/server-access%' }
        ]
      },
      {
        title: 'Advanced',
        contentCollection: 'docs',
        contentFilters: [
          { field: 'path', operator: 'LIKE', value: '/docs/advanced%' }
        ]
      },
      {
        title: 'Command Reference',
        contentCollection: 'docs',
        contentFilters: [
          { field: 'path', operator: 'LIKE', value: '/docs/command-reference%' }
        ]
      },
      {
        title: 'Community',
        contentCollection: 'docs',
        contentFilters: [
          { field: 'path', operator: 'LIKE', value: '/docs/community%' }
        ]
      }
    ]
  },

  nitro: {
    prerender: {
      routes: ['/'],
      crawlLinks: true,
      autoSubfolderIndex: false
    }
  }
})
