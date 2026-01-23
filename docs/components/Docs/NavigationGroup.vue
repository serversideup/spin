<template>
    <li class="relative mt-6" v-if="group.path != '/docs'">
        <h2 class="text-xs font-semibold text-white">
            {{ group.title }}
        </h2>

        <div class="relative mt-3 pl-2">
            <div class="absolute inset-y-0 left-2 w-px bg-white/5"></div>

            <ul role="list" class="border-l border-white/20">
                <li v-for="link in group.children"
                    :key="link.path"
                    :class="{
                        'rounded-lg bg-white/5 -ml-4 pl-4': link.path === route.path
                    }">
                        <NuxtLink
                            :to="link.path"
                            :data-attr-link-id="link.path"
                            class="flex justify-between gap-2 py-1 pr-3 text-sm transition"
                            :class="{
                                'text-white': link.path === route.path,
                                'text-zinc-400 hover:text-white': link.path != route.path
                            }">

                                <span class="pl-4 truncate"
                                    :class="{
                                        '-ml-[1px] border-l border-[#1CE783]': link.path === route.path
                                    }">{{ link.title }}</span>

                        </NuxtLink>
                        <ul v-if="link.path == route.path && toc?.links">
                            <li v-for="( tocLink, linkIndex ) in toc.links"
                                :key="'link-'+linkIndex">
                                    <NuxtLink
                                        @click="scrollTo('#'+tocLink.id)"
                                        :to="'#'+tocLink.id"
                                        class="flex justify-between gap-2 py-1 pr-3 text-sm transition pl-7 text-zinc-400 hover:text-white">
                                            <span class="truncate">{{ tocLink.text }}</span>
                                    </NuxtLink>
                            </li>
                        </ul>
                </li>
            </ul>
        </div>
    </li>
</template>

<script setup>
const props = defineProps(['group', 'toc']);
const route = useRoute();

const scrollTo = (id) => {
    document.getElementById(id.replace('#', ''))?.scrollIntoView({ behavior: 'smooth' })
}
</script>
