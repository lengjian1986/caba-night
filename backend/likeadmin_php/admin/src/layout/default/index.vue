<template>
    <div class="layout-default flex h-screen w-full">
        <div class="app-aside">
            <layout-sidebar />
        </div>

        <div class="flex-1 flex flex-col min-w-0">
            <div class="app-header">
                <layout-header />
            </div>
            <div class="app-main flex-1 min-h-0">
                <layout-main />
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import LayoutHeader from './components/header/index.vue'
import LayoutMain from './components/main.vue'
import LayoutSidebar from './components/sidebar/index.vue'
</script>

<style lang="scss" scoped>
.layout-default {
    background: var(--cabakura-admin-page-bg);
}

.app-header {
    border-bottom: 1px solid rgba(179, 101, 159, 0.12);
    background: var(--cabakura-admin-panel-bg);
}

.app-main {
    background:
        linear-gradient(180deg, rgba(255, 255, 255, 0.78), rgba(255, 255, 255, 0) 180px),
        var(--cabakura-admin-page-bg);
}
</style>
