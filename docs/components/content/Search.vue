<template>
    <UModal v-model:open="show" :ui="{ width: 'max-w-3xl' }">
        <template #content>
            <div class="divide-y divide-gray-500 divide-opacity-20 bg-black rounded-xl overflow-hidden">
                <div class="relative">
                    <UIcon name="i-heroicons-magnifying-glass" class="pointer-events-none absolute left-4 top-3.5 h-5 w-5 text-gray-500" />
                    <input
                        v-model="query"
                        @input="search()"
                        class="h-12 w-full border-0 bg-transparent pl-11 pr-4 text-white outline-none sm:text-sm"
                        placeholder="Search..."
                    />
                </div>

                <div class="h-80 scroll-py-2 divide-y divide-gray-500 divide-opacity-20 overflow-y-auto">
                    <div v-if="query === ''" class="p-2">
                        <div v-for="group in links" :key="group.title" class="border-b border-gray-500 pb-2">
                            <h2 class="mb-2 mt-4 px-3 text-xs font-semibold text-gray-200">{{ group.title }}</h2>
                            <ul class="text-sm text-gray-400">
                                <li
                                    v-for="link in group.links"
                                    :key="link.id"
                                    @click="onSelect(link)"
                                    class="flex cursor-pointer select-none items-center rounded-md px-3 py-2 hover:bg-gray-800 hover:text-white"
                                >
                                    <component :is="link.icon" class="h-6 w-6 flex-none text-gray-500" />
                                    <span class="ml-3 flex-auto truncate">{{ link.name }}</span>
                                </li>
                            </ul>
                        </div>
                    </div>

                    <div v-if="query !== '' && results.length > 0" class="p-2">
                        <h2 class="mb-2 mt-4 px-3 text-xs font-semibold text-gray-200">Results</h2>
                        <ul class="text-sm text-gray-400">
                            <li
                                v-for="link in results"
                                :key="link.id"
                                @click="onSelect(link)"
                                class="flex cursor-pointer select-none items-center rounded-md px-3 py-2 hover:bg-gray-800 hover:text-white"
                            >
                                <UIcon name="i-heroicons-document-text" class="h-5 w-5 flex-none mr-1 text-gray-500" />
                                <span class="w-[calc(100%-50px)] truncate text-sm" v-html="buildSearchResultTitle(link)"></span>
                            </li>
                        </ul>
                    </div>

                    <div v-if="query !== '' && results.length === 0 && !searching" class="px-6 py-14 text-center sm:px-14">
                        <UIcon name="i-heroicons-folder" class="mx-auto h-6 w-6 text-gray-500" />
                        <p class="mt-4 text-sm text-gray-200">We couldn't find any results with that term. Please try again.</p>
                    </div>
                </div>
            </div>
        </template>
    </UModal>
</template>

<script setup>
import hotkeys from 'hotkeys-js';
import DiscordIcon from './DiscordIcon.vue';
import DocsIcon from './DocsIcon.vue';
import HeartIcon from './HeartIcon.vue';
import GitHubIcon from './GitHubIcon.vue';

const show = ref(false);

if (import.meta.client) {
    hotkeys('ctrl+k,command+k', (event, handler) => {
        show.value = true;
        event.preventDefault();
    });
}

const docsEventBus = useEventBus('spin-docs-event-bus');
const listener = (event) => {
    if (event === 'prompt-search') {
        show.value = true;
    }
}
docsEventBus.on(listener);

const defaultLinks = [
    { name: 'Docs', id: '/docs', icon: DocsIcon },
    { name: 'Discord', id: 'https://serversideup.net/discord', icon: DiscordIcon, external: true },
    { name: 'GitHub', id: 'https://github.com/serversideup', icon: GitHubIcon, external: true },
    { name: 'Sponsor', id: 'https://github.com/sponsors/serversideup', icon: HeartIcon, external: true },
]

const { data: navigation } = await useAsyncData('navigation', () =>
    queryCollectionNavigation('docs')
)

const links = computed(() => {
    let computedLinks = [];

    computedLinks.push({
        'title': 'Links',
        'links': defaultLinks
    });

    if (navigation.value && navigation.value.length > 0) {
        computedLinks.push({
            'title': navigation.value[0].title,
            'links': [{
                name: navigation.value[0].title,
                id: navigation.value[0].path,
                icon: DocsIcon
            }]
        });

        navigation.value[0].children?.forEach((link) => {
            if (link.children) {
                let childLinks = [];

                link.children.forEach((child) => {
                    childLinks.push({
                        name: child.title,
                        id: child.path,
                        icon: DocsIcon
                    });
                });

                computedLinks.push({
                    'title': link.title,
                    'links': childLinks
                });
            }
        });
    }

    return computedLinks;
})

const query = ref('')
const results = ref([])
const searching = ref(false)

const search = async () => {
    if (!query.value) {
        results.value = []
        return
    }

    searching.value = true
    try {
        const searchResults = await queryCollectionSearchSections('docs', {
            search: query.value
        })
        results.value = searchResults.map(item => ({
            id: item.page?.path || item.id,
            title: item.page?.title || item.title,
            content: item.content || '',
            titles: item.titles || []
        }))
    } catch (error) {
        console.error('Search error:', error)
        results.value = []
    }
    searching.value = false
}

const buildSearchResultTitle = (link) => {
    let highlightedContent = link.content?.replace(new RegExp(query.value, 'gi'), `<span class="bg-[#1CE783] text-white">${query.value}</span>`) || '';

    let title = `<span class="text-[#E2E8F0]">${link.titles?.length > 0 ? link.titles.join(' > ') + ' > ' : ''}${link.title} </span><span class="text-[10px] hidden md:inline">${highlightedContent}</span>`;
    return title;
}

const onSelect = (link) => {
    show.value = false;
    if (link.external) {
        window.open(link.id, '_blank');
        return;
    } else {
        navigateTo(link.id);
    }
}
</script>
