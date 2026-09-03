import request from '@/utils/request'

export function getCabakuraCastList(params: Record<string, any>) {
    return request.get({ url: '/cabakura.cast/lists', params }, { ignoreCancelToken: true })
}

export function saveCabakuraCastProfile(params: Record<string, any>) {
    return request.post({ url: '/cabakura.cast/saveProfile', params })
}

export function switchCabakuraCastRecommended(params: Record<string, any>) {
    return request.post({ url: '/cabakura.cast/switchRecommended', params })
}

export function switchCabakuraCastPopular(params: Record<string, any>) {
    return request.post({ url: '/cabakura.cast/switchPopular', params })
}
