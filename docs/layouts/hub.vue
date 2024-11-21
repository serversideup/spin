<template>
  <div class="w-full min-h-screen bg-[#1D252C]">
    <Head>
      <Link rel="preconnect" href="https://fonts.googleapis.com"/>
      <Link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
      <Link href="https://fonts.googleapis.com/css2?family=Inter:wght@100;200;300;400;500;600;700;800;900&display=swap" rel="stylesheet"/>
    </Head>

    <GlobalServerSideUp/>
    <MarketingHeader/>

    <main class="w-full max-w-7xl mx-auto px-4 py-8">
      <slot />
    </main>

    <Search/>
  </div>
</template>

<script setup>
const route = useRoute();
const { basePath, domain } = useRuntimeConfig().public;

useHead({
  htmlAttrs: {
    lang: 'en'
  },
  bodyAttrs: {
    class: 'antialiased font-inter bg-black'
  },
  link: [
    { rel: 'apple-touch-icon', sizes: '180x180', href: `${basePath !== '/' ? basePath : ''}/images/favicon/apple-touch-icon.png` },
    { rel: 'icon', type: 'image/png', sizes: '32x32', href: `${basePath !== '/' ? basePath : ''}/images/favicon/favicon-32x32.png` },
    { rel: 'icon', type: 'image/png', sizes: '16x16', href: `${basePath !== '/' ? basePath : ''}/images/favicon/favicon-16x16.png` },
    { rel: 'manifest', href: `${basePath !== '/' ? basePath : ''}/images/favicon/site.webmanifest` },
    { rel: 'mask-icon', href: `${basePath !== '/' ? basePath : ''}/images/favicon/safari-pinned-tab.svg`, color: '#5bbad5' }
  ],
  meta: [
    { name: 'msapplication-TileColor', content: '#da532c' },
    { name: 'theme-color', content: '#ffffff' }
  ]
})

useSeoMeta({
  ogLocale: 'en_US',
  ogUrl: domain + basePath + route.path,
  ogType: 'website',
  ogSiteName: 'Server Side Up - Spin',
  ogImage: domain + basePath + '/images/social-image.jpg',
  ogImageWidth: 1200,
  ogImageHeight: 630,
  ogImageType: 'image/png',
  ogDescription: 'The ultimate open-source solution for managing your server environments from development to production. Simple, lightweight, and fast. Based on Docker.',
  ogTitle: 'Server Side Up - Spin',
  twitterCard: 'summary_large_image',
  twitterDescription: 'The ultimate open-source solution for managing your server environments from development to production. Simple, lightweight, and fast. Based on Docker.',
  twitterImage: domain + basePath + '/images/social-image.jpg',
  twitterSite: '@serversideup',
  twitterTitle: 'Server Side Up - Spin'
})
</script> 