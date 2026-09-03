import request from '@/utils/request'

export function getCabakuraNewsList(params: Record<string, any>) {
    return request.get({ url: '/cabakura.news/lists', params }, { ignoreCancelToken: true })
}

export function saveCabakuraNews(params: Record<string, any>) {
    return request.post({ url: '/cabakura.news/save', params })
}

export function switchCabakuraNewsShow(params: Record<string, any>) {
    return request.post({ url: '/cabakura.news/switchShow', params })
}
