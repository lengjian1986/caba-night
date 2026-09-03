<template>
    <div>
        <el-card class="!border-none" shadow="never">
            <el-form class="mb-[-16px]" :model="queryParams" :inline="true">
                <el-form-item label="会員/Plan">
                    <el-input
                        v-model="queryParams.keyword"
                        class="w-[280px]"
                        placeholder="会員ID/ニックネーム/電話番号/Plan"
                        clearable
                        @keyup.enter="resetPage"
                    />
                </el-form-item>
                <el-form-item label="状態">
                    <el-select v-model="queryParams.status" class="w-[160px]" clearable>
                        <el-option label="契約中" value="active" />
                        <el-option label="期限切れ" value="expired" />
                        <el-option label="解約済み" value="cancelled" />
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
                <el-table-column label="会員ID" prop="member_no" min-width="120" />
                <el-table-column label="ニックネーム" prop="nickname" min-width="140" />
                <el-table-column label="電話番号" prop="mobile_masked" min-width="140" />
                <el-table-column label="Plan" prop="plan_name" min-width="180" />
                <el-table-column label="開始日時" prop="start_time_text" min-width="170" />
                <el-table-column label="終了日時" prop="end_time_text" min-width="170" />
                <el-table-column label="自動更新" min-width="100">
                    <template #default="{ row }">
                        <el-tag :type="row.auto_renew ? 'success' : 'info'">
                            {{ row.auto_renew ? 'ON' : 'OFF' }}
                        </el-tag>
                    </template>
                </el-table-column>
                <el-table-column label="状態" min-width="120">
                    <template #default="{ row }">
                        <el-tag :type="statusTagType(row.status)">{{ row.status_text }}</el-tag>
                    </template>
                </el-table-column>
            </el-table>
            <div class="flex justify-end mt-4">
                <pagination v-model="pager" @change="getLists" />
            </div>
        </el-card>
    </div>
</template>

<script lang="ts" setup name="cabakuraSubscriptionUsers">
import { getCabakuraSubscriptionUsers } from '@/api/cabakura/subscription'
import { usePaging } from '@/hooks/usePaging'

const queryParams = reactive({
    keyword: '',
    status: ''
})

const { pager, getLists, resetPage, resetParams } = usePaging({
    fetchFun: getCabakuraSubscriptionUsers,
    params: queryParams
})

const statusTagType = (status: string) =>
    ({
        active: 'success',
        expired: 'warning',
        cancelled: 'info'
    }[status] || 'info')

onActivated(() => {
    getLists()
})

getLists()
</script>
