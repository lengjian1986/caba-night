<template>
    <div
        class="menu flex-1 min-h-0"
        :class="themeClass"
        :style="isCollapsed ? '' : `--aside-width: ${width}px`"
    >
        <el-scrollbar>
            <el-menu
                v-bind="config"
                :default-active="activeMenu"
                :collapse="isCollapsed"
                mode="vertical"
                :unique-opened="uniqueOpened"
                @select="$emit('select')"
            >
                <menu-item
                    v-for="route in routes"
                    :key="route.path"
                    :route="route"
                    :route-path="route.path"
                    :popper-class="themeClass"
                />
            </el-menu>
        </el-scrollbar>
    </div>
</template>

<script setup lang="ts">
import type { PropType } from 'vue'
import type { RouteRecordRaw } from 'vue-router'

import MenuItem from './menu-item.vue'

const props = defineProps({
    routes: {
        type: Object as PropType<RouteRecordRaw[]>
    },
    config: {
        type: Object
    },
    uniqueOpened: {
        type: Boolean,
        default: false
    },
    isCollapsed: {
        type: Boolean,
        default: false
    },
    theme: {
        type: String
    },
    width: {
        type: Number,
        default: 200
    }
})

defineEmits(['select'])

const route = useRoute()
const activeMenu = computed<string>(() => route.meta?.activeMenu || route.path)
const themeClass = computed(() => `theme-${props.theme}`)
</script>

<style lang="scss" scoped>
.menu {
    &.theme-dark {
        .el-menu {
            :deep(.el-menu-item) {
                border-radius: 8px;
                margin: 2px 10px;
                &.is-active {
                    background: var(--cabakura-admin-sidebar-active);
                    border-color: rgba(255, 255, 255, 0.16);
                    box-shadow: 0 8px 18px rgba(179, 101, 159, 0.28);
                }
            }
            :deep(.el-menu-item:hover),
            :deep(.el-sub-menu__title:hover) {
                background: var(--cabakura-admin-sidebar-hover);
                color: var(--el-color-white);
            }
        }
        :deep(.el-menu--collapse) {
            .el-sub-menu.is-active .el-sub-menu__title {
                background: var(--cabakura-admin-sidebar-active) #{!important};
            }
        }
    }
    &.theme-light {
        :deep(.el-menu) {
            .el-menu-item {
                border-color: transparent;
                border-radius: 8px;
                color: rgba(255, 255, 255, 0.82);
                margin: 2px 10px;
                &.is-active {
                    background: var(--cabakura-admin-sidebar-active);
                    border-right: 0;
                    color: var(--el-color-white);
                    box-shadow: 0 8px 18px rgba(179, 101, 159, 0.28);
                }
            }
            .el-menu-item:hover,
            .el-sub-menu__title:hover {
                background: var(--cabakura-admin-sidebar-hover);
                color: var(--el-color-white);
            }
            .el-sub-menu__title {
                color: rgba(255, 255, 255, 0.82);
            }
        }
    }
    .el-menu {
        border-right: none;
        background: transparent;

        // Keep top-level leaf items aligned with top-level submenu titles.
        :deep(> .el-menu-item) {
            padding-left: var(--el-menu-base-level-padding) !important;
        }

        &:not(.el-menu--collapse) {
            width: var(--aside-width);
        }
    }
}
</style>
