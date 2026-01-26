<template>
    <div class="not-prose my-6 overflow-hidden rounded-2xl bg-zinc-900 shadow-md ring-1 ring-white/10">
        <div ref="positionRef" class="flex min-h-[calc(theme(spacing.12)+1px)] flex-wrap items-start gap-x-4 border-b px-4 border-zinc-800 bg-transparent">
            <h3 v-if="title != ''" class="mr-auto pt-3 text-xs font-semibold text-white">
                {{ title }}
            </h3>
            <UTabs
                v-model="selectedTabIndex"
                :items="tabItems"
                @update:model-value="changeTab"
                :ui="{
                    list: '-mb-px flex gap-4 text-xs font-medium bg-transparent',
                    trigger: 'border-b py-3 transition focus-visible:outline-none border-transparent text-zinc-400 hover:text-zinc-300 data-[state=active]:border-emerald-500 data-[state=active]:text-emerald-400'
                }"
            />
        </div>
        <div class="group bg-white/2.5">
            <div class="relative overflow-x-auto p-4 text-xs text-white">
                <component :is="renderSlot" />
            </div>
        </div>
    </div>
</template>

<script setup>
const props = defineProps({
    title: {
        default: ''
    },
    tabs: {
        default() {
            return [];
        }
    },
    label: {
        default: ''
    },
    snippets: {
        default() {
            return [];
        }
    },
    tag: {
        default: ''
    }
})

const slots = useSlots()
const preferredProgrammingLanguage = usePreferredProgrammingLanguage();

const tabItems = computed(() => {
    return props.tabs.map(tab => ({
        label: tab.name,
        key: tab.key
    }))
})

const selectedTabIndex = computed({
    get() {
        for (let i = 0; i < props.tabs.length; i++) {
            if (props.tabs[i].key === preferredProgrammingLanguage.value) {
                return i;
            }
        }
        return 0;
    },
    set(value) {
        if (props.tabs[value]) {
            preferredProgrammingLanguage.value = props.tabs[value].key;
        }
    }
});

const currentSlot = computed(() => {
    const currentTab = props.tabs[selectedTabIndex.value];
    return currentTab ? slots[currentTab.key] : null;
})

const renderSlot = computed(() => {
    const slot = currentSlot.value;
    if (!slot) return { render: () => null };
    return { render: () => slot() };
})

const positionRef = ref(null);

function changeTab(index) {
    if (!positionRef.value) return;

    let initialTop = positionRef.value.getBoundingClientRect().top;
    preferredProgrammingLanguage.value = props.tabs[index].key;

    window.requestAnimationFrame(() => {
        let newTop = positionRef.value.getBoundingClientRect().top;
        window.scrollBy(0, newTop - initialTop);
    });
}
</script>
