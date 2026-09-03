<template>
    <div>
        <el-card class="!border-none" shadow="never">
            <el-form :inline="true" :model="queryParams">
                <el-form-item label="利用規約"><el-input v-model="queryParams.keyword" class="w-[280px]" placeholder="規約名/タイトルで検索" clearable @keyup.enter="resetPage" /></el-form-item>
                <el-form-item label="表示"><el-select v-model="queryParams.is_show" class="w-[150px]" clearable placeholder="すべて"><el-option label="表示" value="1" /><el-option label="非表示" value="0" /></el-select></el-form-item>
                <el-form-item><el-button type="primary" @click="resetPage">検索</el-button><el-button @click="resetParams">リセット</el-button><el-button v-perms="['cabakura.terms/save']" type="primary" @click="openDialog()">規約作成</el-button></el-form-item>
            </el-form>
        </el-card>
        <el-card class="!border-none mt-4" shadow="never">
            <div v-loading="pager.loading" class="terms-list">
                <el-card v-for="row in pager.lists" :key="row.id" class="term-item" shadow="never">
                    <div class="term-main"><div class="term-title">{{ row.title }}</div><div class="term-meta"><span>規約名：{{ row.name }}</span><span>適用箇所：{{ appliesText(row.applies_to) }}</span><span>更新日時：{{ formatTime(row.update_time, row.updated_at) }}</span></div></div>
                    <div class="term-actions"><el-switch v-model="row.is_show" v-perms="['cabakura.terms/switchShow']" :active-value="1" :inactive-value="0" @change="switchShow(row)" /><el-tag :type="row.is_show ? 'success' : 'info'">{{ row.is_show ? '表示' : '非表示' }}</el-tag><el-button v-perms="['cabakura.terms/save']" type="primary" link @click="openDialog(row)">編集</el-button></div>
                </el-card>
                <el-empty v-if="!pager.loading && !pager.lists.length" description="データなし" />
            </div>
            <div class="flex justify-end mt-4"><pagination v-model="pager" @change="getLists" /></div>
        </el-card>
        <el-dialog v-model="dialogVisible" :title="form.id ? '利用規約編集' : '利用規約作成'" width="720px">
            <el-form :model="form" label-width="120px">
                <el-form-item label="規約名" required><el-input v-model="form.name" placeholder="例：利用規約" /></el-form-item>
                <el-form-item label="タイトル" required><el-input v-model="form.title" placeholder="タイトルを入力してください" /></el-form-item>
                <el-form-item label="適用箇所"><el-input v-model="form.applies_to" placeholder="例：会員登録ページ、予約画面" maxlength="80" /></el-form-item>
                <el-form-item label="内容" required><el-input v-model="form.content" type="textarea" :rows="12" placeholder="規約内容を入力してください" /></el-form-item>
                <el-form-item label="表示"><el-switch v-model="form.is_show" :active-value="1" :inactive-value="0" /></el-form-item>
                <el-form-item label="排序"><el-input-number v-model="form.sort" :min="0" :controls="false" /></el-form-item>
            </el-form>
            <template #footer><el-button @click="dialogVisible = false">キャンセル</el-button><el-button type="primary" :loading="saving" @click="save">保存</el-button></template>
        </el-dialog>
    </div>
</template>
<script lang="ts" setup name="cabakuraTerms">
import { getCabakuraTerms, saveCabakuraTerms, switchCabakuraTermsShow } from '@/api/cabakura/terms'
import { usePaging } from '@/hooks/usePaging'
import feedback from '@/utils/feedback'
const queryParams = reactive({ keyword: '', is_show: '' }); const dialogVisible = ref(false); const saving = ref(false)
const form = reactive<any>({ id: 0, name: '', title: '', content: '', applies_to: 'all', is_show: 1, sort: 0 })
const { pager, getLists, resetPage, resetParams } = usePaging({ fetchFun: getCabakuraTerms, params: queryParams })
const appliesText = (value: string) => ({ all: '全部页面', register: '注册页面', order: '预约/支付页面', mypage: '个人中心' } as any)[value] || value
const formatTime = (value: unknown, fallback = '-') => {
    const numeric = Number(value)
    if (Number.isFinite(numeric) && numeric > 0) {
        const date = new Date((numeric < 100000000000 ? numeric : numeric / 1000) * 1000)
        if (!Number.isNaN(date.getTime())) {
            return new Intl.DateTimeFormat('ja-JP', { timeZone: 'Asia/Tokyo', year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', hour12: false }).format(date).replace(/\//g, '-')
        }
    }
    return fallback || '-'
}
const openDialog = (row?: any) => { Object.assign(form, { id: 0, name: '', title: '', content: '', applies_to: 'all', is_show: 1, sort: 0, ...row }); dialogVisible.value = true }
const save = async () => { if (!form.name.trim() || !form.title.trim() || !form.content.trim()) return feedback.msgError('規約名、タイトル、内容は必須です'); saving.value = true; try { await saveCabakuraTerms(form); dialogVisible.value = false; await getLists() } finally { saving.value = false } }
const switchShow = async (row: any) => { await switchCabakuraTermsShow({ id: row.id, is_show: row.is_show }) }
onActivated(() => getLists()); getLists()
</script>
<style scoped>
.term-item { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; }
.term-main { min-width: 0; }
.term-title { font-size: 16px; font-weight: 600; color: var(--el-text-color-primary); }
.term-meta { display: flex; flex-wrap: wrap; gap: 24px; margin-top: 8px; color: var(--el-text-color-secondary); font-size: 13px; }
.term-actions { display: flex; align-items: center; gap: 18px; margin-left: 20px; white-space: nowrap; }
</style>
