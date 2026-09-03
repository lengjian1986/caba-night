import request from '@/utils/request'

export function loginShopPortal(params: Record<string, any>) {
    return request.post({ url: '/cabakura.shop_portal/login', params }, { withToken: false })
}

export function selectShopPortalShop(params: Record<string, any>) {
    return request.post({ url: '/cabakura.shop_portal/selectShop', params }, { withToken: false })
}

export function getShopPortalDashboard(shopToken: string) {
    return request.get(
        {
            url: '/cabakura.shop_portal/dashboard',
            headers: {
                'shop-token': shopToken
            }
        },
        { withToken: false, ignoreCancelToken: true }
    )
}

export function saveShopPortalPlan(shopToken: string, params: Record<string, any>) {
    return request.post(
        {
            url: '/cabakura.shop_portal/savePlan',
            params,
            headers: {
                'shop-token': shopToken
            }
        },
        { withToken: false }
    )
}

export function saveShopPortalProfile(shopToken: string, params: Record<string, any>) {
    return request.post(
        {
            url: '/cabakura.shop_portal/saveProfile',
            params,
            headers: {
                'shop-token': shopToken
            }
        },
        { withToken: false }
    )
}

export function saveShopPortalBusinessStatus(shopToken: string, params: Record<string, any>) {
    return request.post(
        {
            url: '/cabakura.shop_portal/saveBusinessStatus',
            params,
            headers: {
                'shop-token': shopToken
            }
        },
        { withToken: false }
    )
}

export function getShopPortalUnboundCasts(shopToken: string) {
    return request.get(
        {
            url: '/cabakura.shop_portal/unboundCasts',
            headers: {
                'shop-token': shopToken
            }
        },
        { withToken: false, ignoreCancelToken: true }
    )
}

export function bindShopPortalCast(shopToken: string, params: Record<string, any>) {
    return request.post(
        {
            url: '/cabakura.shop_portal/bindCast',
            params,
            headers: {
                'shop-token': shopToken
            }
        },
        { withToken: false }
    )
}

export function saveShopPortalCastAttendance(shopToken: string, params: Record<string, any>) {
    return request.post(
        {
            url: '/cabakura.shop_portal/saveCastAttendance',
            params,
            headers: {
                'shop-token': shopToken
            }
        },
        { withToken: false }
    )
}

export function getShopPortalAnswerFields(shopToken: string) {
    return request.get(
        {
            url: '/cabakura.shop_portal/answerFields',
            headers: {
                'shop-token': shopToken
            }
        },
        { withToken: false, ignoreCancelToken: true }
    )
}

function updateShopPortalOrder(shopToken: string, url: string, id: number) {
    return request.post(
        {
            url,
            params: { id },
            headers: { 'shop-token': shopToken }
        },
        { withToken: false }
    )
}

export function confirmShopPortalOrder(shopToken: string, id: number) {
    return updateShopPortalOrder(shopToken, '/cabakura.shop_portal/confirmOrder', id)
}

export function rejectShopPortalOrder(shopToken: string, id: number) {
    return updateShopPortalOrder(shopToken, '/cabakura.shop_portal/rejectOrder', id)
}

export function cancelShopPortalOrder(shopToken: string, id: number) {
    return updateShopPortalOrder(shopToken, '/cabakura.shop_portal/cancelOrder', id)
}
