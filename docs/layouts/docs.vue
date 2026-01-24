<script setup lang="ts">
import type { ContentNavigationItem } from '@nuxt/content'

const route = useRoute()
const navigationData = inject<Ref<ContentNavigationItem[]>>('navigation')

/**
 * Recursively checks if a navigation item or any of its children contains the active path
 */
function containsActivePath(item: ContentNavigationItem, activePath: string): boolean {
  if (item._path === activePath || item.path === activePath) {
    return true
  }

  if (item.children && item.children.length > 0) {
    return item.children.some(child => containsActivePath(child, activePath))
  }

  return false
}

/**
 * Processes navigation items to ensure sections are expanded if:
 * 1. They have defaultOpen: true in .navigation.yml, OR
 * 2. They contain the active page
 */
function processNavigation(items: ContentNavigationItem[], activePath: string): ContentNavigationItem[] {
  return items.map(item => {
    const hasActivePath = containsActivePath(item, activePath)

    const processedItem = { ...item }

    if (hasActivePath && item.children && item.children.length > 0) {
      processedItem.defaultOpen = true
    }

    if (processedItem.children && processedItem.children.length > 0) {
      processedItem.children = processNavigation(processedItem.children, activePath)
    }

    return processedItem
  })
}

const navigation = computed(() => {
  const navItems = navigationData?.value?.[0]?.children || []
  return processNavigation(navItems, route.path)
})

useHead({
  bodyAttrs: {
    class: 'antialiased font-inter bg-[#1D252C]'
  }
})
</script>

<template>
  <UContainer>
    <UPage>
      <template #left>
        <UPageAside>
          <UContentNavigation
            highlight
            :navigation="navigation"
          />
        </UPageAside>
      </template>

      <slot />
    </UPage>
  </UContainer>
</template>
