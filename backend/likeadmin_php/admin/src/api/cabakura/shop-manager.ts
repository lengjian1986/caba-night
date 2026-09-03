import request from '@/utils/request'

export function getCabakuraShopManagerList(params: Record<string, any>) {
    return request.get({ url: '/cabakura.shop_manager/lists', params }, { ignoreCancelToken: true })
}

export function saveCabakuraShopManager(params: Record<string, any>) {
    return request.post({ url: '/cabakura.shop_manager/save', params })
}

export function deleteCabakuraShopManager(params: Record<string, any>) {
    return request.post({ url: '/cabakura.shop_manager/delete', params })
}
