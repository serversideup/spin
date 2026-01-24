<template>
  <NuxtLayout name="docs">
    <UPageHeader
      :title="page?.title"
      :description="page?.description"
    />

    <UPageBody prose>
      <ContentRenderer v-if="page" :value="page" />
    </UPageBody>

    <template #right>
      <UContentToc
        v-if="page?.body?.toc?.links?.length"
        :links="page.body.toc.links"
      />
    </template>
  </NuxtLayout>
</template>

<script setup lang="ts">
definePageMeta({
  layout: false
})

const route = useRoute()

const { data: page } = await useAsyncData(`docs-${route.path}`, () =>
  queryCollection('docs').path(route.path).first()
)

useSeoMeta({
  title: page.value?.title,
  description: page.value?.description
})
</script>
