<template>
    <aside class="hidden xl:block xl:flex-none xl:w-64 2xl:w-72">
        <div class="sticky top-32 h-[calc(100vh-160px)] overflow-y-auto py-8 pl-4">
            <!-- Table of Contents -->
            <div v-if="toc && toc.length > 0" class="mb-8">
                <h3 class="text-sm font-semibold text-white mb-4">Table of Contents</h3>
                <nav>
                    <ul class="space-y-2">
                        <li v-for="link in toc" :key="link.id">
                            <NuxtLink
                                :to="'#' + link.id"
                                @click="scrollTo('#' + link.id)"
                                class="block text-sm text-zinc-400 hover:text-[#1CE783] transition-colors"
                                :class="{
                                    'pl-0': link.depth === 2,
                                    'pl-3': link.depth === 3
                                }">
                                {{ link.text }}
                            </NuxtLink>
                        </li>
                    </ul>
                </nav>
            </div>

            <!-- Community -->
            <div class="mb-8">
                <h3 class="text-sm font-semibold text-white mb-4">Community</h3>
                <nav>
                    <ul class="space-y-2">
                        <li>
                            <a
                                :href="editUrl"
                                target="_blank"
                                rel="noopener noreferrer"
                                class="flex items-center text-sm text-zinc-400 hover:text-[#1CE783] transition-colors">
                                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                                </svg>
                                Edit this page
                                <svg class="w-3 h-3 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                                </svg>
                            </a>
                        </li>
                        <li>
                            <a
                                href="https://github.com/serversideup/spin"
                                target="_blank"
                                rel="noopener noreferrer"
                                class="flex items-center text-sm text-zinc-400 hover:text-[#1CE783] transition-colors">
                                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" />
                                </svg>
                                Star on GitHub
                                <svg class="w-3 h-3 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                                </svg>
                            </a>
                        </li>
                        <li>
                            <a
                                href="https://serversideup.net/subscribe"
                                target="_blank"
                                rel="noopener noreferrer"
                                class="flex items-center text-sm text-zinc-400 hover:text-[#1CE783] transition-colors">
                                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                                </svg>
                                Subscribe
                                <svg class="w-3 h-3 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                                </svg>
                            </a>
                        </li>
                        <li>
                            <a
                                href="https://serversideup.net/professional-support"
                                target="_blank"
                                rel="noopener noreferrer"
                                class="flex items-center text-sm text-zinc-400 hover:text-[#1CE783] transition-colors">
                                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192l-3.536 3.536M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-5 0a4 4 0 11-8 0 4 4 0 018 0z" />
                                </svg>
                                Professional Help
                                <svg class="w-3 h-3 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                                </svg>
                            </a>
                        </li>
                    </ul>
                </nav>
            </div>

            <!-- Sponsors -->
            <div>
                <h3 class="text-sm font-semibold text-white mb-4">Sponsors</h3>
                <a
                    href="https://github.com/sponsors/serversideup"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="flex items-center text-sm text-zinc-400 hover:text-[#1CE783] transition-colors mb-4">
                    <svg class="w-4 h-4 mr-2 text-pink-500" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
                    </svg>
                    Become a Sponsor
                    <svg class="w-3 h-3 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                    </svg>
                </a>
            </div>
        </div>
    </aside>
</template>

<script setup>
const props = defineProps({
    toc: {
        type: Array,
        default: () => []
    },
    contentPath: {
        type: String,
        default: ''
    }
});

const route = useRoute();

// Construct the GitHub edit URL
const editUrl = computed(() => {
    // Convert route path to the content file path
    // e.g., /docs/getting-started/introduction -> content/docs/getting-started/introduction.md
    let path = props.contentPath || route.path;
    
    // Remove leading slash and add content prefix
    if (path.startsWith('/')) {
        path = path.slice(1);
    }
    
    return `https://github.com/serversideup/spin/edit/main/docs/content/${path}.md`;
});

const scrollTo = (id) => {
    document.getElementById(id.replace('#', ''))?.scrollIntoView({ behavior: 'smooth' });
};
</script>
