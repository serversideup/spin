<template>
  <UContainer>
    <div class="py-4 text-gray-400">
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
            <span class="text-white">{{ page?.title }}</span>
          </li>
        </ol>
      </nav>
    </div>

    <main class="py-8">
      <article class="prose prose-invert max-w-none">
        <ContentRenderer v-if="page" :value="page" />
      </article>
    </main>
  </UContainer>
</template>

<script setup>
const route = useRoute();
const { domain } = useRuntimeConfig().public;

const { data: page } = await useAsyncData(`hub-${route.path}`, () =>
  queryCollection('hub').path(route.path).first()
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
  ogTitle: page.value?.title,
  ogDescription: page.value?.description,
  twitterCard: 'summary_large_image',
  twitterDescription: page.value?.description,
  twitterSite: '@serversideup',
  twitterTitle: page.value?.title
})

defineOgImage({
  component: 'DocsImage',
  title: page.value?.title,
  description: page.value?.description
});
</script>
