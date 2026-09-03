import request from '@/utils/request'

export function getPushNotificationList(params: Record<string, any>) {
    return request.get({ url: '/cabakura.pushNotification/lists', params }, { ignoreCancelToken: true })
}

export function savePushNotification(params: Record<string, any>) {
    return request.post({ url: '/cabakura.pushNotification/save', params })
}
