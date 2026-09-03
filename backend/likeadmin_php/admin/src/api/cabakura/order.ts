import request from '@/utils/request'

export function getCabakuraOrderList(params: Record<string, any>) {
    return request.get({ url: '/cabakura.order/lists', params }, { ignoreCancelToken: true })
}

export function confirmCabakuraOrder(params: Record<string, any>) {
    return request.post({ url: '/cabakura.order/confirm', params })
}

export function rejectCabakuraOrder(params: Record<string, any>) {
    return request.post({ url: '/cabakura.order/reject', params })
}

export function cancelCabakuraOrder(params: Record<string, any>) {
    return request.post({ url: '/cabakura.order/cancel', params })
}
