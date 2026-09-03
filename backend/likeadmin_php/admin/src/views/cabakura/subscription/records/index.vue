<template>
    <div>
        <el-card class="!border-none" shadow="never">
            <el-form class="mb-[-16px]" :model="queryParams" :inline="true">
                <el-form-item label="記録情報">
                    <el-input
                        v-model="queryParams.keyword"
                        class="w-[280px]"
                        placeholder="会員ID/ニックネーム/Plan/取引番号"
                        clearable
                        @keyup.enter="resetPage"
                    />
                </el-form-item>
                <el-form-item label="支払状態">
                    <el-select v-model="queryParams.pay_status" class="w-[160px]" clearable>
                        <el-option label="支払済み" value="paid" />
                        <el-option label="支払待ち" value="pending" />
                        <el-option label="失敗" value="failed" />
                        <el-option label="返金済み" value="refunded" />
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
                <el-table-column label="Plan" prop="plan_name" min-width="180" />
                <el-table-column label="金額" min-width="120">
                    <template #default="{ row }">¥{{ Number(row.amount || 0).toLocaleString() }}</template>
                </el-table-column>
                <el-table-column label="種別" prop="action_text" min-width="120" />
                <el-table-column label="支払状態" min-width="120">
                    <template #default="{ row }">
                        <el-tag :type="payTagType(row.pay_status)">{{ row.pay_status_text }}</el-tag>
                    </template>
                </el-table-column>
                <el-table-column label="取引番号" prop="transaction_no" min-width="180" />
                <el-table-column label="記録日時" prop="create_time_text" min-width="170" />
            </el-table>
            <div class="flex justify-end mt-4">
                <pagination v-model="pager" @change="getLists" />
            </div>
        </el-card>
    </div>
</template>

<script lang="ts" setup name="cabakuraSubscriptionRecords">
import { getCabakuraSubscriptionRecords } from '@/api/cabakura/subscription'
import { usePaging } from '@/hooks/usePaging'

const queryParams = reactive({
    keyword: '',
    pay_status: ''
})

const { pager, getLists, resetPage, resetParams } = usePaging({
    fetchFun: getCabakuraSubscriptionRecords,
    params: queryParams
})

const payTagType = (status: string) =>
    ({
        paid: 'success',
        pending: 'warning',
        failed: 'danger',
        refunded: 'info'
    }[status] || 'info')

onActivated(() => {
    getLists()
})

getLists()
</script>
