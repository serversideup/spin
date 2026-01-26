<script setup lang="ts">
import type { ContentNavigationItem } from '@nuxt/content'

const route = useRoute()
const navigationData = inject<Ref<ContentNavigationItem[]>>('navigation')

/**
 * Explicit navigation order - maps path segments to their sort order
 * This ensures numeric prefixes in folder names are respected
 */
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

/**
 * Gets the sort order for a navigation item based on its path
 */
function getSortOrder(item: ContentNavigationItem): number {
  const path = item.path || ''
  const segments = path.split('/')
  const lastSegment = segments[segments.length - 1]
  return navigationOrder[lastSegment] ?? 999
}

/**
 * Recursively sorts navigation items by their defined order
 * Also filters out the index/introduction page since it's accessible via the Docs header link
 */
function sortNavigation(items: ContentNavigationItem[]): ContentNavigationItem[] {
  return [...items]
    .filter(item => item.path !== '/docs') // Hide introduction - accessible via header
    .sort((a, b) => getSortOrder(a) - getSortOrder(b))
    .map(item => ({
      ...item,
      children: item.children ? sortNavigation(item.children) : undefined
    }))
}

/**
 * Recursively checks if a navigation item or any of its children contains the active path
 */
function containsActivePath(item: ContentNavigationItem, activePath: string): boolean {
  // Check if this item matches the active path
  // Use both _path and path properties for compatibility
  if (item._path === activePath || item.path === activePath) {
    return true
  }

  // Check if any children contain the active path
  if (item.children && item.children.length > 0) {
    return item.children.some(child => containsActivePath(child, activePath))
  }

  return false
}

/**
 * Processes navigation items to ensure sections are expanded if:
 * 1. They have defaultOpen: true (or undefined) in .navigation.yml, OR
 * 2. They contain the active page
 */
function processNavigation(items: ContentNavigationItem[], activePath: string): ContentNavigationItem[] {
  return items.map(item => {
    const hasActivePath = containsActivePath(item, activePath)

    // Clone the item to avoid mutating the original
    const processedItem = { ...item }

    // If this item contains the active path, ensure it's expanded
    // Otherwise, preserve the original defaultOpen value
    if (hasActivePath && item.children && item.children.length > 0) {
      processedItem.defaultOpen = true
    }

    // Recursively process children
    if (processedItem.children && processedItem.children.length > 0) {
      processedItem.children = processNavigation(processedItem.children, activePath)
    }

    return processedItem
  })
}

// Process the navigation data: sort by defined order, then expand sections containing the active page
const navigation = computed(() => {
  const navItems = navigationData?.value?.[0]?.children || []
  const sortedItems = sortNavigation(navItems)
  return processNavigation(sortedItems, route.path)
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
