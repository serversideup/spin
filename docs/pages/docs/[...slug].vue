<template>
  <UPage v-if="page">
    <UPageHeader
      :title="page.title"
      :description="page.description"
    />

    <UPageBody>
      <ContentRenderer
        v-if="page"
        :value="page"
      />

      <USeparator v-if="surround?.length" />

      <UContentSurround :surround="surround" />
    </UPageBody>

    <template
      v-if="page?.body?.toc?.links?.length"
      #right
    >
      <UContentToc
        :title="toc?.title"
        :links="page.body?.toc?.links"
      >
        <template
          v-if="toc?.bottom"
          #bottom
        >
          <div
            class="hidden lg:block space-y-6"
            :class="{ '!mt-6': page.body?.toc?.links?.length }"
          >
            <USeparator
              v-if="page.body?.toc?.links?.length"
              type="dashed"
            />

            <UPageLinks
              :title="toc.bottom.title"
              :links="links"
            />

            <USeparator type="dashed" />

            <UPageLinks
              title="Sponsors"
              :links="[{
                label: 'Become a Sponsor',
                icon: 'i-lucide-heart',
                to: 'https://github.com/sponsors/serversideup',
                target: '_blank'
              }]"
            />

            <NuxtLink
              to="https://sevalla.com/?utm_source=spin"
              target="_blank"
            >
              <img src="/images/sponsors/sevalla.svg" alt="Sevalla" class="w-full" />
            </NuxtLink>
          </div>
        </template>
      </UContentToc>
    </template>
  </UPage>
</template>

<script setup lang="ts">
definePageMeta({
  layout: 'docs'
})

const route = useRoute()
const { toc } = useAppConfig()

const { data: page } = await useAsyncData(route.path, () => queryCollection('docs').path(route.path).first())
if (!page.value) {
  throw createError({ statusCode: 404, statusMessage: 'Page not found', fatal: true })
}

const { data: surround } = await useAsyncData(`${route.path}-surround`, () => {
  return queryCollectionItemSurroundings('docs', route.path, {
    fields: ['description']
  })
})

const title = page.value.seo?.title || page.value.title
const description = page.value.seo?.description || page.value.description

useSeoMeta({
  title,
  ogTitle: title,
  description,
  ogDescription: description
})

defineOgImage({
  component: 'DocsImage',
  title: page.value?.title,
  description: page.value?.description
})

const links = computed(() => {
  const linksList = []
  if (toc?.bottom?.edit) {
    linksList.push({
      icon: 'i-lucide-external-link',
      label: 'Edit this page',
      to: `${toc.bottom.edit}/${page?.value?.stem}.${page?.value?.extension}`,
      target: '_blank'
    })
  }

  return [...linksList, ...(toc?.bottom?.links || [])].filter(Boolean)
})
</script>
