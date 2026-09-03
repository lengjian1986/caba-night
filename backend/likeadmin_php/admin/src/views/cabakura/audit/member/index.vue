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
                <el-table-column label="证件图片" min-width="120">
                    <template #default="{ row }">
                        <el-image
                            v-if="row.identity_image"
                            class="identity-thumb"
                            :src="row.identity_image"
                            :preview-src-list="[row.identity_image]"
                            preview-teleported
                            fit="cover"
                        />
                        <span v-else class="text-tx-secondary">未上传</span>
                    </template>
                </el-table-column>
                <el-table-column label="本人認証ステータス" min-width="120">
                    <template #default="{ row }">
                        <el-tag :type="statusTagType(row.identity_status)">
                            {{ row.identity_status_text }}
                        </el-tag>
                    </template>
                </el-table-column>
                <el-table-column label="注册时间" prop="create_time_text" min-width="170" />
                <el-table-column label="操作" width="180" fixed="right">
                    <template #default="{ row }">
                        <el-button
                            v-perms="['cabakura.member/approveIdentity']"
                            type="success"
                            link
                            @click="handleApprove(row.id)"
                        >
                            通过
                        </el-button>
                        <el-button
                            v-perms="['cabakura.member/rejectIdentity']"
                            type="danger"
                            link
                            @click="openReject(row.id)"
                        >
                            驳回
                        </el-button>
                    </template>
                </el-table-column>
            </el-table>
            <div class="flex justify-end mt-4">
                <pagination v-model="pager" @change="getLists" />
            </div>
        </el-card>

        <el-dialog v-model="rejectVisible" title="驳回本人认证" width="460px">
            <el-input
                v-model="rejectReason"
                type="textarea"
                :rows="4"
                placeholder="请填写驳回原因"
            />
            <template #footer>
                <el-button @click="rejectVisible = false">取消</el-button>
                <el-button type="danger" @click="handleReject">确认驳回</el-button>
            </template>
        </el-dialog>
    </div>
</template>

<script lang="ts" setup name="cabakuraAuditMember">
import {
    approveCabakuraMemberIdentity,
    getCabakuraMemberList,
    rejectCabakuraMemberIdentity
} from '@/api/cabakura/member'
import { IdentityStatusMap, statusTagType } from '@/enums/cabakura/status'
import { usePaging } from '@/hooks/usePaging'

const queryParams = reactive({
    keyword: '',
    identity_status: 'reviewing'
})

const rejectVisible = ref(false)
const rejectReason = ref('')
const currentId = ref<number>()

const { pager, getLists, resetPage, resetParams } = usePaging({
    fetchFun: getCabakuraMemberList,
    params: queryParams
})

const handleApprove = async (id: number) => {
    await approveCabakuraMemberIdentity({ id })
    getLists()
}

const openReject = (id: number) => {
    currentId.value = id
    rejectReason.value = ''
    rejectVisible.value = true
}

const handleReject = async () => {
    await rejectCabakuraMemberIdentity({ id: currentId.value, reason: rejectReason.value })
    rejectVisible.value = false
    getLists()
}

onActivated(() => {
    getLists()
})

getLists()
</script>

<style lang="scss" scoped>
.identity-thumb {
    width: 56px;
    height: 56px;
    border-radius: 6px;
}
</style>
