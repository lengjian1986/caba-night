import request from '@/utils/request'

export function getCabakuraAreaList(params: Record<string, any>) {
    return request.get({ url: '/cabakura.area/lists', params }, { ignoreCancelToken: true })
}

export function saveCabakuraArea(params: Record<string, any>) {
    return request.post({ url: '/cabakura.area/save', params })
}

export function switchCabakuraAreaShow(params: Record<string, any>) {
    return request.post({ url: '/cabakura.area/switchShow', params })
}

export function switchCabakuraAreaRecommended(params: Record<string, any>) {
    return request.post({ url: '/cabakura.area/switchRecommended', params })
}

export function deleteCabakuraArea(params: Record<string, any>) {
    return request.post({ url: '/cabakura.area/delete', params })
}
