<template>
    <el-tooltip effect="dark" :content="tooltip" placement="bottom">
        <button class="language-switch" type="button" @click="languageStore.toggleLanguage()">
            {{ languageStore.language === 'ja' ? '日本語' : '中文' }}
        </button>
    </el-tooltip>
</template>

<script setup lang="ts">
import useLanguageStore from '@/stores/modules/language'

const languageStore = useLanguageStore()
const tooltip = computed(() => (languageStore.language === 'ja' ? '中文に切り替え' : '切换日语'))
</script>

<style lang="scss" scoped>
.language-switch {
    min-width: 66px;
    height: 28px;
    padding: 0 10px;
    border: 1px solid var(--el-border-color);
    border-radius: 4px;
    color: var(--el-text-color-primary);
    background: var(--el-bg-color);
    font-size: 13px;
    line-height: 26px;
    cursor: pointer;
}
</style>
