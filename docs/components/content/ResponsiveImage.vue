<template>
    <img :src="( basePath != '/' ? basePath : '' )+src" :alt="alt" :style="{
        maxWidth: maxWidth + 'px',
        maxHeight: maxHeight + 'px'
    }"
    class="mx-auto" />
</template>

<script setup>
const { basePath, domain } = useRuntimeConfig().public;

const props = defineProps({
    src: {
        type: String,
        required: true
    },
    maxWidth: {
        type: Number,
        default: 800
    },
    maxHeight: {
        type: Number,
        default: 600
    },
    alt: {
        type: String,
        default: ''
    }
});
</script>