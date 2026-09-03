<template>
    <div class="side" :style="sideStyle">
        <side-logo v-if="settingStore.showLogo" :show-title="!isCollapsed" :theme="sideTheme" />
        <side-menu
            :routes="routes"
            :is-collapsed="isCollapsed"
            :width="settingStore.sideWidth"
            :unique-opened="settingStore.isUniqueOpened"
            :config="menuProp"
            :theme="sideTheme"
            @select="handleSelect"
        />
    </div>
</template>

<script setup lang="ts">
import useAppStore from '@/stores/modules/app'
import useSettingStore from '@/stores/modules/setting'
import useUserStore from '@/stores/modules/user'

import SideLogo from './logo.vue'
import SideMenu from './menu.vue'

const appStore = useAppStore()
const isCollapsed = computed(() => {
    if (appStore.isMobile) {
        return false
    } else {
        return appStore.isCollapsed
    }
})

const settingStore = useSettingStore()
const sideTheme = computed(() => settingStore.sideTheme)
const userStore = useUserStore()

const routes = computed(() => userStore.routes)

const sideStyle = computed(() => {
    return {
        '--side-dark-color': settingStore.sideDarkColor || 'var(--cabakura-admin-sidebar-bg)'
    }
})
const menuProp = computed(() => {
    return {
        backgroundColor: 'transparent',
        textColor: 'rgba(255, 255, 255, 0.82)',
        activeTextColor: 'var(--el-color-white)'
    }
})
const handleSelect = () => {
    if (appStore.isMobile) {
        appStore.toggleCollapsed(true)
    }
}
</script>

<style lang="scss" scoped>
.side {
    position: relative;
    z-index: 999;
    @apply h-full flex flex-col;
    border-right: 1px solid rgba(255, 255, 255, 0.08);
    background:
        linear-gradient(180deg, rgba(255, 255, 255, 0.08) 0%, rgba(255, 255, 255, 0) 36%),
        linear-gradient(
            180deg,
            var(--side-dark-color, var(--cabakura-admin-sidebar-bg)) 0%,
            var(--cabakura-admin-sidebar-bg-deep) 100%
        );
    box-shadow: 10px 0 28px rgba(91, 59, 140, 0.14);
}
</style>
