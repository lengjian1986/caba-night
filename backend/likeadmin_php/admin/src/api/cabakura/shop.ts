import request from '@/utils/request'

export function getCabakuraShopList(params: Record<string, any>) {
    return request.get({ url: '/cabakura.shop/lists', params }, { ignoreCancelToken: true })
}

export function saveCabakuraShopDraft(params: Record<string, any>) {
    return request.post({ url: '/cabakura.shop/saveDraft', params })
}

export function submitCabakuraShopReview(params: Record<string, any>) {
    return request.post({ url: '/cabakura.shop/submitReview', params })
}

export function updateCabakuraShopInfo(params: Record<string, any>) {
    return request.post({ url: '/cabakura.shop/updateInfo', params })
}

export function switchCabakuraShopRecommended(params: Record<string, any>) {
    return request.post({ url: '/cabakura.shop/switchRecommended', params })
}

export function getCabakuraShopDetail(params: Record<string, any>) {
    return request.get({ url: '/cabakura.shop/detail', params })
}

export function approveCabakuraShop(params: Record<string, any>) {
    return request.post({ url: '/cabakura.shop/approve', params })
}

export function rejectCabakuraShop(params: Record<string, any>) {
    return request.post({ url: '/cabakura.shop/reject', params })
}
