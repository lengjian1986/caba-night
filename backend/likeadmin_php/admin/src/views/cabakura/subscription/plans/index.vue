<template>
    <div>
        <el-card class="!border-none" shadow="never">
            <el-form class="mb-[-16px]" :model="queryParams" :inline="true">
                <el-form-item label="Plan">
                    <el-input
                        v-model="queryParams.keyword"
                        class="w-[260px]"
                        placeholder="Plan名/説明"
                        clearable
                        @keyup.enter="resetPage"
                    />
                </el-form-item>
                <el-form-item label="状態">
                    <el-select v-model="queryParams.is_enabled" class="w-[150px]" clearable>
                        <el-option label="有効" value="1" />
                        <el-option label="無効" value="0" />
                    </el-select>
                </el-form-item>
                <el-form-item>
                    <el-button type="primary" @click="resetPage">検索</el-button>
                    <el-button @click="resetParams">リセット</el-button>
                    <el-button
                        v-perms="['cabakura.subscription/savePlan']"
                        class="ml-2"
                        type="primary"
                        @click="openPlanDialog()"
                    >
                        Plan作成
                    </el-button>
                </el-form-item>
            </el-form>
        </el-card>

        <el-card class="!border-none mt-4" shadow="never">
            <el-table size="large" v-loading="pager.loading" :data="pager.lists">
                <el-table-column label="Plan名" prop="name" min-width="180" />
                <el-table-column label="価格" min-width="120">
                    <template #default="{ row }">¥{{ Number(row.price || 0).toLocaleString() }}</template>
                </el-table-column>
                <el-table-column label="期間" min-width="110">
                    <template #default="{ row }">{{ row.duration_days }}日</template>
                </el-table-column>
                <el-table-column label="説明" prop="description" min-width="240" show-overflow-tooltip />
                <el-table-column label="特典" min-width="260">
                    <template #default="{ row }">
                        <div class="benefit-tags">
                            <el-tag v-for="benefit in row.benefits" :key="benefit" size="small">
                                {{ benefit }}
                            </el-tag>
                            <span v-if="!row.benefits?.length">-</span>
                        </div>
                    </template>
                </el-table-column>
                <el-table-column label="有効" width="100">
                    <template #default="{ row }">
                        <el-switch
                            v-model="row.is_enabled"
                            v-perms="['cabakura.subscription/switchPlan']"
                            :active-value="1"
                            :inactive-value="0"
                            @change="handleSwitchPlan(row)"
                        />
                    </template>
                </el-table-column>
                <el-table-column label="並び順" prop="sort" width="90" />
                <el-table-column label="操作" width="110" fixed="right">
                    <template #default="{ row }">
                        <el-button
                            v-perms="['cabakura.subscription/savePlan']"
                            type="primary"
                            link
                            @click="openPlanDialog(row)"
                        >
                            編集
                        </el-button>
                    </template>
                </el-table-column>
            </el-table>
            <div class="flex justify-end mt-4">
                <pagination v-model="pager" @change="getLists" />
            </div>
        </el-card>

        <el-dialog
            v-model="planDialogVisible"
            :title="planForm.id ? 'Plan編集' : 'Plan作成'"
            width="620px"
        >
            <el-form :model="planForm" label-width="90px">
                <el-form-item label="Plan名" required>
                    <el-input v-model="planForm.name" placeholder="例 Premium Monthly" />
                </el-form-item>
                <el-form-item label="価格" required>
                    <el-input-number
                        v-model="planForm.price"
                        class="w-full"
                        :min="0"
                        :controls="false"
                    />
                </el-form-item>
                <el-form-item label="期間">
                    <el-input-number
                        v-model="planForm.duration_days"
                        class="w-full"
                        :min="1"
                        :controls="false"
                    />
                </el-form-item>
                <el-form-item label="説明">
                    <el-input
                        v-model="planForm.description"
                        type="textarea"
                        :rows="3"
                        placeholder="Plan説明を入力"
                    />
                </el-form-item>
                <el-form-item label="特典">
                    <div class="tag-editor">
                        <el-tag
                            v-for="benefit in planForm.benefits"
                            :key="benefit"
                            closable
                            @close="removeBenefit(benefit)"
                        >
                            {{ benefit }}
                        </el-tag>
                        <el-input
                            v-model="benefitInput"
                            class="tag-input"
                            placeholder="特典を入力して Enter"
                            @keyup.enter="commitBenefit"
                            @blur="commitBenefit"
                        />
                    </div>
                </el-form-item>
                <el-form-item label="並び順">
                    <el-input-number
                        v-model="planForm.sort"
                        class="w-full"
                        :min="0"
                        :controls="false"
                    />
                </el-form-item>
                <el-form-item label="有効">
                    <el-switch
                        v-model="planForm.is_enabled"
                        :active-value="1"
                        :inactive-value="0"
                    />
                </el-form-item>
            </el-form>
            <template #footer>
                <el-button @click="planDialogVisible = false">キャンセル</el-button>
                <el-button type="primary" :loading="saving" @click="handleSavePlan">
                    保存
                </el-button>
            </template>
        </el-dialog>
    </div>
</template>

<script lang="ts" setup name="cabakuraSubscriptionPlans">
import {
    getCabakuraSubscriptionPlans,
    saveCabakuraSubscriptionPlan,
    switchCabakuraSubscriptionPlan
} from '@/api/cabakura/subscription'
import { usePaging } from '@/hooks/usePaging'
import feedback from '@/utils/feedback'

const queryParams = reactive({
    keyword: '',
    is_enabled: ''
})

const planDialogVisible = ref(false)
const saving = ref(false)
const benefitInput = ref('')
const planForm = reactive({
    id: 0,
    name: '',
    price: 0,
    duration_days: 30,
    description: '',
    benefits: [] as string[],
    is_enabled: 1,
    sort: 0
})

const { pager, getLists, resetPage, resetParams } = usePaging({
    fetchFun: getCabakuraSubscriptionPlans,
    params: queryParams
})

const openPlanDialog = (row?: any) => {
    Object.assign(planForm, {
        id: row?.id || 0,
        name: row?.name || '',
        price: Number(row?.price || 0),
        duration_days: Number(row?.duration_days || 30),
        description: row?.description || '',
        benefits: Array.isArray(row?.benefits) ? [...row.benefits] : [],
        is_enabled: row?.is_enabled ?? 1,
        sort: Number(row?.sort || 0)
    })
    benefitInput.value = ''
    planDialogVisible.value = true
}

const commitBenefit = () => {
    const benefit = benefitInput.value.trim()
    if (!benefit) {
        benefitInput.value = ''
        return
    }
    if (!planForm.benefits.includes(benefit)) {
        planForm.benefits.push(benefit)
    }
    benefitInput.value = ''
}

const removeBenefit = (benefit: string) => {
    planForm.benefits = planForm.benefits.filter((item) => item !== benefit)
}

const handleSavePlan = async () => {
    commitBenefit()
    if (!planForm.name.trim()) {
        feedback.msgError('Plan名を入力してください')
        return
    }
    saving.value = true
    try {
        await saveCabakuraSubscriptionPlan(planForm)
        planDialogVisible.value = false
        await getLists()
    } finally {
        saving.value = false
    }
}

const handleSwitchPlan = async (row: any) => {
    try {
        await switchCabakuraSubscriptionPlan({
            id: row.id,
            is_enabled: row.is_enabled
        })
    } catch (error) {
        row.is_enabled = row.is_enabled ? 0 : 1
        throw error
    }
}

onActivated(() => {
    getLists()
})

getLists()
</script>

<style lang="scss" scoped>
.benefit-tags,
.tag-editor {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
}

.tag-editor {
    width: 100%;
}

.tag-input {
    flex: 1 1 180px;
    min-width: 180px;
}
</style>
