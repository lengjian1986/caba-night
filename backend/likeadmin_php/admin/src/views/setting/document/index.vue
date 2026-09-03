<template>
    <div class="document-setting">
        <el-card class="!border-none" shadow="never">
            <template #header>
                <div class="card-head">
                    <span class="font-medium">ドキュメント設定</span>
                    <el-button type="primary" @click="openDialog()">追加</el-button>
                </div>
            </template>

            <el-table v-loading="loading" :data="formData.documents" size="large">
                <el-table-column label="規約名" prop="title" min-width="180" />
                <el-table-column label="利用先" prop="usage_target" min-width="180" />
                <el-table-column label="内容" min-width="320">
                    <template #default="{ row }">
                        <div class="content-preview">{{ row.content || '-' }}</div>
                    </template>
                </el-table-column>
                <el-table-column label="ステータス" width="130">
                    <template #default="{ row }">
                        <el-tag :type="row.status === 'enabled' ? 'success' : 'info'">
                            {{ row.status === 'enabled' ? '公開中' : '非公開' }}
                        </el-tag>
                    </template>
                </el-table-column>
                <el-table-column label="操作" width="150" fixed="right">
                    <template #default="{ $index, row }">
                        <el-button type="primary" link @click="openDialog(row, $index)">編集</el-button>
                        <el-button type="danger" link @click="removeDocument($index)">削除</el-button>
                    </template>
                </el-table-column>
            </el-table>

            <el-empty v-if="!loading && !formData.documents.length" description="規約はまだ登録されていません。" />
        </el-card>

        <footer-btns v-perms="['setting.document/setConfig']">
            <el-button type="primary" :loading="saving" @click="saveConfig">保存</el-button>
        </footer-btns>

        <el-dialog
            v-model="dialogVisible"
            :title="editingIndex >= 0 ? '規約編集' : '規約追加'"
            width="720px"
            destroy-on-close
        >
            <el-form :model="documentForm" label-position="top">
                <el-form-item label="規約名" required>
                    <el-input v-model="documentForm.title" placeholder="例：店舗利用規約" />
                </el-form-item>
                <el-form-item label="利用先" required>
                    <el-input v-model="documentForm.usage_target" placeholder="例：店舗 / キャスト / 会員" />
                </el-form-item>
                <el-form-item label="内容" required>
                    <el-input
                        v-model="documentForm.content"
                        type="textarea"
                        :rows="12"
                        placeholder="本文を入力してください"
                    />
                </el-form-item>
                <el-form-item label="ステータス">
                    <el-radio-group v-model="documentForm.status">
                        <el-radio-button value="enabled">公開中</el-radio-button>
                        <el-radio-button value="disabled">非公開</el-radio-button>
                    </el-radio-group>
                </el-form-item>
            </el-form>
            <template #footer>
                <el-button @click="dialogVisible = false">キャンセル</el-button>
                <el-button type="primary" @click="confirmDocument">保存</el-button>
            </template>
        </el-dialog>
    </div>
</template>

<script setup lang="ts" name="documentSetting">
import { getDocumentConfig, setDocumentConfig } from '@/api/setting/document'
import feedback from '@/utils/feedback'
import { ElMessageBox } from 'element-plus'

interface DocumentItem {
    title: string
    usage_target: string
    content: string
    status: 'enabled' | 'disabled'
}

const createDocument = (): DocumentItem => ({
    title: '',
    usage_target: '',
    content: '',
    status: 'enabled'
})

const loading = ref(false)
const saving = ref(false)
const dialogVisible = ref(false)
const editingIndex = ref(-1)
const formData = reactive({
    documents: [] as DocumentItem[]
})
const documentForm = reactive<DocumentItem>(createDocument())

const normalizeDocument = (item: Partial<DocumentItem>): DocumentItem => ({
    title: item.title || '',
    usage_target: item.usage_target || '',
    content: item.content || '',
    status: item.status === 'disabled' ? 'disabled' : 'enabled'
})

const loadConfig = async () => {
    loading.value = true
    try {
        const data = await getDocumentConfig()
        formData.documents = Array.isArray(data.documents)
            ? data.documents.map((item: Partial<DocumentItem>) => normalizeDocument(item))
            : []
    } finally {
        loading.value = false
    }
}

const openDialog = (row?: DocumentItem, index = -1) => {
    editingIndex.value = index
    Object.assign(documentForm, row ? normalizeDocument(row) : createDocument())
    dialogVisible.value = true
}

const confirmDocument = () => {
    if (!documentForm.title.trim()) {
        feedback.msgError('規約名を入力してください')
        return
    }
    if (!documentForm.usage_target.trim()) {
        feedback.msgError('利用先を入力してください')
        return
    }
    if (!documentForm.content.trim()) {
        feedback.msgError('内容を入力してください')
        return
    }

    const data = normalizeDocument(documentForm)
    if (editingIndex.value >= 0) {
        formData.documents.splice(editingIndex.value, 1, data)
    } else {
        formData.documents.push(data)
    }
    dialogVisible.value = false
}

const removeDocument = async (index: number) => {
    try {
        await ElMessageBox.confirm('この規約を削除しますか？', '削除確認', {
            confirmButtonText: '削除',
            cancelButtonText: 'キャンセル',
            type: 'warning',
            confirmButtonClass: 'el-button--danger'
        })
        formData.documents.splice(index, 1)
    } catch {}
}

const saveConfig = async () => {
    saving.value = true
    try {
        await setDocumentConfig({
            documents: formData.documents
        })
        feedback.msgSuccess('保存しました')
        await loadConfig()
    } finally {
        saving.value = false
    }
}

loadConfig()
</script>

<style lang="scss" scoped>
.document-setting {
    padding-bottom: 64px;
}

.card-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
}

.content-preview {
    display: -webkit-box;
    max-height: 44px;
    overflow: hidden;
    color: #667085;
    line-height: 22px;
    -webkit-box-orient: vertical;
    -webkit-line-clamp: 2;
}
</style>
