import request from '@/utils/request'

export function getDocumentConfig() {
    return request.get({ url: '/setting.document/getConfig' })
}

export function setDocumentConfig(params: Record<string, any>) {
    return request.post({ url: '/setting.document/setConfig', params })
}
