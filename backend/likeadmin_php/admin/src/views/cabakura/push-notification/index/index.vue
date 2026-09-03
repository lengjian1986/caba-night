<template>
    <div>
        <el-card class="!border-none" shadow="never">
            <el-form :inline="true" :model="queryParams">
                <el-form-item label="タイトル">
                    <el-input v-model="queryParams.keyword" class="w-[260px]" clearable placeholder="タイトルまたは内容で検索" @keyup.enter="resetPage" />
                </el-form-item>
                <el-form-item>
                    <el-button type="primary" @click="resetPage">検索</el-button>
                    <el-button @click="resetParams">リセット</el-button>
                    <el-button type="primary" class="ml-2" @click="openDialog()">プッシュ通知を作成</el-button>
                </el-form-item>
            </el-form>
        </el-card>
        <el-card class="!border-none mt-4" shadow="never">
            <el-table size="large" v-loading="pager.loading" :data="pager.lists">
                <el-table-column label="タイトル" prop="title" min-width="220" />
                <el-table-column label="内容" prop="content" min-width="300" show-overflow-tooltip />
                <el-table-column label="モード" width="120">
                    <template #default="{ row }">{{ row.mode === 'scheduled' ? '定時プッシュ' : '即時プッシュ' }}</template>
                </el-table-column>
                <el-table-column label="配信日時" prop="scheduled_at_text" width="170" />
                <el-table-column label="状態" width="100">
                    <template #default="{ row }">{{ row.status === 'sent' ? '配信済み' : '待機中' }}</template>
                </el-table-column>
                <el-table-column label="操作" fixed="right" width="90">
                    <template #default="{ row }"><el-button type="primary" link @click="openDialog(row)">編集</el-button></template>
                </el-table-column>
            </el-table>
            <div class="flex justify-end mt-4"><pagination v-model="pager" @change="getLists" /></div>
        </el-card>
        <el-dialog v-model="dialogVisible" :title="form.id ? 'プッシュ通知編集' : 'プッシュ通知を作成'" width="620px">
            <el-form :model="form" label-width="100px">
                <el-form-item label="タイトル" required><el-input v-model="form.title" maxlength="255" show-word-limit /></el-form-item>
                <el-form-item label="内容" required><el-input v-model="form.content" type="textarea" :rows="7" /></el-form-item>
                <el-form-item label="リンク"><el-input v-model="form.link" placeholder="任意のURLまたはdeeplink" /></el-form-item>
                <el-form-item label="プッシュモード">
                    <el-radio-group v-model="form.mode"><el-radio label="immediate">即時プッシュ</el-radio><el-radio label="scheduled">定時プッシュ</el-radio></el-radio-group>
                </el-form-item>
                <el-form-item v-if="form.mode === 'scheduled'" label="配信日時" required><el-date-picker v-model="form.scheduled_at" type="datetime" value-format="YYYY-MM-DD HH:mm:ss" format="YYYY-MM-DD HH:mm" class="w-full" /></el-form-item>
            </el-form>
            <template #footer><el-button @click="dialogVisible = false">キャンセル</el-button><el-button type="primary" :loading="saving" @click="handleSave">保存して配信</el-button></template>
        </el-dialog>
    </div>
</template>

<script lang="ts" setup name="cabakuraPushNotification">
import { getPushNotificationList, savePushNotification } from '@/api/cabakura/push-notification'
import { usePaging } from '@/hooks/usePaging'
import feedback from '@/utils/feedback'

const queryParams = reactive({ keyword: '' })
const dialogVisible = ref(false)
const saving = ref(false)
const form = reactive({ id: 0, title: '', content: '', link: '', mode: 'immediate', scheduled_at: '' })
const { pager, getLists, resetPage, resetParams } = usePaging({ fetchFun: getPushNotificationList, params: queryParams })

const openDialog = (row?: any) => {
    Object.assign(form, { id: row?.id || 0, title: row?.title || '', content: row?.content || '', link: row?.link || '', mode: row?.mode || 'immediate', scheduled_at: row?.scheduled_at ? new Date(row.scheduled_at * 1000).toISOString().slice(0, 19).replace('T', ' ') : '' })
    dialogVisible.value = true
}
const handleSave = async () => {
    if (!form.title.trim() || !form.content.trim()) return feedback.msgError('タイトルと内容を入力してください')
    if (form.mode === 'scheduled' && !form.scheduled_at) return feedback.msgError('配信日時を指定してください')
    saving.value = true
    try { await savePushNotification(form); dialogVisible.value = false; await getLists() } finally { saving.value = false }
}
getLists()
</script>
