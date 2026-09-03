<template>
    <div>
        <el-card class="!border-none" shadow="never">
            <el-form class="mb-[-16px]" :model="queryParams" :inline="true">
                <el-form-item label="キャスト信息">
                    <el-input
                        v-model="queryParams.keyword"
                        class="w-[260px]"
                        placeholder="キャスト名/假名/三围"
                        clearable
                        @keyup.enter="resetPage"
                    />
                </el-form-item>
                <el-form-item label="绑定店铺">
                    <el-select
                        v-model="queryParams.shop_id"
                        class="w-[220px]"
                        filterable
                        clearable
                        placeholder="全部店铺"
                    >
                        <el-option
                            v-for="shop in shopOptions"
                            :key="shop.id"
                            :label="shop.name"
                            :value="shop.id"
                        />
                    </el-select>
                </el-form-item>
                <el-form-item>
                    <el-button type="primary" @click="resetPage">查询</el-button>
                    <el-button @click="resetParams">重置</el-button>
                    <el-button
                        v-perms="['cabakura.cast/saveProfile']"
                        class="ml-2"
                        type="primary"
                        @click="openCastDialog()"
                    >
                        创建キャスト
                    </el-button>
                </el-form-item>
            </el-form>
        </el-card>

        <el-card class="!border-none mt-4" shadow="never">
            <div v-loading="pager.loading" class="cast-panel-list">
                <div v-for="row in pager.lists" :key="row.id" class="cast-strip-panel">
                    <div class="cast-strip-scroll">
                        <div class="cast-strip-identity">
                            <el-image
                                v-if="row.main_image"
                                class="cast-strip-avatar"
                                :src="row.main_image"
                                fit="cover"
                                :preview-src-list="castPreviewImages(row)"
                            />
                            <div v-else class="cast-strip-avatar is-empty">キャスト</div>
                            <div class="cast-strip-name">
                                <div class="font-medium">{{ row.name || '-' }}</div>
                                <div class="text-xs text-tx-secondary">{{ row.kana || '-' }}</div>
                            </div>
                        </div>

                        <div class="cast-strip-cell is-shop">
                            <span>绑定店铺</span>
                            <strong>{{ shopDisplayName(row) }}</strong>
                        </div>
                        <div class="cast-strip-cell is-small">
                            <span>ID</span>
                            <strong>{{ row.id }}</strong>
                        </div>
                        <div class="cast-strip-cell is-small">
                            <span>年龄</span>
                            <strong>{{ displayValue(row.age) }}</strong>
                        </div>
                        <div class="cast-strip-cell is-small">
                            <span>身高</span>
                            <strong>{{ row.height ? `${row.height}cm` : '-' }}</strong>
                        </div>
                        <div class="cast-strip-cell">
                            <span>三围</span>
                            <strong>{{ displayValue(row.measurements) }}</strong>
                        </div>
                        <div class="cast-strip-cell">
                            <span>スタイル</span>
                            <strong>{{ displayValue(row.style) }}</strong>
                        </div>
                        <div class="cast-strip-cell">
                            <span>血液型</span>
                            <strong>{{ displayValue(row.blood_type) }}</strong>
                        </div>
                        <div class="cast-strip-cell">
                            <span>出身地</span>
                            <strong>{{ displayValue(row.birthplace) }}</strong>
                        </div>
                        <div class="cast-strip-cell">
                            <span>趣味</span>
                            <strong>{{ displayValue(row.hobby) }}</strong>
                        </div>
                        <div class="cast-strip-cell">
                            <span>出勤頻度</span>
                            <strong>{{ displayValue(row.attendance_frequency) }}</strong>
                        </div>
                        <div class="cast-strip-cell is-wide">
                            <span>喜欢类型</span>
                            <strong>{{ displayValue(row.preferred_male_type_text || row.preferred_male_type) }}</strong>
                        </div>
                        <div class="cast-strip-cell">
                            <span>抽烟喝酒</span>
                            <strong>{{ displayValue(row.smoking_drinking_text || row.smoking_drinking) }}</strong>
                        </div>
                        <div class="cast-strip-cell">
                            <span>出勤状态</span>
                            <el-tag size="small">
                                {{ row.attendance_status_text || row.attendance_status || '-' }}
                            </el-tag>
                        </div>
                        <div class="cast-strip-cell">
                            <span>审核状态</span>
                            <el-tag size="small">
                                {{ row.review_status_text || row.review_status || '-' }}
                            </el-tag>
                        </div>
                        <div class="cast-strip-cell is-small">
                            <span>评分</span>
                            <strong>{{ displayValue(row.rating) }}</strong>
                        </div>
                        <div class="cast-strip-cell is-small">
                            <span>收藏</span>
                            <strong>{{ displayValue(row.favorite_count) }}</strong>
                        </div>
                        <div class="cast-strip-cell is-small">
                            <span>排序</span>
                            <strong>{{ displayValue(row.sort) }}</strong>
                        </div>
                        <div class="cast-strip-cell is-tags">
                            <span>表示フラグ</span>
                            <div class="cast-strip-tags">
                                <el-tag v-if="row.is_new" size="small" type="success">新人</el-tag>
                                <el-tag v-else-if="row.is_popular" size="small" type="danger">人気</el-tag>
                                <el-tag v-else-if="row.is_recommended" size="small" type="warning">おすすめ</el-tag>
                                <strong v-else>-</strong>
                            </div>
                        </div>
                        <div class="cast-strip-cell is-tags">
                            <span>标签</span>
                            <div class="cast-strip-tags">
                                <el-tag v-for="tag in row.tags" :key="tag" size="small">
                                    {{ tag }}
                                </el-tag>
                                <strong v-if="!row.tags?.length">-</strong>
                            </div>
                        </div>
                        <div class="cast-strip-cell is-gallery">
                            <span>相册</span>
                            <div class="cast-strip-gallery">
                                <el-image
                                    v-for="image in row.gallery_images"
                                    :key="image"
                                    class="cast-strip-gallery-image"
                                    :src="image"
                                    fit="cover"
                                    :preview-src-list="castPreviewImages(row)"
                                />
                                <strong v-if="!row.gallery_images?.length">-</strong>
                            </div>
                        </div>
                        <div class="cast-strip-cell is-profile">
                            <span>自己紹介</span>
                            <strong>{{ row.profile || '-' }}</strong>
                        </div>
                        <div class="cast-strip-cell is-time">
                            <span>创建时间</span>
                            <strong>{{ formatTime(row.create_time) }}</strong>
                        </div>
                        <div class="cast-strip-cell is-time">
                            <span>更新时间</span>
                            <strong>{{ formatTime(row.update_time) }}</strong>
                        </div>
                        <div class="cast-strip-actions">
                            <el-button
                                v-perms="['cabakura.cast/saveProfile']"
                                type="primary"
                                @click="openCastDialog(row)"
                            >
                                编辑
                            </el-button>
                        </div>
                    </div>
                </div>

                <el-empty
                    v-if="!pager.loading && !pager.lists.length"
                    description="暂无 キャスト"
                    :image-size="72"
                />
            </div>
            <div class="flex justify-end mt-4">
                <pagination v-model="pager" @change="getLists" />
            </div>
        </el-card>

        <el-dialog
            v-model="castDialogVisible"
            :title="castForm.id ? '编辑キャスト' : '创建キャスト'"
            width="720px"
        >
            <el-form :model="castForm" label-width="100px">
                <el-row :gutter="20">
                    <el-col :span="12">
                        <el-form-item label="绑定店铺">
                            <el-select
                                v-model="castForm.shop_id"
                                class="w-full"
                                filterable
                                clearable
                                placeholder="可先不绑定店铺"
                            >
                                <el-option
                                    v-for="shop in shopOptions"
                                    :key="shop.id"
                                    :label="shop.name"
                                    :value="shop.id"
                                />
                            </el-select>
                        </el-form-item>
                        <el-form-item label="キャスト名" required>
                            <el-input v-model="castForm.name" placeholder="例如 一ノ瀬 りお" />
                        </el-form-item>
                        <el-form-item label="假名">
                            <el-input v-model="castForm.kana" placeholder="例如 イチノセ リオ" />
                        </el-form-item>
                        <el-form-item label="年龄">
                            <el-input-number
                                v-model="castForm.age"
                                class="w-full"
                                :min="0"
                                :controls="false"
                            />
                        </el-form-item>
                        <el-form-item label="身高">
                            <el-input-number
                                v-model="castForm.height"
                                class="w-full"
                                :min="0"
                                :controls="false"
                            />
                        </el-form-item>
                        <el-form-item label="三围">
                            <el-input v-model="castForm.measurements" placeholder="例如 B86/W58/H84" />
                        </el-form-item>
                        <el-form-item label="スタイル">
                            <el-input v-model="castForm.style" placeholder="例如 Dカップ / 細身" />
                        </el-form-item>
                        <el-form-item label="血液型">
                            <el-input v-model="castForm.blood_type" placeholder="例如 O型" />
                        </el-form-item>
                        <el-form-item label="出身地">
                            <el-input v-model="castForm.birthplace" placeholder="例如 東京都" />
                        </el-form-item>
                        <el-form-item label="趣味">
                            <el-input v-model="castForm.hobby" placeholder="例如 美容・カフェ巡り" />
                        </el-form-item>
                        <el-form-item label="出勤頻度">
                            <el-input v-model="castForm.attendance_frequency" placeholder="例如 週4〜5日" />
                        </el-form-item>
                        <el-form-item label="喜欢类型">
                            <el-select
                                v-model="castForm.preferred_male_type"
                                class="w-full"
                                filterable
                                clearable
                                placeholder="请选择喜欢类型"
                            >
                                <el-option
                                    v-for="option in fieldOptions('cbk_cast_preferred_male_type')"
                                    :key="option.id || option.value"
                                    :label="option.name"
                                    :value="option.value"
                                />
                            </el-select>
                        </el-form-item>
                        <el-form-item label="出勤状态">
                            <el-select v-model="castForm.attendance_status" class="w-full">
                                <el-option label="出勤中" value="working" />
                                <el-option label="待出勤" value="scheduled" />
                                <el-option label="休息" value="off" />
                            </el-select>
                        </el-form-item>
                    </el-col>
                    <el-col :span="12">
                        <el-form-item label="主图">
                            <material-picker v-model="castForm.main_image" :limit="1" size="100px" />
                        </el-form-item>
                        <el-form-item label="相册">
                            <material-picker
                                v-model="castForm.gallery_images"
                                :limit="9"
                                size="100px"
                            />
                        </el-form-item>
                        <el-form-item label="标签">
                            <el-select
                                v-model="castForm.tags"
                                multiple
                                filterable
                                allow-create
                                class="w-full"
                                placeholder="输入标签后回车"
                            />
                        </el-form-item>
                        <el-form-item label="抽烟喝酒">
                            <el-select
                                v-model="castForm.smoking_drinking"
                                class="w-full"
                                filterable
                                clearable
                                placeholder="请选择抽烟喝酒"
                            >
                                <el-option
                                    v-for="option in fieldOptions('cbk_cast_smoking_drinking')"
                                    :key="option.id || option.value"
                                    :label="option.name"
                                    :value="option.value"
                                />
                            </el-select>
                        </el-form-item>
                        <el-form-item label="排序">
                            <el-input-number
                                v-model="castForm.sort"
                                class="w-full"
                                :min="0"
                                :controls="false"
                            />
                        </el-form-item>
                        <el-form-item label="表示フラグ" required>
                            <el-radio-group v-model="castForm.display_flag">
                                <el-radio label="new">新人</el-radio>
                                <el-radio label="popular">人気</el-radio>
                                <el-radio label="recommended">おすすめ</el-radio>
                            </el-radio-group>
                        </el-form-item>
                    </el-col>
                </el-row>
                <el-form-item label="自己紹介">
                    <el-input
                        v-model="castForm.profile"
                        type="textarea"
                        :rows="4"
                        placeholder="自己紹介を入力してください"
                    />
                </el-form-item>
            </el-form>
            <template #footer>
                <el-button @click="castDialogVisible = false">取消</el-button>
                <el-button type="primary" :loading="castSaving" @click="saveCastProfile">
                    保存キャスト
                </el-button>
            </template>
        </el-dialog>
    </div>
</template>

<script lang="ts" setup name="cabakuraCastLists">
import {
    getCabakuraCastList,
    saveCabakuraCastProfile,
    switchCabakuraCastRecommended
} from '@/api/cabakura/cast'
import { getCabakuraAnswerSettingFields } from '@/api/cabakura/answer-setting'
import { getCabakuraShopList } from '@/api/cabakura/shop'
import { usePaging } from '@/hooks/usePaging'
import { timeFormatTokyo } from '@/utils/util'

const queryParams = reactive({
    keyword: '',
    shop_id: ''
})

const castDialogVisible = ref(false)
const castSaving = ref(false)
const shopOptions = ref<Array<{ id: number; name: string }>>([])
const answerSettingFields = ref<any[]>([])
const shopNameMap = computed<Record<number, string>>(() =>
    shopOptions.value.reduce(
        (map, shop) => {
            map[shop.id] = shop.name
            return map
        },
        {} as Record<number, string>
    )
)

const displayValue = (value: unknown) => {
    if (value === undefined || value === null || value === '') {
        return '-'
    }
    return value
}

const formatTime = (value: unknown) => {
    return timeFormatTokyo(value)
}

const shopDisplayName = (row: any) => {
    return shopNameMap.value[row.shop_id] || (row.shop_id ? `店铺ID ${row.shop_id}` : '未绑定')
}

const castPreviewImages = (row: any) => {
    return [row.main_image, ...(Array.isArray(row.gallery_images) ? row.gallery_images : [])].filter(Boolean)
}

const fieldOptions = (type: string) => {
    for (const group of answerSettingFields.value) {
        const field = group.fields?.find((item: any) => item.type === type)
        if (field) {
            return (field.options || []).filter((option: any) => option.status === 1)
        }
    }
    return []
}

const createEmptyCast = () => ({
    id: 0,
    shop_id: undefined as number | undefined,
    name: '',
    kana: '',
    age: 0,
    height: 0,
    measurements: '',
    style: '',
    blood_type: '',
    birthplace: '',
    hobby: '',
    attendance_frequency: '',
    preferred_male_type: '',
    smoking_drinking: '',
    profile: '',
    main_image: '',
    gallery_images: [] as string[],
    tags: [] as string[],
    attendance_status: 'off',
    review_status: 'draft',
    is_new: false,
    is_popular: false,
    is_recommended: false,
    display_flag: 'new',
    sort: 0
})
const castForm = reactive(createEmptyCast())

const { pager, getLists, resetPage, resetParams } = usePaging({
    fetchFun: getCabakuraCastList,
    params: queryParams
})

const loadShopOptions = async () => {
    const data = await getCabakuraShopList({
        page_no: 1,
        page_size: 200
    })
    shopOptions.value = (data.lists || []).map((item: any) => ({
        id: item.id,
        name: item.name
    }))
}

const openCastDialog = (row?: any) => {
    Object.assign(
        castForm,
        row
            ? {
                  ...createEmptyCast(),
                  ...row,
                  shop_id: row.shop_id || undefined,
                  gallery_images: Array.isArray(row.gallery_images) ? row.gallery_images : [],
                  tags: Array.isArray(row.tags) ? row.tags : [],
                  preferred_male_type: row.preferred_male_type || '',
                  smoking_drinking: row.smoking_drinking || '',
                  is_new: Boolean(row.is_new),
                  is_popular: Boolean(row.is_popular),
                  is_recommended: Boolean(row.is_recommended),
                  display_flag: row.is_new ? 'new' : row.is_popular ? 'popular' : 'recommended'
              }
            : createEmptyCast()
    )
    castDialogVisible.value = true
}

const loadAnswerSettingFields = async () => {
    answerSettingFields.value = await getCabakuraAnswerSettingFields()
}

const saveCastProfile = async () => {
    castForm.shop_id = castForm.shop_id ? Number(castForm.shop_id) : undefined
    castForm.is_new = castForm.display_flag === 'new'
    castForm.is_popular = castForm.display_flag === 'popular'
    castForm.is_recommended = castForm.display_flag === 'recommended'
    castSaving.value = true
    try {
        await saveCabakuraCastProfile(castForm)
        castDialogVisible.value = false
        await getLists()
    } finally {
        castSaving.value = false
    }
}

const handleSwitchRecommended = async (row: any) => {
    try {
        await switchCabakuraCastRecommended({
            id: row.id,
            is_recommended: row.is_recommended
        })
    } catch (error) {
        row.is_recommended = row.is_recommended ? 0 : 1
        throw error
    }
}

onActivated(() => {
    getLists()
    loadAnswerSettingFields()
})

onMounted(() => {
    loadShopOptions()
    loadAnswerSettingFields()
})

getLists()
</script>

<style lang="scss" scoped>
.cast-panel-list {
    min-height: 160px;
}

.cast-strip-panel {
    margin-bottom: 10px;
    border: 1px solid var(--el-border-color-light);
    border-radius: 6px;
    background: var(--el-bg-color);
}

.cast-strip-panel:last-child {
    margin-bottom: 0;
}

.cast-strip-scroll {
    display: flex;
    align-items: center;
    gap: 10px;
    min-height: 86px;
    overflow-x: auto;
    overflow-y: hidden;
    padding: 10px 12px;
}

.cast-strip-identity {
    position: sticky;
    left: 0;
    z-index: 1;
    display: flex;
    align-items: center;
    flex: 0 0 230px;
    gap: 10px;
    min-width: 230px;
    padding-right: 10px;
    background: var(--el-bg-color);
    border-right: 1px solid var(--el-border-color-light);
}

.cast-strip-avatar {
    width: 56px;
    height: 56px;
    border-radius: 6px;
    flex: 0 0 auto;
}

.cast-strip-avatar.is-empty {
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--el-text-color-secondary);
    background: var(--el-fill-color-light);
    font-size: 12px;
}

.cast-strip-name {
    min-width: 0;
}

.cast-strip-name > div {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.cast-strip-cell {
    display: flex;
    flex-direction: column;
    justify-content: center;
    flex: 0 0 132px;
    min-width: 132px;
    min-height: 58px;
    padding: 8px 10px;
    border: 1px solid var(--el-border-color-lighter);
    border-radius: 6px;
    background: var(--el-fill-color-lighter);
}

.cast-strip-cell.is-small {
    flex-basis: 74px;
    min-width: 74px;
}

.cast-strip-cell.is-shop,
.cast-strip-cell.is-wide {
    flex-basis: 190px;
    min-width: 190px;
}

.cast-strip-cell.is-tags {
    flex-basis: 210px;
    min-width: 210px;
}

.cast-strip-cell.is-gallery {
    flex-basis: 170px;
    min-width: 170px;
}

.cast-strip-cell.is-profile {
    flex-basis: 280px;
    min-width: 280px;
}

.cast-strip-cell.is-time {
    flex-basis: 170px;
    min-width: 170px;
}

.cast-strip-cell span {
    margin-bottom: 4px;
    color: var(--el-text-color-secondary);
    font-size: 12px;
    line-height: 1.2;
}

.cast-strip-cell strong {
    overflow: hidden;
    color: var(--el-text-color-primary);
    font-weight: 500;
    line-height: 1.35;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.cast-strip-tags,
.cast-strip-gallery {
    display: flex;
    align-items: center;
    gap: 5px;
    overflow: hidden;
}

.cast-strip-tags {
    flex-wrap: nowrap;
}

.cast-strip-gallery-image {
    width: 36px;
    height: 36px;
    border-radius: 4px;
    flex: 0 0 auto;
}

.cast-strip-actions {
    position: sticky;
    right: 0;
    display: flex;
    align-items: center;
    align-self: stretch;
    flex: 0 0 auto;
    padding-left: 8px;
    background: var(--el-bg-color);
}
</style>
