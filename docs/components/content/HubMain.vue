<template>
  <div class="w-full">
        <!-- Hero Section -->
        <div class="text-center mb-12">
      <h1 class="text-4xl font-bold text-white mb-4">Spin Hub</h1>
      <p class="text-slate-400 text-lg">
        A place to share and build templates together. 
        <NuxtLink to="/docs/advanced/create-your-own-template" class="text-[#1CE783] hover:underline">
          Build your own template →
        </NuxtLink>
        </p>
      </div>

      <!-- Grid of Templates -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <NuxtLink
        v-for="template in templates" 
        :key="template._path"
        :to="template._path"
        class="bg-[#151A1F] rounded-lg overflow-hidden hover:ring-1 hover:ring-[#1CE783] transition-all"
      >
        <div class="aspect-[1.905/1] relative overflow-hidden">
          <img 
            :src="template.image" 
            class="absolute inset-0 w-full h-full object-cover" 
            :alt="template.title" 
          />
        </div>
        <div class="p-4">
          <div class="flex items-center gap-2 mb-2">
            <span 
              :class="[
                'text-xs px-2 py-1 rounded',
                categoryStyles[template.category]?.classes || defaultCategoryStyle
              ]"
            >
              {{ template.category }}
            </span>
          </div>
          <h3 class="text-white font-semibold text-xl mb-2">{{ template.title }}</h3>
          <p class="text-slate-400 text-sm mb-4">{{ template.description }}</p>
          <div class="flex items-center gap-2">
            <img :src="template.authorImage" class="w-8 h-8 rounded-full" :alt="template.author" />
            <div>
              <p class="text-white text-sm">{{ template.author }}</p>
            </div>
          </div>
        </div>
      </NuxtLink>
    </div>
  </div>
</template>

<script setup>
const { data: templates } = await useAsyncData('templates', () => {
  return queryContent('/hub')
    .where({ _path: { $ne: '/hub' } })
    .find()
})

// Category styling configuration
const categoryStyles = {
  'Laravel': {
    classes: 'bg-orange-500/20 text-orange-400'
  },
  'Nuxt': {
    classes: 'bg-green-500/20 text-green-400'
  },
  'Vue': {
    classes: 'bg-emerald-500/20 text-emerald-400'
  },
  'WordPress': {
    classes: 'bg-blue-500/20 text-blue-400'
  },
  'Node.js': {
    classes: 'bg-yellow-500/20 text-yellow-400'
  }
}

// Default style for unconfigured categories
const defaultCategoryStyle = 'bg-slate-500/20 text-slate-400'
</script> 