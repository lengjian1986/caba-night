<template>
    <div>
        <el-card class="!border-none" shadow="never">
            <el-form class="mb-[-16px]" :model="queryParams" :inline="true">
                <el-form-item label="店铺信息">
                    <el-input
                        v-model="queryParams.keyword"
                        class="w-[280px]"
                        placeholder="店铺名/区域/许可证号"
                        clearable
                        @keyup.enter="resetPage"
                    />
                </el-form-item>
                <el-form-item label="审核状态">
                    <el-select v-model="queryParams.review_status" class="w-[180px]" clearable>
                        <el-option
                            v-for="(label, value) in ShopReviewStatusMap"
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
                <el-table-column label="店铺" min-width="180">
                    <template #default="{ row }">
                        <div class="font-medium">{{ row.name }}</div>
                        <div class="text-xs text-tx-secondary">{{ row.kana }}</div>
                    </template>
                </el-table-column>
                <el-table-column label="区域" prop="area" min-width="140" />
                <el-table-column label="许可证号" prop="license_no" min-width="170" />
                <el-table-column label="营业状态" prop="business_status" min-width="110" />
                <el-table-column label="预约开放" min-width="100">
                    <template #default="{ row }">
                        <el-tag :type="row.booking_enabled ? 'success' : 'info'">
                            {{ row.booking_enabled ? '已开放' : '未开放' }}
                        </el-tag>
                    </template>
                </el-table-column>
                <el-table-column label="审核状态" min-width="120">
                    <template #default="{ row }">
                        <el-tag :type="statusTagType(row.review_status)">
                            {{ row.review_status_text }}
                        </el-tag>
                    </template>
                </el-table-column>
                <el-table-column label="提交时间" prop="submitted_at" min-width="170" />
                <el-table-column label="操作" width="190" fixed="right">
                    <template #default="{ row }">
                        <el-button v-perms="['cabakura.shop/detail']" type="primary" link @click="openDetail(row.id)">审核</el-button>
                        <el-button v-perms="['cabakura.shop/approve']" type="success" link @click="handleApprove(row.id)">通过</el-button>
                        <el-button v-perms="['cabakura.shop/reject']" type="danger" link @click="openReject(row.id)">驳回</el-button>
                    </template>
                </el-table-column>
            </el-table>
            <div class="flex justify-end mt-4">
                <pagination v-model="pager" @change="getLists" />
            </div>
        </el-card>

        <el-drawer v-model="detailVisible" title="店铺审核详情" size="520px">
            <el-descriptions v-if="detail" :column="1" border>
                <el-descriptions-item label="店铺">{{ detail.name }}</el-descriptions-item>
                <el-descriptions-item label="区域">{{ detail.area }}</el-descriptions-item>
                <el-descriptions-item label="地址">{{ detail.address }}</el-descriptions-item>
                <el-descriptions-item label="营业时间">{{ detail.business_hours }}</el-descriptions-item>
                <el-descriptions-item label="价格区间">{{ detail.price_range }}</el-descriptions-item>
                <el-descriptions-item label="店铺说明">
                    <div class="whitespace-pre-wrap">{{ detail.description || '-' }}</div>
                </el-descriptions-item>
                <el-descriptions-item label="店铺Logo">
                    <el-image
                        v-if="detail.logo_image"
                        class="review-image"
                        :src="detail.logo_image"
                        :preview-src-list="[detail.logo_image]"
                        preview-teleported
                        fit="cover"
                    />
                    <span v-else>-</span>
                </el-descriptions-item>
                <el-descriptions-item label="店铺照片">
                    <div v-if="detail.shop_images?.length" class="review-image-list">
                        <el-image
                            v-for="image in detail.shop_images"
                            :key="image"
                            class="review-image"
                            :src="image"
                            :preview-src-list="detail.shop_images"
                            preview-teleported
                            fit="cover"
                        />
                    </div>
                    <span v-else>-</span>
                </el-descriptions-item>
                <el-descriptions-item label="许可证号">{{ detail.license.license_no }}</el-descriptions-item>
                <el-descriptions-item label="经营主体">{{ detail.license.holder_name }}</el-descriptions-item>
                <el-descriptions-item label="有效期">{{ detail.license.expires_at }}</el-descriptions-item>
                <el-descriptions-item label="许可证件">
                    <div v-if="detail.license.files?.length" class="review-image-list">
                        <el-image
                            v-for="image in detail.license.files"
                            :key="image"
                            class="review-image"
                            :src="image"
                            :preview-src-list="detail.license.files"
                            preview-teleported
                            fit="cover"
                        />
                    </div>
                    <span v-else>-</span>
                </el-descriptions-item>
            </el-descriptions>
            <el-timeline v-if="detail" class="mt-6">
                <el-timeline-item
                    v-for="log in detail.review_logs"
                    :key="`${log.action}-${log.time}`"
                    :timestamp="log.time"
                >
                    <div class="font-medium">{{ log.action }}</div>
                    <div class="text-sm text-tx-secondary">{{ log.operator }}：{{ log.remark }}</div>
                </el-timeline-item>
            </el-timeline>
        </el-drawer>

        <el-dialog v-model="rejectVisible" title="驳回店铺审核" width="460px">
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

<script lang="ts" setup name="cabakuraShopReview">
import {
    approveCabakuraShop,
    getCabakuraShopDetail,
    getCabakuraShopList,
    rejectCabakuraShop
} from '@/api/cabakura/shop'
import { ShopReviewStatusMap, statusTagType } from '@/enums/cabakura/status'
import { usePaging } from '@/hooks/usePaging'

const queryParams = reactive({
    keyword: '',
    review_status: ''
})

const detailVisible = ref(false)
const rejectVisible = ref(false)
const currentId = ref<number>()
const rejectReason = ref('')
const detail = ref<any>()

const { pager, getLists, resetPage, resetParams } = usePaging({
    fetchFun: getCabakuraShopList,
    params: queryParams
})

const openDetail = async (id: number) => {
    currentId.value = id
    detail.value = await getCabakuraShopDetail({ id })
    detailVisible.value = true
}

const handleApprove = async (id: number) => {
    await approveCabakuraShop({ id })
    getLists()
}

const openReject = (id: number) => {
    currentId.value = id
    rejectReason.value = ''
    rejectVisible.value = true
}

const handleReject = async () => {
    await rejectCabakuraShop({ id: currentId.value, reason: rejectReason.value })
    rejectVisible.value = false
    getLists()
}

onActivated(() => {
    getLists()
})

getLists()
</script>

<style lang="scss" scoped>
.review-image-list {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
}

.review-image {
    width: 72px;
    height: 72px;
    border-radius: 6px;
}
</style>
