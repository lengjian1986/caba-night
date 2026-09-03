import request from '@/utils/request'

export function getCabakuraMemberList(params: Record<string, any>) {
    return request.get({ url: '/cabakura.member/lists', params }, { ignoreCancelToken: true })
}

export function getCabakuraMemberDeleteRecords(params: Record<string, any>) {
    return request.get(
        { url: '/cabakura.member/deleteRecords', params },
        { ignoreCancelToken: true }
    )
}

export function getCabakuraMemberDetail(params: Record<string, any>) {
    return request.get({ url: '/cabakura.member/detail', params })
}

export function updateCabakuraMemberProfile(params: Record<string, any>) {
    return request.post({ url: '/cabakura.member/updateProfile', params })
}

export function approveCabakuraMemberIdentity(params: Record<string, any>) {
    return request.post({ url: '/cabakura.member/approveIdentity', params })
}

export function rejectCabakuraMemberIdentity(params: Record<string, any>) {
    return request.post({ url: '/cabakura.member/rejectIdentity', params })
}
