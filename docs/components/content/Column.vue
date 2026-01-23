<template>
    <div class="[&>:first-child]:mt-0 [&>:last-child]:mb-0"
        :class="{
            'xl:sticky xl:top-24': sticky
        }">
        <slot />
    </div>
</template>

<script setup>
const props = defineProps({
    sticky: {
        default: false
    }
})
</script>