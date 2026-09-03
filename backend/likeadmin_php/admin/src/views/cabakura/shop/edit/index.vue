<template>
    <div>
        <el-page-header class="mb-4" :content="t('店铺编辑', languageStore.language)" @back="router.back()" />

        <el-card class="!border-none" shadow="never" v-loading="loading">
            <template #header>
                <div class="flex items-center justify-between">
                    <div class="font-medium">店铺资料</div>
                    <el-tag :type="statusTagType(formData.review_status)">
                        {{ formData.review_status_text || '-' }}
                    </el-tag>
                </div>
            </template>

            <el-form ref="formRef" :model="formData" label-width="120px">
                <el-tabs v-model="activeTab">
                    <el-tab-pane label="基本信息" name="base">
                        <div class="flex justify-end gap-2 mb-4">
                            <el-button v-if="!baseEditing" @click="beginEditing('base')">編集</el-button>
                            <template v-else>
                                <el-button @click="cancelEditing('base')">キャンセル</el-button>
                                <el-button
                                    v-perms="['cabakura.shop/updateInfo']"
                                    type="primary"
                                    :loading="saving"
                                    @click="handleSave('base')"
                                >保存</el-button>
                            </template>
                        </div>
                        <fieldset :disabled="!baseEditing" class="border-0 p-0 m-0">
                        <el-row :gutter="24">
                            <el-col :span="12">
                                <el-form-item label="店铺ID">
                                    <el-input v-model="formData.id" disabled />
                                </el-form-item>
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
                            </el-col>
                            <el-col :span="12">
                                <el-form-item label="营业时间">
                                    <el-input v-model="formData.business_hours" placeholder="例如 20:00-LAST" />
                                </el-form-item>
                                <el-form-item label="料金システム">
                                    <div class="w-full space-y-2">
                                        <div class="flex flex-wrap items-center gap-2">
                                            <span class="shrink-0">料金</span>
                                            <el-input
                                                v-model="formData.price_min"
                                                class="w-40"
                                                type="number"
                                                min="0"
                                                :controls="false"
                                                placeholder="下限"
                                            >
                                                <template #prepend>¥</template>
                                            </el-input>
                                            <span>〜</span>
                                            <el-input
                                                v-model="formData.price_max"
                                                class="w-40"
                                                type="number"
                                                min="0"
                                                :controls="false"
                                                placeholder="上限"
                                            >
                                                <template #prepend>¥</template>
                                            </el-input>
                                        </div>
                                        <div class="flex items-center gap-2">
                                            <span class="shrink-0">時間単位</span>
                                            <el-input
                                                v-model="formData.time_unit"
                                                class="w-32"
                                                type="number"
                                                min="0"
                                                :controls="false"
                                                placeholder="時間"
                                            />
                                            <span>分</span>
                                        </div>
                                    </div>
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
                                <el-form-item label="営業ステータス">
                                    <el-select v-model="formData.business_status" class="w-full">
                                        <el-option label="営業中" value="営業中" />
                                        <el-option label="休み" value="休息中" />
                                        <el-option label="暂停展示" value="暂停展示" />
                                    </el-select>
                                </el-form-item>
                                <el-form-item label="人気店舗表示">
                                    <el-switch v-model="formData.is_recommended" />
                                </el-form-item>
                                <el-form-item label="预约开放">
                                    <el-switch
                                        v-model="formData.booking_enabled"
                                        disabled
                                        active-text="已开放"
                                        inactive-text="未开放"
                                    />
                                </el-form-item>
                                <el-form-item label="标签">
                                    <el-select
                                        v-model="formData.tags"
                                        multiple
                                        filterable
                                        allow-create
                                        class="w-full"
                                    >
                                        <el-option label="高級感" value="高級感" />
                                        <el-option label="明朗会計" value="明朗会計" />
                                        <el-option label="当日予約OK" value="当日予約OK" />
                                    </el-select>
                                </el-form-item>
                                <el-form-item label="提交时间">
                                    <el-input v-model="formData.submitted_at" disabled />
                                </el-form-item>
                            </el-col>
                        </el-row>
                        </fieldset>
                    </el-tab-pane>

                    <el-tab-pane label="店铺照片" name="images">
                        <div class="flex justify-end gap-2 mb-4">
                            <el-button v-if="!imagesEditing" @click="beginEditing('images')">編集</el-button>
                            <template v-else>
                                <el-button @click="cancelEditing('images')">キャンセル</el-button>
                                <el-button
                                    v-perms="['cabakura.shop/updateInfo']"
                                    type="primary"
                                    :loading="saving"
                                    @click="handleSave('images')"
                                >保存</el-button>
                            </template>
                        </div>
                        <fieldset :disabled="!imagesEditing" class="border-0 p-0 m-0">
                        <el-row :gutter="24">
                            <el-col :span="12">
                                <el-form-item label="店铺Logo">
                                    <material-picker v-model="formData.logo_image" :limit="1" size="110px" />
                                </el-form-item>
                                <el-form-item label="店铺照片">
                                    <material-picker
                                        v-model="formData.shop_images"
                                        :limit="9"
                                        size="110px"
                                    />
                                </el-form-item>
                            </el-col>
                            <el-col :span="12">
                                <el-form-item label="许可证号" required>
                                    <el-input v-model="formData.license_no" placeholder="营业执照/营业许可编号" />
                                </el-form-item>
                                <el-form-item label="经营主体">
                                    <el-input v-model="formData.license_holder_name" placeholder="法人或经营主体" />
                                </el-form-item>
                                <el-form-item label="许可有效期">
                                    <el-date-picker
                                        v-model="formData.license_expires_at"
                                        class="w-full"
                                        type="date"
                                        value-format="YYYY-MM-DD"
                                        placeholder="选择日期"
                                    />
                                </el-form-item>
                                <el-form-item label="许可证件">
                                    <material-picker
                                        v-model="formData.license_files"
                                        :limit="6"
                                        size="110px"
                                    />
                                </el-form-item>
                            </el-col>
                        </el-row>
                        </fieldset>
                    </el-tab-pane>

                    <el-tab-pane label="セットプラン" name="packages">
                        <div class="package-actions">
                            <el-button type="primary" @click="openPackageDialog()">セットプラン作成</el-button>
                        </div>
                        <div v-if="formData.package_sets.length" class="package-grid">
                            <div
                                v-for="(item, index) in formData.package_sets"
                                :key="index"
                                class="package-set-card"
                            >
                                <el-image
                                    v-if="item.image"
                                    class="package-image"
                                    :src="item.image"
                                    fit="cover"
                                />
                                <div v-else class="package-image is-empty">Set</div>
                                <div class="package-info">
                                    <div class="package-set-head">
                                        <div class="font-medium">{{ item.name || `Set ${index + 1}` }}</div>
                                        <div>
                                            <el-button type="primary" link @click="openPackageDialog(index)">
                                                編集
                                            </el-button>
                                            <el-button type="danger" link @click="removePackageSet(index)">
                                                削除
                                            </el-button>
                                        </div>
                                    </div>
                                    <div class="text-sm text-tx-secondary">
                                        ¥{{ Number(item.price || 0).toLocaleString() }}
                                        / 最大{{ item.max_people || 0 }}人
                                        / {{ packageStatusText(item.status) }}
                                    </div>
                                    <div v-if="item.discount_value" class="text-sm text-tx-secondary mt-1">
                                        割引：{{ item.discount_type === 'percent' ? `${item.discount_value}%` : `¥${Number(item.discount_value).toLocaleString()}` }}
                                        / {{ item.limit_type === 'date_range' ? '期間指定' : '回数限定' }}
                                    </div>
                                    <div class="text-sm text-tx-secondary mt-1">
                                        {{ item.description || '-' }}
                                    </div>
                                    <div v-if="item.tags?.length" class="package-tags">
                                        <el-tag
                                            v-for="tag in item.tags"
                                            :key="tag"
                                            size="small"
                                            class="mr-1"
                                        >
                                            {{ tag }}
                                        </el-tag>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <el-empty v-else description="セットプランはありません" :image-size="72" />
                    </el-tab-pane>

                    <el-tab-pane label="キャスト情報" name="casts">
                        <el-table :data="castList" size="large">
                            <el-table-column label="头像" width="90">
                                <template #default="{ row }">
                                    <el-image
                                        v-if="row.main_image"
                                        class="cast-avatar"
                                        :src="row.main_image"
                                        fit="cover"
                                    />
                                    <div v-else class="cast-avatar is-empty">キャスト</div>
                                </template>
                            </el-table-column>
                            <el-table-column label="キャスト名" min-width="160">
                                <template #default="{ row }">
                                    <div class="font-medium">{{ row.name }}</div>
                                    <div class="text-xs text-tx-secondary">{{ row.kana }}</div>
                                </template>
                            </el-table-column>
                            <el-table-column label="年龄" prop="age" min-width="80" />
                            <el-table-column label="身高" min-width="90">
                                <template #default="{ row }">{{ row.height || '-' }}cm</template>
                            </el-table-column>
                            <el-table-column label="三围" prop="measurements" min-width="120" />
                            <el-table-column label="喜欢类型" min-width="160">
                                <template #default="{ row }">
                                    {{ row.preferred_male_type_text || row.preferred_male_type || '-' }}
                                </template>
                            </el-table-column>
                            <el-table-column label="抽烟喝酒" min-width="120">
                                <template #default="{ row }">
                                    {{ row.smoking_drinking_text || row.smoking_drinking || '-' }}
                                </template>
                            </el-table-column>
                            <el-table-column label="出勤状态" min-width="100">
                                <template #default="{ row }">
                                    <el-tag>{{ row.attendance_status_text }}</el-tag>
                                </template>
                            </el-table-column>
                            <el-table-column label="审核状态" min-width="100">
                                <template #default="{ row }">
                                    <el-tag>{{ row.review_status_text }}</el-tag>
                                </template>
                            </el-table-column>
                            <el-table-column label="标签" min-width="180">
                                <template #default="{ row }">
                                    <el-tag
                                        v-for="tag in row.tags"
                                        :key="tag"
                                        size="small"
                                        class="mr-1"
                                    >
                                        {{ tag }}
                                    </el-tag>
                                </template>
                            </el-table-column>
                        </el-table>
                        <el-empty
                            v-if="!castList.length"
                            description="暂无 キャスト"
                            :image-size="72"
                        />
                    </el-tab-pane>
                </el-tabs>

            </el-form>
        </el-card>

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
                    <material-picker v-model="packageForm.image" :limit="1" size="110px" />
                </el-form-item>
                <el-form-item label="紐付けキャスト">
                    <el-select
                        v-model="packageForm.cast_names"
                        multiple
                        filterable
                        allow-create
                        class="w-full"
                        placeholder="キャスト名を入力して Enter"
                    >
                        <el-option
                            v-for="name in castNameOptions"
                            :key="name"
                            :label="name"
                            :value="name"
                        />
                    </el-select>
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
                <el-button type="primary" :loading="packageSaving" @click="savePackageSet">
                    セットプラン保存
                </el-button>
            </template>
        </el-dialog>
    </div>
</template>

<script lang="ts" setup name="cabakuraShopEdit">
import {
    getCabakuraShopDetail,
    updateCabakuraShopInfo
} from '@/api/cabakura/shop'
import { getCabakuraCastList } from '@/api/cabakura/cast'
import { getCabakuraAreaList } from '@/api/cabakura/area'
import { getCabakuraAnswerSettingFields } from '@/api/cabakura/answer-setting'
import { getCabakuraShopManagerList } from '@/api/cabakura/shop-manager'
import { statusTagType } from '@/enums/cabakura/status'
import useLanguageStore from '@/stores/modules/language'
import { t } from '@/utils/i18n'
import feedback from '@/utils/feedback'

const route = useRoute()
const router = useRouter()
const languageStore = useLanguageStore()

const loading = ref(false)
const saving = ref(false)
const packageSaving = ref(false)
const baseEditing = ref(false)
const imagesEditing = ref(false)
const activeTab = ref('base')
const baseSnapshot = ref<Record<string, any> | null>(null)
const imagesSnapshot = ref<Record<string, any> | null>(null)

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
    duration_minutes?: number
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
    id: 0,
    manager_id: undefined as number | undefined,
    name: '',
    kana: '',
    area: '',
    phone: '',
    email: '',
    address: '',
    station: '',
    business_hours: '',
    price_range: '',
    price_min: '',
    price_max: '',
    time_unit: '',
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
    is_recommended: false,
    booking_enabled: false,
    submitted_at: '',
    review_status: '',
    review_status_text: ''
})
const packageDialogVisible = ref(false)
const editingPackageIndex = ref(-1)
const packageForm = reactive<PackageSet>(createEmptyPackage())
const castList = ref<any[]>([])
const managerOptions = ref<any[]>([])
const areaOptions = ref<any[]>([])
const answerSettingFields = ref<any[]>([])
const selectedPrefecture = ref('')
const castNameOptions = computed(() => castList.value.map((item) => item.name).filter(Boolean))
const fieldOptions = (type: string) => {
    for (const group of answerSettingFields.value) {
        const field = group.fields?.find((item: any) => item.type === type)
        if (field) {
            return (field.options || []).filter((option: any) => option.status === 1)
        }
    }
    return []
}
const cityOptions = computed(() => {
    const prefecture = areaOptions.value.find((item) => item.name === selectedPrefecture.value)
    return prefecture?.children || []
})

const parsePriceRange = (value: unknown) => {
    const numbers = String(value || '').match(/\d[\d,]*/g) || []
    return {
        price_min: numbers[0]?.replace(/,/g, '') || '',
        price_max: numbers[1]?.replace(/,/g, '') || '',
        time_unit: numbers[2]?.replace(/,/g, '') || ''
    }
}

const formatPriceAmount = (value: string) => {
    const digits = String(value || '').replace(/[^\d]/g, '')
    return digits ? Number(digits).toLocaleString('ja-JP') : ''
}

const syncPriceRange = () => {
    const min = formatPriceAmount(formData.price_min)
    const max = formatPriceAmount(formData.price_max)
    const time = String(formData.time_unit || '').replace(/[^\d]/g, '')
    formData.price_range = min || max || time ? `¥${min}~¥${max} / ${time}分` : ''
}

const syncAreaSelection = () => {
    if (!formData.area || !areaOptions.value.length) return
    const rawArea = formData.area.trim()
    const matchedPrefecture = areaOptions.value.find(
        (prefecture) =>
            prefecture.name === rawArea ||
            rawArea.startsWith(`${prefecture.name} `) ||
            (prefecture.children || []).some(
                (city: any) => city.name === rawArea || rawArea.endsWith(` ${city.name}`)
            )
    )
    selectedPrefecture.value = matchedPrefecture?.name || ''
    const matchedCity = matchedPrefecture?.children?.find(
        (city: any) => city.name === rawArea || rawArea.endsWith(` ${city.name}`)
    )
    if (matchedPrefecture && matchedCity) {
        formData.area = `${matchedPrefecture.name} ${matchedCity.name}`
    }
}

const handlePrefectureChange = () => {
    formData.area = ''
}

const loadDetail = async () => {
    const id = Number(route.query.id || 0)
    if (!id) return

    loading.value = true
    try {
        const data = await getCabakuraShopDetail({ id })
        Object.assign(formData, {
            id: data.id,
            manager_id: data.manager_id ? Number(data.manager_id) : undefined,
            name: data.name,
            kana: data.kana,
            area: data.area,
            phone: data.phone || '',
            email: data.email || '',
            address: data.address,
            station: data.station,
            business_hours: data.business_hours,
            price_range: data.price_range,
            ...parsePriceRange(data.price_range),
            description: data.description || '',
            keywords: data.keywords || '',
            tags: Array.isArray(data.tags) ? data.tags : [],
            logo_image: data.logo_image || '',
            shop_images: Array.isArray(data.shop_images) ? data.shop_images : [],
            package_sets: Array.isArray(data.package_sets) ? data.package_sets : [],
            license_no: data.license?.license_no || '',
            license_holder_name: data.license?.holder_name || '',
            license_expires_at: data.license?.expires_at || '',
            license_files: Array.isArray(data.license?.files)
                ? data.license.files
                : data.license?.file_name
                  ? [data.license.file_name]
                  : [],
            business_status: data.business_status === '営業中' ? '営業中' : '休息中',
            is_recommended: Boolean(data.is_recommended),
            booking_enabled: Boolean(data.booking_enabled),
            submitted_at: data.submitted_at || '',
            review_status: data.review_status,
            review_status_text: data.review_status_text
        })
        syncAreaSelection()
        await loadCastList()
    } finally {
        loading.value = false
    }
}

const loadCastList = async () => {
    if (!formData.id) return
    const data = await getCabakuraCastList({
        shop_id: formData.id,
        page_no: 1,
        page_size: 100
    })
    castList.value = data.lists || []
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
    syncAreaSelection()
}

const loadAnswerSettingFields = async () => {
    answerSettingFields.value = await getCabakuraAnswerSettingFields()
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

const cloneFormData = () => JSON.parse(JSON.stringify(formData))

const beginEditing = (section: 'base' | 'images') => {
    if (section === 'base') {
        baseSnapshot.value = cloneFormData()
        baseEditing.value = true
    } else {
        imagesSnapshot.value = cloneFormData()
        imagesEditing.value = true
    }
}

const cancelEditing = (section: 'base' | 'images') => {
    const snapshot = section === 'base' ? baseSnapshot.value : imagesSnapshot.value
    if (snapshot) {
        Object.assign(formData, snapshot)
        syncAreaSelection()
    }
    if (section === 'base') {
        baseEditing.value = false
        baseSnapshot.value = null
    } else {
        imagesEditing.value = false
        imagesSnapshot.value = null
    }
}

const handleSave = async (section: 'base' | 'images') => {
    if (!validateBaseRequired()) {
        return
    }
    saving.value = true
    try {
        formData.manager_id = formData.manager_id ? Number(formData.manager_id) : undefined
        syncPriceRange()
        await updateCabakuraShopInfo(formData)
        await loadDetail()
        if (section === 'base') {
            baseEditing.value = false
            baseSnapshot.value = null
        } else {
            imagesEditing.value = false
            imagesSnapshot.value = null
        }
    } finally {
        saving.value = false
    }
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

const savePackageSet = async () => {
    if (!validateBaseRequired()) {
        return
    }
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

    packageSaving.value = true
    try {
        formData.manager_id = formData.manager_id ? Number(formData.manager_id) : undefined
        await updateCabakuraShopInfo(formData)
        packageDialogVisible.value = false
        feedback.msgSuccess('セットプランを保存しました')
        await loadDetail()
    } finally {
        packageSaving.value = false
    }
}

const removePackageSet = (index: number) => {
    formData.package_sets.splice(index, 1)
}

onMounted(() => {
    loadAreaOptions()
    loadAnswerSettingFields()
    loadManagerOptions()
    loadDetail()
})
</script>

<style lang="scss" scoped>
.package-set-card {
    display: flex;
    gap: 12px;
    padding: 12px;
    margin-bottom: 12px;
    border: 1px solid var(--el-border-color-light);
    border-radius: 6px;
}

.package-set-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 10px;
}

.package-actions {
    margin-bottom: 12px;
}

.package-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(360px, 1fr));
    gap: 12px;
}

.package-image {
    width: 72px;
    height: 72px;
    border-radius: 6px;
    flex: 0 0 auto;

    &.is-empty {
        display: flex;
        align-items: center;
        justify-content: center;
        color: var(--el-text-color-secondary);
        background: var(--el-fill-color-light);
    }
}

.package-info {
    min-width: 0;
    flex: 1;
}

.package-tags {
    margin-top: 8px;
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

.cast-avatar {
    width: 56px;
    height: 56px;
    border-radius: 6px;

    &.is-empty {
        display: flex;
        align-items: center;
        justify-content: center;
        color: var(--el-text-color-secondary);
        background: var(--el-fill-color-light);
    }
}
</style>
