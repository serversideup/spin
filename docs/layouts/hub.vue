<template>
  <main class="w-full max-w-7xl mx-auto px-4 py-8">
    <ContentRenderer v-if="page" :value="page" />
  </main>
</template>

<script setup>
const route = useRoute();
const { domain } = useRuntimeConfig().public;

const { data: page } = await useAsyncData(`hub-landing-${route.path}`, () =>
  queryCollection('landing').path(route.path).first()
)

useHead({
  htmlAttrs: {
    lang: 'en'
  },
  bodyAttrs: {
    class: 'antialiased font-inter bg-[#1D252C]'
  }
})

useSeoMeta({
  ogLocale: 'en_US',
  ogUrl: domain + route.path,
  ogType: 'website',
  ogSiteName: 'Server Side Up - Spin',
  ogImage: domain + '/images/social-image.jpg',
  ogImageWidth: 1200,
  ogImageHeight: 630,
  ogImageType: 'image/png',
  ogDescription: 'The ultimate open-source solution for managing your server environments from development to production. Simple, lightweight, and fast. Based on Docker.',
  ogTitle: 'Server Side Up - Spin',
  twitterCard: 'summary_large_image',
  twitterDescription: 'The ultimate open-source solution for managing your server environments from development to production. Simple, lightweight, and fast. Based on Docker.',
  twitterImage: domain + '/images/social-image.jpg',
  twitterSite: '@serversideup',
  twitterTitle: 'Server Side Up - Spin'
})
</script>
