import request from '@/utils/request'

export function getCabakuraSubscriptionUsers(params: Record<string, any>) {
    return request.get({ url: '/cabakura.subscription/users', params }, { ignoreCancelToken: true })
}

export function getCabakuraSubscriptionRecords(params: Record<string, any>) {
    return request.get({ url: '/cabakura.subscription/records', params }, { ignoreCancelToken: true })
}

export function getCabakuraSubscriptionPlans(params: Record<string, any>) {
    return request.get({ url: '/cabakura.subscription/plans', params }, { ignoreCancelToken: true })
}

export function saveCabakuraSubscriptionPlan(params: Record<string, any>) {
    return request.post({ url: '/cabakura.subscription/savePlan', params })
}

export function switchCabakuraSubscriptionPlan(params: Record<string, any>) {
    return request.post({ url: '/cabakura.subscription/switchPlan', params })
}
