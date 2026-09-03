<template>
    <div>
        <el-card class="!border-none" shadow="never">
            <el-form class="mb-[-16px]" :model="queryParams" :inline="true">
                <el-form-item label="会员信息">
                    <el-input
                        v-model="queryParams.keyword"
                        class="w-[280px]"
                        placeholder="会员ID/昵称/姓名/手机号"
                        clearable
                        @keyup.enter="resetPage"
                    />
                </el-form-item>
                <el-form-item label="本人認証ステータス">
                    <el-select v-model="queryParams.identity_status" class="w-[180px]" clearable>
                        <el-option
                            v-for="(label, value) in IdentityStatusMap"
                            :key="value"
                            :label="label"
                            :value="value"
                        />
                    </el-select>
                </el-form-item>
                <el-form-item>
                    <el-button type="primary" @click="resetPage">查询</el-button>
                    <el-button @click="resetParams">重置</el-button>
                </el-form-item>
            </el-form>
        </el-card>

        <el-card class="!border-none mt-4" shadow="never">
            <el-table size="large" v-loading="pager.loading" :data="pager.lists">
                <el-table-column label="会员ID" prop="member_no" min-width="110" />
                <el-table-column label="昵称" prop="nickname" min-width="130" />
                <el-table-column label="姓名" prop="real_name" min-width="120" />
                <el-table-column label="手机号" prop="mobile_masked" min-width="140" />
                <el-table-column label="等级" prop="level_name" min-width="130" />
                <el-table-column label="本人認証ステータス" min-width="120">
                    <template #default="{ row }">
                        <el-tag :type="statusTagType(row.identity_status)">
                            {{ row.identity_status_text }}
                        </el-tag>
                    </template>
                </el-table-column>
                <el-table-column label="账户状态" min-width="110">
                    <template #default="{ row }">
                        <el-tag :type="row.status === 'normal' ? 'success' : 'danger'">
                            {{ row.status_text }}
                        </el-tag>
                    </template>
                </el-table-column>
                <el-table-column label="余额" min-width="120">
                    <template #default="{ row }">¥{{ row.wallet_balance.toLocaleString() }}</template>
                </el-table-column>
                <el-table-column label="预约" prop="order_count" min-width="90" />
                <el-table-column label="收藏" prop="favorite_count" min-width="90" />
                <el-table-column label="评价" prop="review_count" min-width="90" />
                <el-table-column label="注册时间" prop="create_time_text" min-width="170" />
                <el-table-column label="操作" fixed="right" min-width="100">
                    <template #default="{ row }">
                        <el-button
                            v-perms="['cabakura.member/updateProfile']"
                            type="primary"
                            link
                            @click="goDetail(row.id)"
                        >
                            编辑
                        </el-button>
                    </template>
                </el-table-column>
            </el-table>
            <div class="flex justify-end mt-4">
                <pagination v-model="pager" @change="getLists" />
            </div>
        </el-card>
    </div>
</template>

<script lang="ts" setup name="cabakuraMemberLists">
import { getCabakuraMemberList } from '@/api/cabakura/member'
import { IdentityStatusMap, statusTagType } from '@/enums/cabakura/status'
import { usePaging } from '@/hooks/usePaging'

const router = useRouter()

const queryParams = reactive({
    keyword: '',
    identity_status: ''
})

const { pager, getLists, resetPage, resetParams } = usePaging({
    fetchFun: getCabakuraMemberList,
    params: queryParams
})

const goDetail = (id: number) => {
    router.push({
        path: '/member/detail',
        query: { id }
    })
}

onActivated(() => {
    getLists()
})

getLists()
</script>
