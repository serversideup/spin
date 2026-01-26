export default defineAppConfig({
  ui: {
    colors: {
      primary: 'emerald',
      neutral: 'zinc'
    },
    header: {
      slots: {
        root: 'bg-[#1D252C]',
        right: 'flex items-center justify-end lg:flex-1 gap-3',
      },
    },
    prose: {
      codeIcon: {
        'compose.yml': 'i-simple-icons-docker',
        'compose.yaml': 'i-simple-icons-docker',
        'docker-compose.yaml': 'i-simple-icons-docker',
        'docker-compose.yml': 'i-simple-icons-docker',
        'dockerfile': 'i-simple-icons-docker',
        'Dockerfile': 'i-simple-icons-docker',
        '.spin.yml': 'i-heroicons-cog-6-tooth',
        'spin.yml': 'i-heroicons-cog-6-tooth',
        'bash': 'i-heroicons-command-line',
        'shell': 'i-heroicons-command-line',
        'Terminal': 'i-heroicons-command-line',
        'yaml': 'i-heroicons-document-text',
        'json': 'i-heroicons-code-bracket',
        'php': 'i-simple-icons-php',
        'javascript': 'i-simple-icons-javascript',
        'typescript': 'i-simple-icons-typescript',
        'vue': 'i-simple-icons-vuedotjs'
      }
    }
  },
  seo: {
    siteName: 'Spin - Server Side Up'
  },
  header: {
    title: 'Spin',
    to: '/',
    logo: {
      alt: 'Spin',
      light: 'images/logos/spin-logo.svg',
      dark: 'images/logos/spin-logo.svg'
    },
    search: true,
    links: [{
      'icon': 'i-lucide-book-open',
      'to': '/docs',
      'aria-label': 'Documentation',
      'label': 'Docs',
      'variant': 'ghost',
      'size': 'xl',
      'class': 'font-bold'
    },{
      'icon': 'i-lucide-rocket',
      'to': '/hub',
      'aria-label': 'Hub',
      'label': 'Hub',
      'variant': 'ghost',
      'size': 'xl',
      'class': 'font-bold'
    },{
      'icon': 'i-simple-icons-discord',
      'to': 'https://serversideup.net/discord',
      'target': '_blank',
      'aria-label': 'Server Side Up on Discord',
      'label': 'Discord',
      'variant': 'ghost',
      'size': 'xl',
      'class': 'font-bold'
    },{
      'icon': 'i-simple-icons-github',
      'to': 'https://github.com/serversideup/spin',
      'target': '_blank',
      'aria-label': 'GitHub',
      'label': 'GitHub',
      'variant': 'ghost',
      'size': 'xl',
      'class': 'font-bold'
    },{
      'trailingIcon': 'i-lucide-heart',
      'label': 'Sponsor',
      'to': 'https://github.com/sponsors/serversideup',
      'target': '_blank',
      'aria-label': 'Sponsor',
      'size': 'xl',
      'variant': 'outline',
      'class': 'font-bold',
    },{
      'trailingIcon': 'i-lucide-arrow-right',
      'label': 'Get Started',
      'to': '/docs',
      'aria-label': 'Get Started',
      'size': 'xl',
      'variant': 'solid',
      'class': 'font-bold bg-emerald-500 text-black hover:bg-emerald-400',
      'color': 'primary',
    }]
  },
  toc: {
    title: 'Table of Contents',
    bottom: {
      title: 'Community',
      edit: 'https://github.com/serversideup/spin/edit/main/docs/content',
      links: [
        {
          icon: 'i-lucide-star',
          label: 'Star on GitHub',
          to: 'https://github.com/serversideup/spin',
          target: '_blank'
        },
        {
          icon: 'i-lucide-bell-ring',
          label: 'Subscribe',
          to: 'https://serversideup.net/subscribe',
          target: '_blank'
        },
        {
          icon: 'i-lucide-handshake',
          label: 'Professional Help',
          to: 'https://serversideup.net/professional-support',
          target: '_blank'
        }
      ]
    }
  }
})
