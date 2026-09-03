<template>
    <div>
        <el-card class="!border-none" shadow="never">
            <div class="setting-head">
                <div>
                    <div class="setting-title">暗卷回答设定</div>
                    <div class="text-sm text-tx-secondary">维护 Cast 资料中需要选择的下拉选项。</div>
                </div>
            </div>
        </el-card>

        <div v-loading="loading" class="setting-group-list">
            <el-card
                v-for="group in groups"
                :key="group.key"
                class="!border-none mt-4"
                shadow="never"
            >
                <div class="group-title">{{ group.label }}</div>
                <div class="field-grid">
                    <div v-for="field in group.fields" :key="field.type" class="field-panel">
                        <div class="field-head">
                            <div>
                                <div class="field-title">{{ field.name }}</div>
                                <div class="field-code">{{ field.type }}</div>
                            </div>
                            <el-button type="primary" @click="openOptionDialog(field)">添加选项</el-button>
                        </div>

                        <el-table :data="field.options" size="large">
                            <el-table-column label="选项名称" prop="name" min-width="130" />
                            <el-table-column label="选项值" prop="value" min-width="130" />
                            <el-table-column label="状态" width="90">
                                <template #default="{ row }">
                                    <el-tag :type="row.status ? 'success' : 'info'">
                                        {{ row.status ? '启用' : '停用' }}
                                    </el-tag>
                                </template>
                            </el-table-column>
                            <el-table-column label="排序" prop="sort" width="80" />
                            <el-table-column label="备注" prop="remark" min-width="140" show-tooltip-when-overflow />
                            <el-table-column label="操作" width="120" fixed="right">
                                <template #default="{ row }">
                                    <el-button type="primary" link @click="openOptionDialog(field, row)">
                                        编辑
                                    </el-button>
                                    <el-button type="danger" link @click="handleDeleteOption(row.id)">
                                        删除
                                    </el-button>
                                </template>
                            </el-table-column>
                        </el-table>
                        <el-empty
                            v-if="!field.options.length"
                            description="暂无选项"
                            :image-size="60"
                        />
                    </div>
                </div>
            </el-card>
        </div>

        <el-dialog
            v-model="optionDialogVisible"
            :title="optionForm.id ? '编辑选项' : '添加选项'"
            width="520px"
        >
            <el-form :model="optionForm" label-width="90px">
                <el-form-item label="所属字段">
                    <el-input :model-value="activeField?.name || '-'" disabled />
                </el-form-item>
                <el-form-item label="选项名称" required>
                    <el-input v-model="optionForm.name" placeholder="例如 清潔感がある" />
                </el-form-item>
                <el-form-item label="选项值" required>
                    <el-input v-model="optionForm.value" placeholder="例如 clean" />
                </el-form-item>
                <el-form-item label="排序">
                    <el-input-number
                        v-model="optionForm.sort"
                        class="w-full"
                        :min="0"
                        :controls="false"
                    />
                </el-form-item>
                <el-form-item label="状态">
                    <el-switch
                        v-model="optionForm.status"
                        :active-value="1"
                        :inactive-value="0"
                    />
                </el-form-item>
                <el-form-item label="备注">
                    <el-input
                        v-model="optionForm.remark"
                        type="textarea"
                        :rows="3"
                        placeholder="可选"
                    />
                </el-form-item>
            </el-form>
            <template #footer>
                <el-button @click="optionDialogVisible = false">取消</el-button>
                <el-button type="primary" :loading="saving" @click="handleSaveOption">
                    保存
                </el-button>
            </template>
        </el-dialog>
    </div>
</template>

<script lang="ts" setup name="cabakuraAnswerSetting">
import {
    deleteCabakuraAnswerSettingOption,
    getCabakuraAnswerSettingFields,
    saveCabakuraAnswerSettingOption
} from '@/api/cabakura/answer-setting'
import feedback from '@/utils/feedback'

const loading = ref(false)
const saving = ref(false)
const groups = ref<any[]>([])
const optionDialogVisible = ref(false)
const activeField = ref<any>()
const optionForm = reactive({
    id: 0,
    type: '',
    name: '',
    value: '',
    sort: 0,
    status: 1,
    remark: ''
})

const loadFields = async () => {
    loading.value = true
    try {
        groups.value = await getCabakuraAnswerSettingFields()
    } finally {
        loading.value = false
    }
}

const openOptionDialog = (field: any, row?: any) => {
    activeField.value = field
    Object.assign(optionForm, {
        id: row?.id || 0,
        type: field.type,
        name: row?.name || '',
        value: row?.value || '',
        sort: row?.sort || 0,
        status: row?.status ?? 1,
        remark: row?.remark || ''
    })
    optionDialogVisible.value = true
}

const handleSaveOption = async () => {
    saving.value = true
    try {
        await saveCabakuraAnswerSettingOption(optionForm)
        optionDialogVisible.value = false
        await loadFields()
    } finally {
        saving.value = false
    }
}

const handleDeleteOption = async (id: number) => {
    await feedback.confirm('确定要删除这个选项？')
    await deleteCabakuraAnswerSettingOption({ id })
    await loadFields()
}

onActivated(() => {
    loadFields()
})

loadFields()
</script>

<style lang="scss" scoped>
.setting-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
}

.setting-title {
    font-size: 18px;
    font-weight: 600;
}

.setting-group-list {
    min-height: 180px;
}

.group-title {
    margin-bottom: 14px;
    font-size: 16px;
    font-weight: 600;
}

.field-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(460px, 1fr));
    gap: 14px;
}

.field-panel {
    min-width: 0;
    padding: 14px;
    border: 1px solid var(--el-border-color-light);
    border-radius: 6px;
}

.field-head {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 12px;
    margin-bottom: 12px;
}

.field-title {
    font-weight: 600;
}

.field-code {
    margin-top: 2px;
    color: var(--el-text-color-secondary);
    font-size: 12px;
}
</style>
