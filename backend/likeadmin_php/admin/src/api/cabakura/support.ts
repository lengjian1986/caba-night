import request from '@/utils/request'

export function getCabakuraSupportTickets(params: Record<string, any>) {
    return request.get({ url: '/cabakura.support/tickets', params }, { ignoreCancelToken: true })
}

export function updateCabakuraSupportTicketStatus(params: Record<string, any>) {
    return request.post({ url: '/cabakura.support/updateStatus', params })
}

export function getCabakuraSupportTicketMessages(params: Record<string, any>) {
    return request.get({ url: '/cabakura.support/messages', params }, { ignoreCancelToken: true })
}

export function replyCabakuraSupportTicket(params: Record<string, any>) {
    return request.post({ url: '/cabakura.support/reply', params })
}
