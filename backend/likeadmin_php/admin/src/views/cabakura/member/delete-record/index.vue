<template>
    <div>
        <el-card class="!border-none" shadow="never">
            <el-form class="mb-[-16px]" :model="queryParams" :inline="true">
                <el-form-item label="会員情報">
                    <el-input
                        v-model="queryParams.keyword"
                        class="w-[280px]"
                        placeholder="会員ID/ニックネーム/電話番号/理由"
                        clearable
                        @keyup.enter="resetPage"
                    />
                </el-form-item>
                <el-form-item label="状態">
                    <el-select v-model="queryParams.status" class="w-[160px]" clearable>
                        <el-option label="申請中" value="requested" />
                        <el-option label="消去済み" value="processed" />
                        <el-option label="キャンセル" value="cancelled" />
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
                <el-table-column label="理由" prop="reason" min-width="260" show-overflow-tooltip />
                <el-table-column label="状態" min-width="120">
                    <template #default="{ row }">
                        <el-tag :type="statusTagType(row.status)">
                            {{ row.status_text }}
                        </el-tag>
                    </template>
                </el-table-column>
                <el-table-column label="申請日時" prop="requested_time_text" min-width="170" />
                <el-table-column label="処理日時" prop="processed_time_text" min-width="170" />
                <el-table-column label="処理者" prop="operator" min-width="120" />
                <el-table-column label="備考" prop="remark" min-width="220" show-overflow-tooltip />
            </el-table>
            <div class="flex justify-end mt-4">
                <pagination v-model="pager" @change="getLists" />
            </div>
        </el-card>
    </div>
</template>

<script lang="ts" setup name="cabakuraMemberDeleteRecord">
import { getCabakuraMemberDeleteRecords } from '@/api/cabakura/member'
import { usePaging } from '@/hooks/usePaging'

const queryParams = reactive({
    keyword: '',
    status: ''
})

const { pager, getLists, resetPage, resetParams } = usePaging({
    fetchFun: getCabakuraMemberDeleteRecords,
    params: queryParams
})

const statusTagType = (status: string) => {
    return (
        {
            requested: 'warning',
            processed: 'success',
            cancelled: 'info'
        }[status] || 'info'
    )
}

onActivated(() => {
    getLists()
})

getLists()
</script>
