<template>
    <div>
        <el-card class="!border-none" shadow="never">
            <el-form class="mb-[-16px]" :model="queryParams" :inline="true">
                <el-form-item label="チケット情報">
                    <el-input
                        v-model="queryParams.keyword"
                        class="w-[280px]"
                        placeholder="チケット番号/注文番号/会員"
                        clearable
                        @keyup.enter="resetPage"
                    />
                </el-form-item>
                <el-form-item label="ステータス">
                    <el-select v-model="queryParams.status" class="w-[180px]" clearable>
                        <el-option
                            v-for="option in supportTicketStatusOptions"
                            :key="option.value"
                            :label="option.label"
                            :value="option.value"
                        />
                    </el-select>
                </el-form-item>
                <el-form-item>
                    <el-button type="primary" @click="resetPage">検索</el-button>
                    <el-button @click="resetParams">リセット</el-button>
                </el-form-item>
            </el-form>
        </el-card>

        <el-card class="!border-none mt-4" shadow="never">
            <el-table size="large" v-loading="pager.loading" :data="pager.lists">
                <el-table-column label="チケット番号" prop="ticket_no" min-width="180" />
                <el-table-column label="カテゴリ" prop="category" min-width="140" />
                <el-table-column label="会員" prop="member_name" min-width="120" />
                <el-table-column label="関連注文" prop="order_no" min-width="160" />
                <el-table-column label="店舗" prop="shop_name" min-width="140" />
                <el-table-column label="最終メッセージ" prop="last_message" min-width="300" show-overflow-tooltip />
                <el-table-column label="ステータス" min-width="140">
                    <template #default="{ row }">
                        <el-tag :type="statusTagType(row.status)">{{ row.status_text }}</el-tag>
                    </template>
                </el-table-column>
                <el-table-column label="更新日時" prop="updated_at" min-width="170" />
                <el-table-column label="操作" width="120" fixed="right">
                    <template #default="{ row }">
                        <el-button type="primary" link @click="openHandleDialog(row)">対応</el-button>
                    </template>
                </el-table-column>
            </el-table>
            <div class="flex justify-end mt-4">
                <pagination v-model="pager" @change="getLists" />
            </div>
        </el-card>

        <el-dialog v-model="handleVisible" title="チケット対応" width="680px">
            <el-descriptions v-if="currentTicket" :column="2" border class="mb-4">
                <el-descriptions-item label="チケット番号">
                    {{ currentTicket.ticket_no }}
                </el-descriptions-item>
                <el-descriptions-item label="会員">
                    {{ currentTicket.member_name || '-' }}
                </el-descriptions-item>
                <el-descriptions-item label="店舗">
                    {{ currentTicket.shop_name || '-' }}
                </el-descriptions-item>
                <el-descriptions-item label="ステータス">
                    <el-tag :type="statusTagType(currentTicket.status)">
                        {{ currentTicket.status_text }}
                    </el-tag>
                </el-descriptions-item>
            </el-descriptions>

            <div v-loading="messagesLoading" class="message-history">
                <el-empty
                    v-if="!messagesLoading && !ticketMessages.length"
                    description="メッセージはありません"
                />
                <div
                    v-for="message in ticketMessages"
                    :key="message.id"
                    class="message-item"
                    :class="{ 'is-admin': message.sender_type === 'admin' }"
                >
                    <div class="message-meta">
                        <span>{{ senderText(message) }}</span>
                        <span>{{ message.created_at }}</span>
                    </div>
                    <div class="message-bubble">{{ message.content }}</div>
                </div>
            </div>

            <el-form :model="handleForm" label-width="120px" class="mt-4">
                <el-form-item label="ステータス">
                    <el-select v-model="handleForm.status" class="w-full">
                        <el-option
                            v-for="option in supportTicketHandleOptions"
                            :key="option.value"
                            :label="option.label"
                            :value="option.value"
                        />
                    </el-select>
                </el-form-item>
                <el-form-item label="返信内容">
                    <el-input
                        v-model="handleForm.content"
                        type="textarea"
                        :rows="4"
                        placeholder="ユーザーへの返信内容を入力してください"
                    />
                </el-form-item>
            </el-form>

            <template #footer>
                <el-button @click="handleVisible = false">キャンセル</el-button>
                <el-button type="primary" :loading="replyLoading" @click="handleReply">返信</el-button>
            </template>
        </el-dialog>
    </div>
</template>

<script lang="ts" setup name="cabakuraSupportTicket">
import {
    getCabakuraSupportTicketMessages,
    getCabakuraSupportTickets,
    replyCabakuraSupportTicket
} from '@/api/cabakura/support'
import { statusTagType } from '@/enums/cabakura/status'
import { usePaging } from '@/hooks/usePaging'

const queryParams = reactive({
    keyword: '',
    status: ''
})

const supportTicketStatusOptions = [
    { label: '未対応', value: 'open' },
    { label: '対応中', value: 'in_progress' },
    { label: '対応済み', value: 'done' }
]

const handleVisible = ref(false)
const messagesLoading = ref(false)
const replyLoading = ref(false)
const currentTicket = ref<Record<string, any> | null>(null)
const ticketMessages = ref<Record<string, any>[]>([])
const handleForm = reactive({
    id: 0,
    status: 'pending_user',
    content: ''
})

const { pager, getLists, resetPage, resetParams } = usePaging({
    fetchFun: getCabakuraSupportTickets,
    params: queryParams
})

const normalizeHandleStatus = (status: string) => {
    if (['pending_operator', 'pending_user'].includes(status)) {
        return 'pending_user'
    }
    if (['resolved', 'closed'].includes(status)) {
        return 'resolved'
    }
    return 'open'
}

const supportTicketHandleOptions = [
    { label: '未対応', value: 'open' },
    { label: '対応中', value: 'pending_user' },
    { label: '対応済み', value: 'resolved' }
]

const senderText = (message: Record<string, any>) => {
    if (message.sender_type === 'admin') {
        return message.sender_name || '管理者'
    }
    if (message.sender_type === 'shop') {
        return message.sender_name || '店舗'
    }
    return message.sender_name || 'ユーザー'
}

const loadMessages = async (ticketId: number) => {
    messagesLoading.value = true
    try {
        ticketMessages.value = await getCabakuraSupportTicketMessages({ ticket_id: ticketId })
    } finally {
        messagesLoading.value = false
    }
}

const openHandleDialog = async (row: Record<string, any>) => {
    currentTicket.value = row
    handleForm.id = row.id
    handleForm.status = normalizeHandleStatus(row.status)
    handleForm.content = ''
    ticketMessages.value = []
    handleVisible.value = true
    await loadMessages(row.id)
}

const handleReply = async () => {
    replyLoading.value = true
    try {
        await replyCabakuraSupportTicket({
            ticket_id: handleForm.id,
            status: handleForm.status,
            content: handleForm.content
        })
        handleForm.content = ''
        await loadMessages(handleForm.id)
        getLists()
    } finally {
        replyLoading.value = false
    }
}

onActivated(() => {
    getLists()
})

getLists()
</script>

<style lang="scss" scoped>
.message-history {
    max-height: 360px;
    min-height: 180px;
    overflow-y: auto;
    padding: 16px;
    background: #fff7fb;
    border: 1px solid #f1d7e4;
    border-radius: 8px;
}

.message-item {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    gap: 6px;
    margin-bottom: 14px;
}

.message-item.is-admin {
    align-items: flex-end;
}

.message-meta {
    display: flex;
    gap: 10px;
    color: #909399;
    font-size: 12px;
}

.message-bubble {
    max-width: 78%;
    white-space: pre-wrap;
    word-break: break-word;
    padding: 10px 12px;
    color: #303133;
    background: #ffffff;
    border: 1px solid #ebeef5;
    border-radius: 8px;
}

.message-item.is-admin .message-bubble {
    color: #ffffff;
    background: #8b5cf6;
    border-color: #8b5cf6;
}
</style>
