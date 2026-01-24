<template>
  <div>
    <UPageHeader
      :title="page?.title"
      :description="page?.description"
    />

    <UPageBody prose>
      <ContentRenderer v-if="page" :value="page" />
    </UPageBody>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  layout: 'docs'
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
