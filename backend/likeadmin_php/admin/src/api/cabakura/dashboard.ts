import request from '@/utils/request'

export function getCabakuraDashboardSummary() {
    return request.get({ url: '/cabakura.dashboard/summary' })
}
