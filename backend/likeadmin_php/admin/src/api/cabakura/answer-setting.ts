import request from '@/utils/request'

export function getCabakuraAnswerSettingFields() {
    return request.get({ url: '/cabakura.answer_setting/fields' })
}

export function saveCabakuraAnswerSettingOption(params: Record<string, any>) {
    return request.post({ url: '/cabakura.answer_setting/saveOption', params })
}

export function deleteCabakuraAnswerSettingOption(params: Record<string, any>) {
    return request.post({ url: '/cabakura.answer_setting/deleteOption', params })
}
