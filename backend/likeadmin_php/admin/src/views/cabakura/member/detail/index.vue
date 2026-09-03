<template>
    <div>
        <el-page-header class="mb-4" content="会员详情" @back="router.back()" />

        <el-row :gutter="16">
            <el-col :span="8">
                <el-card class="!border-none" shadow="never" v-loading="loading">
                    <div class="text-lg font-medium">{{ detail.nickname || '-' }}</div>
                    <div class="mt-1 text-sm text-tx-secondary">{{ detail.member_no || '-' }}</div>

                    <div class="mt-5 space-y-3 text-sm">
                        <div class="flex justify-between">
                            <span class="text-tx-secondary">手机号</span>
                            <span>{{ detail.mobile_masked || '-' }}</span>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-tx-secondary">会员等级</span>
                            <span>{{ detail.level_name || '-' }}</span>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-tx-secondary">本人認証ステータス</span>
                            <el-tag :type="statusTagType(detail.identity_status)">
                                {{ detail.identity_status_text || '-' }}
                            </el-tag>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-tx-secondary">账户状态</span>
                            <el-tag :type="detail.status === 'normal' ? 'success' : 'danger'">
                                {{ detail.status_text || '-' }}
                            </el-tag>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-tx-secondary">钱包余额</span>
                            <span>¥{{ Number(detail.wallet_balance || 0).toLocaleString() }}</span>
                        </div>
                    </div>
                </el-card>

                <el-card class="!border-none mt-4" shadow="never" v-loading="loading">
                    <div class="grid grid-cols-3 gap-3 text-center">
                        <div>
                            <div class="text-xl font-medium">{{ detail.order_count || 0 }}</div>
                            <div class="mt-1 text-xs text-tx-secondary">预约</div>
                        </div>
                        <div>
                            <div class="text-xl font-medium">{{ detail.favorite_count || 0 }}</div>
                            <div class="mt-1 text-xs text-tx-secondary">收藏</div>
                        </div>
                        <div>
                            <div class="text-xl font-medium">{{ detail.review_count || 0 }}</div>
                            <div class="mt-1 text-xs text-tx-secondary">评价</div>
                        </div>
                    </div>
                </el-card>
            </el-col>

            <el-col :span="16">
                <el-card class="!border-none" shadow="never" v-loading="loading">
                    <template #header>
                        <div class="font-medium">基础资料</div>
                    </template>

                    <el-form ref="formRef" :model="formData" label-width="110px">
                        <el-form-item label="头像">
                            <material-picker v-model="formData.avatar" :limit="1" size="80px" />
                        </el-form-item>
                        <el-form-item label="会员ID">
                            <el-input v-model="formData.member_no" disabled />
                        </el-form-item>
                        <el-form-item label="昵称" required>
                            <el-input v-model="formData.nickname" placeholder="请输入昵称" />
                        </el-form-item>
                        <el-form-item label="姓名">
                            <el-input v-model="formData.real_name" placeholder="请输入姓名" />
                        </el-form-item>
                        <el-form-item label="手机号" required>
                            <el-input v-model="formData.mobile" placeholder="请输入手机号" />
                        </el-form-item>
                        <el-form-item label="邮箱">
                            <el-input v-model="formData.email" placeholder="请输入邮箱" />
                        </el-form-item>
                        <el-form-item label="国籍">
                            <el-select v-model="formData.nationality" class="w-full">
                                <el-option label="日本" value="日本" />
                                <el-option label="中国" value="中国" />
                                <el-option label="韩国" value="韓国" />
                                <el-option label="其他" value="その他" />
                            </el-select>
                        </el-form-item>
                        <el-form-item label="邮编">
                            <el-input v-model="formData.postal_code" placeholder="请输入邮编" />
                        </el-form-item>
                        <el-form-item label="地址">
                            <el-input v-model="formData.address" placeholder="请输入地址" />
                        </el-form-item>
                        <el-form-item label="建筑名/房间号">
                            <el-input v-model="formData.building_name" placeholder="请输入建筑名和房间号" />
                        </el-form-item>
                        <el-form-item label="会员等级">
                            <el-select v-model="formData.level_name" class="w-full">
                                <el-option
                                    v-for="level in MemberLevelOptions"
                                    :key="level"
                                    :label="level"
                                    :value="level"
                                />
                            </el-select>
                        </el-form-item>
                        <el-form-item label="钱包余额">
                            <el-input-number
                                v-model="formData.wallet_balance"
                                :min="0"
                                :precision="0"
                                :step="1000"
                                class="!w-full"
                                controls-position="right"
                            />
                        </el-form-item>
                        <el-form-item label="本人認証ステータス">
                            <el-select v-model="formData.identity_status" class="w-full">
                                <el-option
                                    v-for="(label, value) in IdentityStatusMap"
                                    :key="value"
                                    :label="label"
                                    :value="value"
                                />
                            </el-select>
                        </el-form-item>
                        <el-form-item label="证件图片">
                            <div>
                                <material-picker
                                    v-model="formData.identity_image"
                                    :limit="1"
                                    size="120px"
                                />
                                <div class="form-tips">用于会员身份认证审核。</div>
                            </div>
                        </el-form-item>
                        <el-form-item label="账户状态">
                            <el-select v-model="formData.status" class="w-full">
                                <el-option
                                    v-for="(label, value) in MemberStatusMap"
                                    :key="value"
                                    :label="label"
                                    :value="value"
                                />
                            </el-select>
                        </el-form-item>
                        <el-form-item label="注册时间">
                            <el-input v-model="formData.create_time_text" disabled />
                        </el-form-item>
                        <el-form-item label="更新时间">
                            <el-input v-model="formData.update_time_text" disabled />
                        </el-form-item>
                        <el-form-item>
                            <el-button
                                v-perms="['cabakura.member/updateProfile']"
                                type="primary"
                                :loading="saving"
                                @click="handleSave"
                            >
                                保存资料
                            </el-button>
                            <el-button @click="router.back()">返回</el-button>
                        </el-form-item>
                    </el-form>
                </el-card>
            </el-col>
        </el-row>
    </div>
</template>

<script lang="ts" setup name="cabakuraMemberDetail">
import {
    getCabakuraMemberDetail,
    updateCabakuraMemberProfile
} from '@/api/cabakura/member'
import { IdentityStatusMap, MemberStatusMap, statusTagType } from '@/enums/cabakura/status'

const route = useRoute()
const router = useRouter()
const MemberLevelOptions = ['一般会員', 'プレミアム会員', 'supermember']

const loading = ref(false)
const saving = ref(false)
const detail = reactive<Record<string, any>>({})
const formData = reactive({
    id: 0,
    avatar: '',
    member_no: '',
    nickname: '',
    real_name: '',
    mobile: '',
    email: '',
    nationality: '日本',
    postal_code: '',
    address: '',
    building_name: '',
    level_name: '',
    wallet_balance: 0,
    identity_status: 'not_started',
    identity_image: '',
    status: 'normal',
    create_time_text: '',
    update_time_text: ''
})

const loadDetail = async () => {
    const id = Number(route.query.id || 0)
    if (!id) return

    loading.value = true
    try {
        const data = await getCabakuraMemberDetail({ id })
        Object.assign(detail, data)
        Object.assign(formData, {
            id: data.id,
            avatar: data.avatar || '',
            member_no: data.member_no,
            nickname: data.nickname,
            real_name: data.real_name,
            mobile: data.mobile,
            email: data.email || '',
            nationality: data.nationality || '日本',
            postal_code: data.postal_code || '',
            address: data.address || '',
            building_name: data.building_name || '',
            level_name: MemberLevelOptions.includes(data.level_name) ? data.level_name : '一般会員',
            wallet_balance: Number(data.wallet_balance || 0),
            identity_status: data.identity_status,
            identity_image: data.identity_image || '',
            status: data.status,
            create_time_text: data.create_time_text,
            update_time_text: data.update_time_text
        })
    } finally {
        loading.value = false
    }
}

const handleSave = async () => {
    saving.value = true
    try {
        await updateCabakuraMemberProfile(formData)
        await loadDetail()
    } finally {
        saving.value = false
    }
}

onMounted(() => {
    loadDetail()
})
</script>
