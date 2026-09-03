<template>
    <div>
        <el-card class="!border-none" shadow="never">
            <el-form class="mb-[-16px]" :model="queryParams" :inline="true">
                <el-form-item label="订单信息">
                    <el-input
                        v-model="queryParams.keyword"
                        class="w-[280px]"
                        placeholder="订单号/会员/店铺"
                        clearable
                        @keyup.enter="resetPage"
                    />
                </el-form-item>
                <el-form-item label="订单状态">
                    <el-select v-model="queryParams.status" class="w-[180px]" clearable>
                        <el-option
                            v-for="(label, value) in OrderStatusMap"
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
                <el-table-column label="订单号" prop="order_no" min-width="180" />
                <el-table-column label="会员" prop="member_name" min-width="120" />
                <el-table-column label="电话号码" prop="member_mobile" min-width="150" />
                <el-table-column label="邮箱" prop="member_email" min-width="200" show-overflow-tooltip />
                <el-table-column label="店铺" prop="shop_name" min-width="150" />
                <el-table-column label="Cast" prop="cast_name" min-width="130" />
                <el-table-column label="来店时间" prop="visit_time" min-width="170" />
                <el-table-column label="支付时间" prop="payment_time_text" min-width="170" />
                <el-table-column label="人数" prop="people_count" min-width="80" />
                <el-table-column label="金额" min-width="120">
                    <template #default="{ row }">¥{{ row.amount.toLocaleString() }}</template>
                </el-table-column>
                <el-table-column label="支付" prop="pay_status_text" min-width="100" />
                <el-table-column label="备注" prop="remark" min-width="180" show-overflow-tooltip />
                <el-table-column label="状态" min-width="130">
                    <template #default="{ row }">
                        <el-tag :type="statusTagType(row.status)">{{ row.status_text }}</el-tag>
                    </template>
                </el-table-column>
                <el-table-column label="操作" width="170" fixed="right">
                    <template #default="{ row }">
                        <template v-if="row.status === 'confirmed'">
                            <el-button v-perms="['cabakura.order/cancel']" type="danger" link @click="handleCancel(row.id)">キャンセル</el-button>
                        </template>
                        <template v-else-if="!['cancelled', 'rejected'].includes(row.status)">
                            <el-button v-perms="['cabakura.order/confirm']" type="success" link @click="handleConfirm(row.id)">確認</el-button>
                            <el-button v-perms="['cabakura.order/reject']" type="danger" link @click="openReject(row.id)">拒否</el-button>
                        </template>
                        <el-icon v-else class="order-action-disabled" title="操作不可">
                            <CircleClose />
                        </el-icon>
                    </template>
                </el-table-column>
            </el-table>
            <div class="flex justify-end mt-4">
                <pagination v-model="pager" @change="getLists" />
            </div>
        </el-card>

        <el-dialog v-model="rejectVisible" title="拒绝预约" width="460px">
            <el-input
                v-model="rejectReason"
                type="textarea"
                :rows="4"
                placeholder="请填写拒绝原因"
            />
            <template #footer>
                <el-button @click="rejectVisible = false">取消</el-button>
                <el-button type="danger" @click="handleReject">确认拒绝</el-button>
            </template>
        </el-dialog>
    </div>
</template>

<script lang="ts" setup name="cabakuraOrderLists">
import {
    cancelCabakuraOrder,
    confirmCabakuraOrder,
    getCabakuraOrderList,
    rejectCabakuraOrder
} from '@/api/cabakura/order'
import { OrderStatusMap, statusTagType } from '@/enums/cabakura/status'
import { usePaging } from '@/hooks/usePaging'
import { CircleClose } from '@element-plus/icons-vue'
import { ElMessageBox } from 'element-plus'

const queryParams = reactive({
    keyword: '',
    status: ''
})

const rejectVisible = ref(false)
const currentId = ref<number>()
const rejectReason = ref('')

const { pager, getLists, resetPage, resetParams } = usePaging({
    fetchFun: getCabakuraOrderList,
    params: queryParams
})

const handleConfirm = async (id: number) => {
    try {
        await ElMessageBox.confirm('この予約を確定しますか？', '確認', {
            confirmButtonText: '確認',
            cancelButtonText: 'キャンセル',
            type: 'warning'
        })
        await confirmCabakuraOrder({ id })
        getLists()
    } catch {
        // Dialog cancellation and request errors require no local state change.
    }
}

const openReject = (id: number) => {
    currentId.value = id
    rejectReason.value = ''
    rejectVisible.value = true
}

const handleReject = async () => {
    try {
        await ElMessageBox.confirm('この予約を拒否しますか？', '確認', {
            confirmButtonText: '拒否',
            cancelButtonText: 'キャンセル',
            type: 'warning'
        })
        await rejectCabakuraOrder({ id: currentId.value, reason: rejectReason.value })
        rejectVisible.value = false
        getLists()
    } catch {
        // Dialog cancellation and request errors require no local state change.
    }
}

const handleCancel = async (id: number) => {
    try {
        await ElMessageBox.confirm('この予約をキャンセルしますか？', '確認', {
            confirmButtonText: 'キャンセルする',
            cancelButtonText: '戻る',
            type: 'warning'
        })
        await cancelCabakuraOrder({ id })
        getLists()
    } catch {
        // Dialog cancellation and request errors require no local state change.
    }
}

onActivated(() => {
    getLists()
})

getLists()

const orderRefreshTimer = window.setInterval(() => {
    getLists()
}, 15000)

onUnmounted(() => {
    window.clearInterval(orderRefreshTimer)
})
</script>
