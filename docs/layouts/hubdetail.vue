<template>
  <div class="w-full min-h-screen bg-[#1D252C]">
      <Head>
          <Link rel="preconnect" href="https://fonts.googleapis.com"/>
          <Link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
          <Link href="https://fonts.googleapis.com/css2?family=Inter:wght@100;200;300;400;500;600;700;800;900&display=swap" rel="stylesheet"/>
          <Link rel="apple-touch-icon" sizes="180x180" :href="( basePath != '/' ? basePath : '' )+'/images/favicon/apple-touch-icon.png'"/>
          <Link rel="icon" type="image/png" sizes="32x32" :href="( basePath != '/' ? basePath : '' )+'/images/favicon/favicon-32x32.png'"/>
          <Link rel="icon" type="image/png" sizes="16x16" :href="( basePath != '/' ? basePath : '' )+'/images/favicon/favicon-16x16.png'"/>
          <Link rel="manifest" :href="( basePath != '/' ? basePath : '' )+'/images/favicon/site.webmanifest'"/>
          <Link rel="mask-icon" :href="( basePath != '/' ? basePath : '' )+'/images/favicon/safari-pinned-tab.svg'" color="#5bbad5"/>
          <Meta name="msapplication-TileColor" content="#da532c"/>
          <Meta name="theme-color" content="#ffffff"/>
      </Head>

      <GlobalServerSideUp/>

      <MarketingHeader/>

      <div class="container mx-auto">
        <div class="px-4 sm:px-6 lg:px-8 py-4 text-gray-400">
          <nav class="flex" aria-label="Breadcrumb">
            <ol class="flex items-center space-x-2">
              <li>
                <NuxtLink to="/hub" class="hover:text-white">Explore</NuxtLink>
              </li>
              <li class="flex items-center">
                <svg class="h-5 w-5 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z" clip-rule="evenodd" />
                </svg>
              </li>
              <li>
                <span class="text-white">{{ title }}</span>
              </li>
            </ol>
          </nav>
        </div>
      </div>

      <div class="lg:flex lg:w-screen lg:h-[calc(100vh-167px)]">
          <div class="relative px-4 pt-5 sm:px-6 lg:overflow-y-scroll lg:flex-1 lg:px-8">
              <main class="py-8 scroll-smooth" id="content-container">
                  <ContentDoc
                      class="prose prose-invert" 
                      tag="article" />
              </main>

              <DocsFooter/>
          </div>
      </div>

      <Search/>
  </div>
</template>

<script setup>
const route = useRoute();
const { basePath, domain } = useRuntimeConfig().public;
const { data: page } = await useAsyncData('page', () => queryContent(useRoute().path).findOne())
const title = computed(() => page.value?.title || '')

useHead({
  htmlAttrs: {
      lang: 'en'
  },
  bodyAttrs: {
      class: 'antialiased font-inter bg-black'
  }
})

useSeoMeta({
  ogLocale: 'en_US',
  ogUrl: domain+basePath+route.path,
  ogType: 'website',
  ogSiteName: 'Server Side Up - Spin',
  ogTitle: page.value?.head.title,
  ogDescription: page.value.description,
  twitterCard: 'summary_large_image',
  twitterDescription: page.value?.description,
  twitterSite: '@serversideup',
  twitterTitle: page.value?.head.title
})

defineOgImage({
  component: 'DocsImage',
  title: page.value.title,
  description: page.value.description
});
</script>