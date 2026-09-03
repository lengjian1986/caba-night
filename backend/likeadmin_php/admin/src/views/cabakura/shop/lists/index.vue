<template>
    <div>
        <el-card class="!border-none" shadow="never">
            <el-form class="mb-[-16px]" :model="queryParams" :inline="true">
                <el-form-item label="店铺信息">
                    <el-input
                        v-model="queryParams.keyword"
                        class="w-[280px]"
                        placeholder="店铺名/区域/许可证号/关键字"
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
                    <el-button class="ml-2" type="primary" @click="openCreate">创建店铺</el-button>
                </el-form-item>
            </el-form>
        </el-card>

        <el-card class="!border-none mt-4" shadow="never">
            <el-table size="large" v-loading="pager.loading" :data="pager.lists">
                <el-table-column label="店铺" min-width="190">
                    <template #default="{ row }">
                        <div class="font-medium">{{ row.name }}</div>
                        <div class="text-xs text-tx-secondary">{{ row.kana }}</div>
                    </template>
                </el-table-column>
                <el-table-column label="区域" prop="area" min-width="140" />
                <el-table-column label="电话号" prop="phone" min-width="140" />
                <el-table-column label="邮箱" prop="email" min-width="180" />
                <el-table-column label="管理者" min-width="150">
                    <template #default="{ row }">
                        <div>{{ row.manager_name || '-' }}</div>
                        <div class="text-xs text-tx-secondary">{{ row.manager_mobile || '' }}</div>
                    </template>
                </el-table-column>
                <el-table-column label="许可证号" prop="license_no" min-width="170" />
                <el-table-column label="営業ステータス" min-width="110">
                    <template #default="{ row }">
                        {{ row.business_status === '休息中' ? '休み' : row.business_status }}
                    </template>
                </el-table-column>
                <el-table-column label="人気店舗表示" min-width="120">
                    <template #default="{ row }">
                        <el-switch
                            v-model="row.is_recommended"
                            :active-value="1"
                            :inactive-value="0"
                            @change="handleSwitchRecommended(row)"
                        />
                    </template>
                </el-table-column>
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
                <el-table-column label="操作" fixed="right" width="100">
                    <template #default="{ row }">
                        <el-button
                            v-perms="['cabakura.shop/updateInfo']"
                            type="primary"
                            link
                            @click="goEdit(row.id)"
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

        <popup
            ref="formPopupRef"
            title="创建店铺"
            width="720px"
            async
            @confirm="handleSubmitReview"
        >
            <el-form ref="formRef" :model="formData" label-width="120px">
                <el-form-item label="店铺名" required>
                    <el-input v-model="formData.name" placeholder="例如 LUXE TOKYO" />
                </el-form-item>
                <el-form-item label="假名">
                    <el-input v-model="formData.kana" placeholder="例如 リュクス トウキョウ" />
                </el-form-item>
                <el-form-item label="エリア" required>
                    <div class="grid grid-cols-2 gap-3 w-full">
                        <el-select
                            v-model="selectedPrefecture"
                            filterable
                            placeholder="都道府県を選択"
                            @change="handlePrefectureChange"
                        >
                            <el-option
                                v-for="item in areaOptions"
                                :key="item.id || item.name"
                                :label="item.name"
                                :value="item.name"
                            />
                        </el-select>
                        <el-select
                            v-model="formData.area"
                            filterable
                            placeholder="市区町村を選択"
                            :disabled="!selectedPrefecture"
                        >
                            <el-option
                                v-for="item in cityOptions"
                                :key="item.id || item.name"
                                :label="item.name"
                                :value="`${selectedPrefecture} ${item.name}`"
                            />
                        </el-select>
                    </div>
                </el-form-item>
                <el-form-item label="电话号">
                    <el-input v-model="formData.phone" placeholder="例如 03-1234-5678" />
                </el-form-item>
                <el-form-item label="邮箱">
                    <el-input v-model="formData.email" placeholder="例如 info@example.com" />
                </el-form-item>
                <el-form-item label="管理者">
                    <el-select
                        v-model="formData.manager_id"
                        class="w-full"
                        clearable
                        filterable
                        placeholder="请选择管理者"
                    >
                        <el-option
                            v-for="item in managerOptions"
                            :key="item.id"
                            :label="`${item.name} / ${item.mobile}`"
                            :value="item.id"
                        />
                    </el-select>
                </el-form-item>
                <el-form-item label="地址">
                    <el-input v-model="formData.address" placeholder="请输入详细地址" />
                </el-form-item>
                <el-form-item label="最近车站">
                    <el-input v-model="formData.station" placeholder="例如 新宿駅 徒歩3分" />
                </el-form-item>
                <el-form-item label="营业时间">
                    <el-input v-model="formData.business_hours" placeholder="例如 20:00-LAST" />
                </el-form-item>
                <el-form-item label="价格区间">
                    <el-input v-model="formData.price_range" placeholder="例如 ¥10,000~¥18,000 / 60分" />
                </el-form-item>
                <el-form-item label="店铺说明">
                    <el-input
                        v-model="formData.description"
                        type="textarea"
                        :rows="5"
                        maxlength="2000"
                        show-word-limit
                        placeholder="店舗の紹介、特徴、注意事項などを入力してください"
                    />
                </el-form-item>
                <el-form-item label="关键字">
                    <el-input
                        v-model="formData.keywords"
                        maxlength="500"
                        show-word-limit
                        placeholder="例：新宿 高級 個室 スペース区切りで入力"
                    />
                </el-form-item>
                <el-form-item label="人気店舗表示">
                    <el-switch v-model="formData.is_recommended" />
                </el-form-item>
                <el-form-item label="标签">
                    <el-select v-model="formData.tags" multiple filterable allow-create class="w-full">
                        <el-option label="高級感" value="高級感" />
                        <el-option label="明朗会計" value="明朗会計" />
                        <el-option label="当日予約OK" value="当日予約OK" />
                    </el-select>
                </el-form-item>
                <el-form-item label="店铺Logo">
                    <material-picker v-model="formData.logo_image" :limit="1" size="90px" />
                </el-form-item>
                <el-form-item label="店铺照片">
                    <material-picker
                        v-model="formData.shop_images"
                        :limit="6"
                        size="90px"
                    />
                </el-form-item>
                <el-form-item label="セットプラン">
                    <div class="w-full">
                        <div class="package-actions">
                            <el-button type="primary" @click="openPackageDialog()">セットプラン作成</el-button>
                        </div>
                        <div
                            v-for="(item, index) in formData.package_sets"
                            :key="index"
                            class="package-set-row"
                        >
                            <span>{{ item.name || `Set ${index + 1}` }}</span>
                            <span>¥{{ Number(item.price || 0).toLocaleString() }}</span>
                            <span>最大{{ item.max_people || 0 }}人</span>
                            <el-tag size="small">{{ packageStatusText(item.status) }}</el-tag>
                            <el-button type="primary" link @click="openPackageDialog(index)">
                                編集
                            </el-button>
                            <el-button type="danger" link @click="removePackageSet(index)">
                                削除
                            </el-button>
                        </div>
                        <el-empty
                            v-if="!formData.package_sets.length"
                            description="セットプランはありません"
                            :image-size="60"
                        />
                    </div>
                </el-form-item>
                <el-form-item label="许可证号" required>
                    <el-input v-model="formData.license_no" placeholder="营业执照/营业许可编号" />
                </el-form-item>
                <el-form-item label="经营主体">
                    <el-input v-model="formData.license_holder_name" placeholder="法人或经营主体" />
                </el-form-item>
                <el-form-item label="许可有效期">
                    <el-date-picker
                        v-model="formData.license_expires_at"
                        type="date"
                        value-format="YYYY-MM-DD"
                        placeholder="选择日期"
                    />
                </el-form-item>
                <el-form-item label="许可证件" required>
                    <material-picker
                        v-model="formData.license_files"
                        :limit="6"
                        size="90px"
                    />
                </el-form-item>
                <el-form-item>
                    <el-button @click="handleSaveDraft">保存草稿</el-button>
                </el-form-item>
            </el-form>
        </popup>

        <el-dialog
            v-model="packageDialogVisible"
            :title="editingPackageIndex >= 0 ? 'セットプラン編集' : 'セットプラン作成'"
            width="620px"
        >
            <el-form :model="packageForm" label-width="100px">
                <el-form-item label="プラン名" required>
                    <el-input v-model="packageForm.name" placeholder="例 Premium Set" />
                </el-form-item>
                <el-form-item label="説明">
                    <el-input
                        v-model="packageForm.description"
                        type="textarea"
                        :rows="3"
                        placeholder="セットプラン説明を入力"
                    />
                </el-form-item>
                <el-form-item label="画像">
                    <material-picker v-model="packageForm.image" :limit="1" size="100px" />
                </el-form-item>
                <el-form-item label="紐付けキャスト">
                    <el-select
                        v-model="packageForm.cast_names"
                        multiple
                        filterable
                        allow-create
                        class="w-full"
                        placeholder="キャスト名を入力して Enter"
                    />
                </el-form-item>
                <el-form-item label="価格" required>
                    <el-input-number
                        v-model="packageForm.price"
                        class="w-full"
                        :min="0"
                        :controls="false"
                    />
                </el-form-item>
                <el-form-item label="割引タイプ">
                    <el-select
                        v-model="packageForm.discount_type"
                        class="w-full"
                        @change="handlePackageDiscountTypeChange"
                    >
                        <el-option label="割引なし" value="none" />
                        <el-option label="固定金額" value="amount" />
                        <el-option label="パーセント" value="percent" />
                    </el-select>
                </el-form-item>
                <el-form-item label="公開状態">
                    <el-radio-group v-model="packageForm.status">
                        <el-radio value="public">公開中</el-radio>
                        <el-radio value="private">非公開</el-radio>
                    </el-radio-group>
                </el-form-item>
                <el-form-item label="おすすめ切替">
                    <el-switch v-model="packageForm.is_recommended" />
                </el-form-item>
                <el-form-item v-if="packageForm.discount_type !== 'none'" label="割引">
                    <el-input-number
                        v-model="packageForm.discount_value"
                        class="w-full"
                        :min="0"
                        :max="packageForm.discount_type === 'percent' ? 100 : undefined"
                        :controls="false"
                        :placeholder="
                            packageForm.discount_type === 'percent'
                                ? '割引率を入力してください'
                                : '割引後の金額を入力してください'
                        "
                    />
                    <div class="field-hint">
                        {{
                            packageForm.discount_type === 'percent'
                                ? '割引率を入力してください（例：20 = 20%OFF）'
                                : '割引後の金額を入力してください（例：8000）'
                        }}
                    </div>
                </el-form-item>
                <el-form-item label="制限方式">
                    <el-radio-group v-model="packageForm.limit_type">
                        <el-radio value="date_range">期間指定</el-radio>
                        <el-radio value="usage_count">回数限定</el-radio>
                    </el-radio-group>
                </el-form-item>
                <el-form-item v-if="packageForm.limit_type === 'date_range'" label="期間">
                    <el-date-picker
                        v-model="packageForm.valid_range"
                        class="w-full"
                        type="daterange"
                        value-format="YYYY-MM-DD"
                        start-placeholder="開始日"
                        end-placeholder="終了日"
                    />
                </el-form-item>
                <el-form-item v-else label="限定回数">
                    <el-input-number
                        v-model="packageForm.usage_limit"
                        class="w-full"
                        :min="0"
                        :controls="false"
                    />
                </el-form-item>
                <el-form-item label="最大人数">
                    <el-input-number
                        v-model="packageForm.max_people"
                        class="w-full"
                        :min="1"
                        :controls="false"
                    />
                </el-form-item>
                <el-form-item label="タグ">
                    <el-select
                        v-model="packageForm.tags"
                        multiple
                        filterable
                        class="w-full"
                        placeholder="セットプランタグを選択"
                    >
                        <el-option
                            v-for="option in fieldOptions('cbk_shop_plan_tag')"
                            :key="option.id || option.value"
                            :label="option.name"
                            :value="option.value"
                        />
                    </el-select>
                </el-form-item>
            </el-form>
            <template #footer>
                <el-button @click="packageDialogVisible = false">キャンセル</el-button>
                <el-button type="primary" @click="savePackageSet">セットプラン保存</el-button>
            </template>
        </el-dialog>
    </div>
</template>

<script lang="ts" setup name="cabakuraShopLists">
import {
    getCabakuraShopList,
    saveCabakuraShopDraft,
    submitCabakuraShopReview,
    switchCabakuraShopRecommended
} from '@/api/cabakura/shop'
import { getCabakuraAnswerSettingFields } from '@/api/cabakura/answer-setting'
import { getCabakuraAreaList } from '@/api/cabakura/area'
import { getCabakuraShopManagerList } from '@/api/cabakura/shop-manager'
import { ShopReviewStatusMap, statusTagType } from '@/enums/cabakura/status'
import { usePaging } from '@/hooks/usePaging'
import useLanguageStore from '@/stores/modules/language'
import { t } from '@/utils/i18n'
import feedback from '@/utils/feedback'

const router = useRouter()
const languageStore = useLanguageStore()

const queryParams = reactive({
    keyword: '',
    review_status: ''
})

const formPopupRef = shallowRef()

type PackageSet = {
    name: string
    description: string
    image: string
    cast_names: string[]
    price: number
    discount_type: string
    discount_value: number | undefined
    limit_type: string
    valid_range: string[]
    usage_limit: number
    max_people: number
    status: string
    is_recommended: boolean
    tags: string[]
}

const createEmptyPackage = (): PackageSet => ({
    name: '',
    description: '',
    image: '',
    cast_names: [],
    price: 0,
    discount_type: 'none',
    discount_value: undefined,
    limit_type: 'date_range',
    valid_range: [],
    usage_limit: 0,
    max_people: 1,
    status: 'public',
    is_recommended: false,
    tags: []
})

const formData = reactive({
    name: '',
    manager_id: undefined as number | undefined,
    kana: '',
    area: '',
    phone: '',
    email: '',
    address: '',
    station: '',
    business_hours: '',
    price_range: '',
    description: '',
    keywords: '',
    tags: [] as string[],
    logo_image: '',
    shop_images: [] as string[],
    package_sets: [] as PackageSet[],
    license_no: '',
    license_holder_name: '',
    license_expires_at: '',
    license_files: [] as string[],
    business_status: '休息中',
    is_recommended: false
})
const packageDialogVisible = ref(false)
const editingPackageIndex = ref(-1)
const packageForm = reactive<PackageSet>(createEmptyPackage())
const managerOptions = ref<any[]>([])
const areaOptions = ref<any[]>([])
const answerSettingFields = ref<any[]>([])
const selectedPrefecture = ref('')
const cityOptions = computed(() => {
    const prefecture = areaOptions.value.find((item) => item.name === selectedPrefecture.value)
    return prefecture?.children || []
})

const fieldOptions = (type: string) => {
    for (const group of answerSettingFields.value) {
        const field = group.fields?.find((item: any) => item.type === type)
        if (field) {
            return (field.options || []).filter((option: any) => option.status === 1)
        }
    }
    return []
}

const { pager, getLists, resetPage, resetParams } = usePaging({
    fetchFun: getCabakuraShopList,
    params: queryParams
})

const resetForm = () => {
    Object.assign(formData, {
        name: '',
        manager_id: undefined,
        kana: '',
        area: '',
        phone: '',
        email: '',
        address: '',
        station: '',
        business_hours: '',
        price_range: '',
        description: '',
        keywords: '',
        tags: [],
        logo_image: '',
        shop_images: [],
        package_sets: [],
        license_no: '',
        license_holder_name: '',
        license_expires_at: '',
        license_files: [],
        business_status: '休息中',
        is_recommended: false
    })
    selectedPrefecture.value = ''
}

const handleSwitchRecommended = async (row: any) => {
    try {
        await switchCabakuraShopRecommended({
            id: row.id,
            is_recommended: row.is_recommended
        })
    } catch (error) {
        row.is_recommended = row.is_recommended ? 0 : 1
        throw error
    }
}

const openCreate = () => {
    resetForm()
    loadAreaOptions()
    loadAnswerSettingFields()
    loadManagerOptions()
    formPopupRef.value?.open()
}

const loadManagerOptions = async () => {
    const data = await getCabakuraShopManagerList({
        page_no: 1,
        page_size: 100
    })
    managerOptions.value = data.lists || []
}

const loadAreaOptions = async () => {
    const data = await getCabakuraAreaList({
        is_show: 1
    })
    areaOptions.value = (data.lists || []).filter((item: any) => Number(item.level) === 1)
}

const loadAnswerSettingFields = async () => {
    answerSettingFields.value = await getCabakuraAnswerSettingFields()
}

const handlePrefectureChange = () => {
    formData.area = ''
}

const validateBaseRequired = () => {
    if (!formData.name.trim()) {
        feedback.msgError('店铺名を入力してください')
        return false
    }
    if (!selectedPrefecture.value) {
        feedback.msgError('都道府県を選択してください')
        return false
    }
    if (!formData.area.trim()) {
        feedback.msgError('市区町村を選択してください')
        return false
    }
    return true
}

const goEdit = (id: number) => {
    router.push({
        path: '/shop/edit',
        query: { id }
    })
}

const openPackageDialog = (index = -1) => {
    editingPackageIndex.value = index
    Object.assign(
        packageForm,
        index >= 0
            ? {
                  ...createEmptyPackage(),
                  ...formData.package_sets[index],
                  cast_names: Array.isArray(formData.package_sets[index].cast_names)
                      ? formData.package_sets[index].cast_names
                      : [],
                  valid_range: Array.isArray(formData.package_sets[index].valid_range)
                      ? formData.package_sets[index].valid_range
                      : [],
                  tags: Array.isArray(formData.package_sets[index].tags)
                      ? formData.package_sets[index].tags
                      : []
              }
            : createEmptyPackage()
    )
    packageDialogVisible.value = true
}

const handlePackageDiscountTypeChange = () => {
    packageForm.discount_value = undefined
}

const normalizePackageStatus = (value: any) =>
    [0, false, '0', 'private', 'hidden', 'inactive', 'off', '下架', '非公開'].includes(value)
        ? 'private'
        : 'public'

const packageStatusText = (value: any) =>
    normalizePackageStatus(value) === 'private' ? '非公開' : '公開中'

const savePackageSet = () => {
    const payload = {
        ...packageForm,
        status: normalizePackageStatus(packageForm.status),
        cast_names: [...packageForm.cast_names],
        valid_range: [...packageForm.valid_range],
        tags: [...packageForm.tags]
    }
    if (editingPackageIndex.value >= 0) {
        formData.package_sets.splice(editingPackageIndex.value, 1, payload)
    } else {
        formData.package_sets.push(payload)
    }
    packageDialogVisible.value = false
}

const removePackageSet = (index: number) => {
    formData.package_sets.splice(index, 1)
}

const handleSaveDraft = async () => {
    if (!validateBaseRequired()) {
        return
    }
    formData.manager_id = formData.manager_id ? Number(formData.manager_id) : undefined
    await saveCabakuraShopDraft(formData)
    formPopupRef.value?.close()
    getLists()
}

const handleSubmitReview = async () => {
    if (!validateBaseRequired()) {
        return
    }
    formData.manager_id = formData.manager_id ? Number(formData.manager_id) : undefined
    await submitCabakuraShopReview(formData)
    formPopupRef.value?.close()
    getLists()
}

onActivated(() => {
    getLists()
})

getLists()
loadManagerOptions()
</script>

<style lang="scss" scoped>
.package-set-row {
    display: grid;
    grid-template-columns: minmax(0, 1fr) 100px 100px 48px 48px;
    gap: 8px;
    align-items: center;
    margin-bottom: 8px;
}

.package-actions {
    margin-bottom: 12px;
}

.tag-editor {
    display: flex;
    flex-wrap: wrap;
    width: 100%;
    gap: 8px;
}

.tag-input {
    flex: 1 1 180px;
    min-width: 180px;
}

.field-hint {
    margin-top: 6px;
    color: var(--el-text-color-secondary);
    font-size: 12px;
    line-height: 1.4;
}
</style>
