<template>
    <div class="w-full min-h-screen bg-[#1D252C] flex items-center justify-center">
        <div class="text-center">
            <h1 class="text-6xl font-bold text-white mb-4">{{ error?.statusCode || 404 }}</h1>
            <p class="text-xl text-zinc-400 mb-8">{{ error?.message || 'Page not found' }}</p>
            <NuxtLink to="/" class="px-6 py-3 bg-[#1CE783] text-black font-semibold rounded-lg hover:bg-[#15b86a] transition">
                Go Home
            </NuxtLink>
        </div>
    </div>
</template>

<script setup>
defineProps({
    error: Object
})
</script>
