export const ShopReviewStatusMap: Record<string, string> = {
    draft: '草稿',
    submitted: '待审核',
    reviewing: '审核中',
    approved: '审核通过',
    rejected: '审核驳回',
    supplement_required: '需补充资料',
    suspended: '暂停展示'
}

export const OrderStatusMap: Record<string, string> = {
    requesting: '確認待ち',
    confirmed: '予約確定',
    unpaid: '未決済',
    paid: '決済済み',
    visited: '来店済み',
    completed: '売上確定',
    cancel_requested: 'キャンセル申請中',
    cancelled: 'キャンセル済み',
    refund_pending: '返金処理中',
    refunded: '返金済み',
    refund_failed: '返金失敗'
}

export const SupportTicketStatusMap: Record<string, string> = {
    open: '未対応',
    pending_operator: '対応中',
    pending_user: '対応中',
    resolved: '対応済み',
    closed: '対応済み'
}

export const IdentityStatusMap: Record<string, string> = {
    approved: '通過',
    rejected: '拒否'
}

export const MemberStatusMap: Record<string, string> = {
    normal: '有効',
    disabled: '凍結'
}

export function statusTagType(status: string) {
    if (['pending_operator', 'pending_user'].includes(status)) {
        return 'primary'
    }
    if (['approved', 'confirmed', 'paid', 'completed', 'refunded', 'resolved', 'closed'].includes(status)) {
        return 'success'
    }
    if (['open', 'reviewing', 'requesting', 'refund_pending'].includes(status)) {
        return 'warning'
    }
    if (['rejected', 'refund_failed', 'suspended'].includes(status)) {
        return 'danger'
    }
    return 'info'
}
