import request from '@/utils/request'

export const getCabakuraTerms = (params: Record<string, any>) => request.get({ url: '/cabakura.terms/lists', params }, { ignoreCancelToken: true })
export const saveCabakuraTerms = (params: Record<string, any>) => request.post({ url: '/cabakura.terms/save', params })
export const switchCabakuraTermsShow = (params: Record<string, any>) => request.post({ url: '/cabakura.terms/switchShow', params })
