<script setup lang="ts">
import { useDark, useThrottleFn, useWindowSize } from '@vueuse/core'
import ja from 'element-plus/es/locale/lang/ja'
import zhCn from 'element-plus/es/locale/lang/zh-cn'

import { ScreenEnum } from './enums/appEnums'
import { useDomI18n } from './hooks/useDomI18n'
import useAppStore from './stores/modules/app'
import useLanguageStore from './stores/modules/language'
import useSettingStore from './stores/modules/setting'

const appStore = useAppStore()
const settingStore = useSettingStore()
const languageStore = useLanguageStore()
const elConfig = computed(() => ({
    zIndex: 3000,
    locale: languageStore.language === 'ja' ? ja : zhCn
}))
const isDark = useDark()
useDomI18n()
onMounted(async () => {
    //设置主题色
    settingStore.setTheme(isDark.value)
})

const { width } = useWindowSize()
watch(
    width,
    useThrottleFn((value) => {
        if (value > ScreenEnum.SM) {
            appStore.setMobile(false)
            appStore.toggleCollapsed(false)
        } else {
            appStore.setMobile(true)
            appStore.toggleCollapsed(true)
        }
        if (value < ScreenEnum.MD) {
            appStore.toggleCollapsed(true)
        }
    }),
    {
        immediate: true
    }
)
</script>

<template>
    <el-config-provider :locale="elConfig.locale" :z-index="elConfig.zIndex">
        <router-view />
    </el-config-provider>
</template>

<style></style>
