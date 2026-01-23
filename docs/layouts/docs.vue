<template>
    <div class="w-full min-h-screen bg-[#1D252C]">
        <Head>
            <Link rel="preconnect" href="https://fonts.googleapis.com"/>
            <Link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
            <Link href="https://fonts.googleapis.com/css2?family=Inter:wght@100;200;300;400;500;600;700;800;900&display=swap" rel="stylesheet"/>
            <Link rel="apple-touch-icon" sizes="180x180" href="/images/favicon/apple-touch-icon.png"/>
            <Link rel="icon" type="image/png" sizes="32x32" href="/images/favicon/favicon-32x32.png"/>
            <Link rel="icon" type="image/png" sizes="16x16" href="/images/favicon/favicon-16x16.png"/>
            <Link rel="manifest" href="/images/favicon/site.webmanifest"/>
            <Link rel="mask-icon" href="/images/favicon/safari-pinned-tab.svg" color="#5bbad5"/>
            <Meta name="msapplication-TileColor" content="#da532c"/>
            <Meta name="theme-color" content="#ffffff"/>
        </Head>

        <GlobalServerSideUp/>

        <MarketingHeader/>

        <div class="max-w-8xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="lg:flex">
                <!-- Left Sidebar -->
                <div class="hidden lg:block lg:flex-none lg:w-72 xl:w-80">
                    <div class="sticky top-32 h-[calc(100vh-160px)] overflow-y-auto py-8 pr-4">
                        <DocsNavigation/>
                    </div>
                </div>

                <!-- Main content -->
                <div class="min-w-0 flex-1 lg:pl-8 lg:pr-0 xl:px-16">
                    <main class="py-8 scroll-smooth" id="content-container">
                        <article class="prose prose-invert max-w-3xl">
                            <ContentRenderer v-if="page" :value="page" />
                        </article>

                        <DocsFooter class="max-w-3xl"/>
                    </main>
                </div>

                <!-- Right Sidebar -->
                <DocsAside
                    :toc="toc"
                    :content-path="page?.stem"
                />
            </div>
        </div>

        <Search/>
    </div>
</template>

<script setup>
const route = useRoute();
const { domain } = useRuntimeConfig().public;

const { data: page } = await useAsyncData(`page-${route.path}`, () =>
    queryCollection('docs').path(route.path).first()
)

// Extract table of contents from page body
const toc = computed(() => page.value?.body?.toc?.links || [])

useHead({
    htmlAttrs: {
        lang: 'en'
    },
    bodyAttrs: {
        class: 'antialiased font-inter bg-black'
    }
})

useSeoMeta({
    ogLocale: 'en_US',
    ogUrl: domain + route.path,
    ogType: 'website',
    ogSiteName: 'Server Side Up - Spin',
    ogTitle: page.value?.title,
    ogDescription: page.value?.description,
    twitterCard: 'summary_large_image',
    twitterDescription: page.value?.description,
    twitterSite: '@serversideup',
    twitterTitle: page.value?.title
})

defineOgImage({
    component: 'DocsImage',
    title: page.value?.title,
    description: page.value?.description
});
</script>
