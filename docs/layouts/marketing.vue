<template>
  <div class="w-full flex flex-col">
    <ContentRenderer v-if="page" :value="page" />
  </div>
</template>

<script setup>
const route = useRoute();
const { domain } = useRuntimeConfig().public;

const { data: page } = await useAsyncData(`landing-${route.path}`, () =>
  queryCollection('landing').path(route.path).first()
)

useHead({
  htmlAttrs: {
    lang: 'en'
  },
  bodyAttrs: {
    class: 'antialiased bg-[#1D252C]'
  },
  title: 'Spin: 100% replication from Development to Production - Server Side Up',
  script: [
    {
      src: 'https://f.convertkit.com/ckjs/ck.5.js'
    }
  ]
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
