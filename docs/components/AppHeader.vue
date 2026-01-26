<script setup lang="ts">
import type { ContentNavigationItem } from '@nuxt/content'

const navigation = inject<Ref<ContentNavigationItem[]>>('navigation')

const { header } = useAppConfig()

const logoSrc = computed(() => {
  const logo = header?.logo?.dark || header?.logo?.light
  return logo ? useAssetUrl(logo) : null
})

// Navigation order - same as docs layout
const navigationOrder: Record<string, number> = {
  'installation': 1,
  'getting-started': 2,
  'development-environment': 3,
  'server-configuration': 4,
  'providers': 5,
  'deployment': 6,
  'server-access': 7,
  'advanced': 8,
  'command-reference': 9,
  'community': 11
}

function getSortOrder(item: ContentNavigationItem): number {
  const path = item.path || ''
  const segments = path.split('/')
  const lastSegment = segments[segments.length - 1]
  return navigationOrder[lastSegment] ?? 999
}

function sortNavigation(items: ContentNavigationItem[]): ContentNavigationItem[] {
  return [...items]
    .filter(item => item.path !== '/docs')
    .sort((a, b) => getSortOrder(a) - getSortOrder(b))
    .map(item => ({
      ...item,
      children: item.children ? sortNavigation(item.children) : undefined
    }))
}

const sortedNavigation = computed(() => {
  const navItems = navigation?.value?.[0]?.children || []
  return sortNavigation(navItems)
})
</script>

<template>
  <UHeader
    class="bg-[#1D252C]"
    :ui="{ center: 'flex-1' }"
    :to="header?.to || '/'"
  >
    <template
      v-if="header?.logo?.dark || header?.logo?.light || header?.title"
      #title
    >
      <img
        v-if="logoSrc"
        :src="logoSrc"
        class="w-32 shrink-0"
        :alt="header?.logo?.alt || 'Logo'"
      />

      <span v-else-if="header?.title">
        {{ header.title }}
      </span>
    </template>

    <template #right>
      <UContentSearchButton
        v-if="header?.search"
        class="lg:hidden"
      />

      <UContentSearchButton
        v-if="header?.search"
        :collapsed="false"
        variant="ghost"
        :label="'Search'"
        :size="'xl'"
        :kbds="[]"
        class="hidden lg:flex cursor-pointer font-bold"
      />

      <template v-if="header?.links">
        <UButton
          class="hidden lg:flex font-bold"
          v-for="(link, index) of header.links"
          :key="index"
          v-bind="{ color: 'neutral', variant: 'ghost', ...link }"
        />
      </template>
    </template>

    <template #body>
      <!-- Main navigation links -->
      <nav class="flex flex-col gap-1 mb-6">
        <UButton
          to="/docs"
          variant="ghost"
          color="neutral"
          class="justify-start font-semibold"
          icon="i-lucide-book-open"
          label="Docs"
        />
        <UButton
          to="/hub"
          variant="ghost"
          color="neutral"
          class="justify-start font-semibold"
          icon="i-lucide-rocket"
          label="Hub"
        />
        <UButton
          to="https://serversideup.net/discord"
          target="_blank"
          variant="ghost"
          color="neutral"
          class="justify-start font-semibold"
          icon="i-simple-icons-discord"
          label="Discord"
        />
        <UButton
          to="https://github.com/serversideup/spin"
          target="_blank"
          variant="ghost"
          color="neutral"
          class="justify-start font-semibold"
          icon="i-simple-icons-github"
          label="GitHub"
        />
      </nav>

      <!-- CTA buttons -->
      <div class="flex items-center gap-2 mb-6">
        <UButton
          to="https://github.com/sponsors/serversideup"
          target="_blank"
          color="neutral"
          variant="outline"
          icon="i-lucide-heart"
          label="Sponsor"
        />
        <UButton
          to="/docs"
          color="primary"
          class="bg-[#1CE783] hover:bg-[#1ad677] text-[#151A1F]"
          label="Get Started →"
        />
      </div>

      <!-- Separator -->
      <USeparator class="mb-4" />

      <!-- Docs navigation -->
      <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3 px-2">Documentation</p>
      <UContentNavigation
        highlight
        :navigation="sortedNavigation"
      />
    </template>
  </UHeader>
</template>
