<script setup lang="ts">
import { useClipboard } from '@vueuse/core'

const route = useRoute()
const toast = useToast()
const { copy, copied } = useClipboard()
const config = useRuntimeConfig()
const isCopying = ref(false)

// Build the full URL to the raw markdown
const site = useSiteConfig();
const mdPath = computed(() => `${site.url}/raw${route.path}.md`)

const items = [
  {
    label: 'Copy Markdown link',
    icon: 'i-lucide-link',
    onSelect() {
      copy(mdPath.value)
      toast.add({
        title: 'Copied to clipboard',
        icon: 'i-lucide-check-circle'
      })
    }
  },
  {
    label: 'View as Markdown',
    icon: 'i-simple-icons-markdown',
    target: '_blank',
    to: `/raw${route.path}.md`
  },
  {
    label: 'Open in ChatGPT',
    icon: 'i-simple-icons-openai',
    target: '_blank',
    to: `https://chatgpt.com/?hints=search&q=${encodeURIComponent(`Read ${mdPath.value} so I can ask questions about it.`)}`
  },
  {
    label: 'Open in Claude',
    icon: 'i-simple-icons-anthropic',
    target: '_blank',
    to: `https://claude.ai/new?q=${encodeURIComponent(`Read ${mdPath.value} so I can ask questions about it.`)}`
  }
]

async function copyPage() {
  isCopying.value = true
  try {
    const content = await $fetch<string>(`/raw${route.path}.md`)
    copy(content)
    toast.add({
      title: 'Page copied to clipboard',
      icon: 'i-lucide-check-circle'
    })
  } catch (e) {
    toast.add({
      title: 'Failed to copy page',
      icon: 'i-lucide-x-circle',
      color: 'error'
    })
  }
  isCopying.value = false
}
</script>

<template>
  <UButtonGroup>
    <UButton
      label="Copy page"
      :icon="copied ? 'i-lucide-copy-check' : 'i-lucide-copy'"
      color="neutral"
      variant="outline"
      :loading="isCopying"
      :ui="{
        leadingIcon: [copied ? 'text-primary' : 'text-neutral', 'size-3.5']
      }"
      @click="copyPage"
    />
    <UDropdownMenu
      :items="items"
      :content="{
        align: 'end',
        side: 'bottom',
        sideOffset: 8
      }"
      :ui="{
        content: 'w-48'
      }"
    >
      <UButton
        icon="i-lucide-chevron-down"
        size="sm"
        color="neutral"
        variant="outline"
      />
    </UDropdownMenu>
  </UButtonGroup>
</template>
