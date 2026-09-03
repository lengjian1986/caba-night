import { defineStore } from 'pinia'

export type AdminLanguage = 'zh' | 'ja'

const STORAGE_KEY = 'cabakura_admin_language'

const getDefaultLanguage = (): AdminLanguage => {
    const value = localStorage.getItem(STORAGE_KEY)
    return value === 'ja' ? 'ja' : 'zh'
}

const useLanguageStore = defineStore({
    id: 'language',
    state: () => ({
        language: getDefaultLanguage() as AdminLanguage
    }),
    actions: {
        setLanguage(language: AdminLanguage) {
            this.language = language
            localStorage.setItem(STORAGE_KEY, language)
            document.documentElement.lang = language === 'ja' ? 'ja' : 'zh-CN'
        },
        toggleLanguage() {
            this.setLanguage(this.language === 'ja' ? 'zh' : 'ja')
        }
    }
})

export default useLanguageStore
