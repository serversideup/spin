// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  app: {
    baseURL: process.env.NUXT_APP_BASE_URL || '/'
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
      domain: process.env.TOP_LEVEL_DOMAIN || 'https://serversideup.net',
      baseUrl: process.env.NUXT_PUBLIC_BASE_URL || ''
    }
  },

  site: {
    url: process.env.SITE_URL || 'https://serversideup.net',
  },

  llms: {
    domain: 'https://serversideup.net/open-source/spin/',
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
  }
})
