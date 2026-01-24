<template>
  <UApp>
    <NuxtLoadingIndicator />

    <GlobalServerSideUp />

    <UBanner
      icon="i-lucide-rocket"
      title="Spin Pro now available with Laravel Horizon, Reverb, and more!"
      to="https://getspin.pro/?ref=spin"
      color="primary"
      class="text-black bg-[#1CE783] hover:bg-[#1ad677]"
      target="_blank"
    />

    <AppHeader />

    <UMain class="bg-[#1D252C]">
      <NuxtLayout>
        <NuxtPage />
      </NuxtLayout>
    </UMain>

    <ClientOnly>
      <LazyUContentSearch
        :files="files"
        :navigation="navigation"
      />
    </ClientOnly>
  </UApp>
</template>

<script setup lang="ts">
const { seo } = useAppConfig()

const { data: navigation } = await useAsyncData('navigation', () => queryCollectionNavigation('docs'))
const { data: files } = useLazyAsyncData('search', () => queryCollectionSearchSections('docs'), {
  server: false
})

useHead({
  meta: [
    { name: 'viewport', content: 'width=device-width, initial-scale=1' }
  ],
  link: [
    { rel: 'apple-touch-icon', sizes: '180x180', href: '/images/favicon/apple-touch-icon.png' },
    { rel: 'icon', type: 'image/png', sizes: '32x32', href: '/images/favicon/favicon-32x32.png' },
    { rel: 'icon', type: 'image/png', sizes: '16x16', href: '/images/favicon/favicon-16x16.png' },
    { rel: 'manifest', href: '/images/favicon/site.webmanifest' },
    { rel: 'mask-icon', href: '/images/favicon/safari-pinned-tab.svg', color: '#5bbad5' }
  ],
  htmlAttrs: {
    lang: 'en',
    class: 'dark'
  }
})

useSeoMeta({
  titleTemplate: `%s - ${seo?.siteName}`,
  ogSiteName: seo?.siteName,
  twitterCard: 'summary_large_image'
})

provide('navigation', navigation)
</script>
