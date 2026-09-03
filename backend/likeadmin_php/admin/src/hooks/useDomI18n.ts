import useLanguageStore from '@/stores/modules/language'
import { translateInlineText } from '@/utils/i18n'

const translatedAttrs = [
    'placeholder',
    'title',
    'aria-label',
    'content',
    'label',
    'description',
    'active-text',
    'inactive-text',
    'start-placeholder',
    'end-placeholder'
]

const shouldSkipElement = (node: Node) => {
    const parent = node.parentElement
    if (!parent) return true
    return ['SCRIPT', 'STYLE', 'TEXTAREA'].includes(parent.tagName)
}

const translateTextNode = (node: Node, language: 'zh' | 'ja') => {
    if (shouldSkipElement(node)) return
    const value = node.textContent || ''
    const translated = translateInlineText(value, language)
    if (translated !== value) {
        node.textContent = translated
    }
}

const translateElementAttrs = (element: Element, language: 'zh' | 'ja') => {
    translatedAttrs.forEach((attr) => {
        const value = element.getAttribute(attr)
        if (!value) return
        const translated = translateInlineText(value, language)
        if (translated !== value) {
            element.setAttribute(attr, translated)
        }
    })
}

const translateNode = (node: Node, language: 'zh' | 'ja') => {
    if (node.nodeType === Node.TEXT_NODE) {
        translateTextNode(node, language)
        return
    }
    if (node.nodeType !== Node.ELEMENT_NODE) return

    const element = node as Element
    translateElementAttrs(element, language)
    element.querySelectorAll('*').forEach((child) => translateElementAttrs(child, language))
    const walker = document.createTreeWalker(element, NodeFilter.SHOW_TEXT)
    let textNode = walker.nextNode()
    while (textNode) {
        translateTextNode(textNode, language)
        textNode = walker.nextNode()
    }
}

export const useDomI18n = () => {
    const languageStore = useLanguageStore()
    let observer: MutationObserver | null = null

    const applyTranslate = () => {
        document.documentElement.lang = languageStore.language === 'ja' ? 'ja' : 'zh-CN'
        translateNode(document.body, languageStore.language)
    }

    onMounted(() => {
        applyTranslate()
        observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                mutation.addedNodes.forEach((node) => translateNode(node, languageStore.language))
                if (mutation.type === 'attributes') {
                    translateNode(mutation.target, languageStore.language)
                }
            })
        })
        observer.observe(document.body, {
            childList: true,
            subtree: true,
            attributes: true,
            attributeFilter: translatedAttrs
        })
    })

    onUnmounted(() => {
        observer?.disconnect()
    })

    watch(
        () => languageStore.language,
        () => nextTick(applyTranslate),
        { flush: 'post' }
    )
}
