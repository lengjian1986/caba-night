<template>
    <div>
        <el-card class="!border-none" shadow="never">
            <el-form class="mb-[-16px]" :model="queryParams" :inline="true">
                <el-form-item label="キーワード">
                    <el-input
                        v-model="queryParams.keyword"
                        class="w-[260px]"
                        placeholder="エリア名/都道府県/市区町村"
                        clearable
                        @keyup.enter="resetPage"
                    />
                </el-form-item>
                <el-form-item label="表示">
                    <el-select
                        v-model="queryParams.is_show"
                        class="w-[140px]"
                        clearable
                        placeholder="すべて"
                    >
                        <el-option label="表示" value="1" />
                        <el-option label="非表示" value="0" />
                    </el-select>
                </el-form-item>
                <el-form-item label="おすすめ">
                    <el-select
                        v-model="queryParams.is_recommended"
                        class="w-[140px]"
                        clearable
                        placeholder="すべて"
                    >
                        <el-option label="おすすめ" value="1" />
                        <el-option label="通常" value="0" />
                    </el-select>
                </el-form-item>
                <el-form-item label="階層">
                    <el-select
                        v-model="queryParams.level"
                        class="w-[140px]"
                        clearable
                        placeholder="すべて"
                    >
                        <el-option label="都道府県" value="1" />
                        <el-option label="市区町村" value="2" />
                        <el-option label="区" value="3" />
                    </el-select>
                </el-form-item>
                <el-form-item>
                    <el-button type="primary" @click="resetPage">検索</el-button>
                    <el-button @click="resetParams">リセット</el-button>
                    <el-button
                        v-perms="['cabakura.area/save']"
                        class="ml-2"
                        type="primary"
                        @click="openAreaDialog()"
                    >
                        エリア追加
                    </el-button>
                </el-form-item>
            </el-form>
        </el-card>

        <el-card class="!border-none mt-4" shadow="never">
            <el-table
                v-loading="pager.loading"
                :data="pager.lists"
                size="large"
                row-key="id"
                default-expand-all
                :tree-props="{ children: 'children' }"
            >
                <el-table-column label="エリア名" prop="name" min-width="160" />
                <el-table-column label="階層" prop="level_text" width="110" />
                <el-table-column label="コード" prop="code" width="120" />
                <el-table-column label="かな" prop="kana" min-width="150" />
                <el-table-column label="都道府県" prop="prefecture" min-width="130" />
                <el-table-column label="表示順" prop="sort" width="90" />
                <el-table-column label="表示" width="100">
                    <template #default="{ row }">
                        <el-switch
                            v-model="row.is_show"
                            v-perms="['cabakura.area/switchShow']"
                            :active-value="1"
                            :inactive-value="0"
                            @change="handleSwitchShow(row)"
                        />
                    </template>
                </el-table-column>
                <el-table-column label="おすすめ" width="120">
                    <template #default="{ row }">
                        <el-switch
                            v-model="row.is_recommended"
                            v-perms="['cabakura.area/switchRecommended']"
                            :active-value="1"
                            :inactive-value="0"
                            @change="handleSwitchRecommended(row)"
                        />
                    </template>
                </el-table-column>
                <el-table-column label="更新日時" prop="updated_at" min-width="160" />
                <el-table-column label="操作" width="150" fixed="right">
                    <template #default="{ row }">
                        <el-button
                            v-perms="['cabakura.area/save']"
                            type="primary"
                            link
                            @click="openAreaDialog(row)"
                        >
                            編集
                        </el-button>
                        <el-button
                            v-perms="['cabakura.area/delete']"
                            type="danger"
                            link
                            @click="handleDeleteArea(row)"
                        >
                            削除
                        </el-button>
                    </template>
                </el-table-column>
            </el-table>
        </el-card>

        <el-dialog
            v-model="areaDialogVisible"
            :title="areaForm.id ? 'エリア編集' : 'エリア追加'"
            width="560px"
        >
            <el-form :model="areaForm" label-width="120px">
                <el-form-item label="階層" required>
                    <el-select v-model="areaForm.level" class="w-full" @change="handleLevelChange">
                        <el-option label="都道府県" :value="1" />
                        <el-option label="市区町村" :value="2" />
                        <el-option label="区" :value="3" />
                    </el-select>
                </el-form-item>
                <el-form-item v-if="areaForm.level > 1" label="親エリア" required>
                    <el-select
                        v-model="areaForm.parent_id"
                        class="w-full"
                        filterable
                        placeholder="親エリアを選択"
                    >
                        <el-option
                            v-for="item in parentOptions"
                            :key="item.id"
                            :label="item.label"
                            :value="item.id"
                        />
                    </el-select>
                </el-form-item>
                <el-form-item label="エリア名" required>
                    <el-input v-model="areaForm.name" placeholder="例：東京都 / 大阪市 / 北区" />
                </el-form-item>
                <el-form-item label="かな">
                    <el-input v-model="areaForm.kana" placeholder="例：とうきょうと" />
                </el-form-item>
                <el-form-item label="コード">
                    <el-input
                        v-model="areaForm.code"
                        placeholder="空の場合は自動採番"
                        :disabled="Boolean(areaForm.code) && !String(areaForm.code).startsWith('custom-')"
                    />
                </el-form-item>
                <el-form-item label="表示順">
                    <el-input-number
                        v-model="areaForm.sort"
                        class="w-full"
                        :min="0"
                        :controls="false"
                    />
                </el-form-item>
                <el-form-item label="表示">
                    <el-switch
                        v-model="areaForm.is_show"
                        :active-value="1"
                        :inactive-value="0"
                    />
                </el-form-item>
                <el-form-item label="おすすめ">
                    <el-switch
                        v-model="areaForm.is_recommended"
                        :active-value="1"
                        :inactive-value="0"
                    />
                </el-form-item>
            </el-form>
            <template #footer>
                <el-button @click="areaDialogVisible = false">キャンセル</el-button>
                <el-button type="primary" :loading="saving" @click="handleSaveArea">
                    保存
                </el-button>
            </template>
        </el-dialog>
    </div>
</template>

<script lang="ts" setup name="cabakuraArea">
import {
    deleteCabakuraArea,
    getCabakuraAreaList,
    saveCabakuraArea,
    switchCabakuraAreaRecommended,
    switchCabakuraAreaShow
} from '@/api/cabakura/area'
import { usePaging } from '@/hooks/usePaging'
import feedback from '@/utils/feedback'
import { ElMessageBox } from 'element-plus'

const queryParams = reactive({
    keyword: '',
    is_show: '',
    is_recommended: '',
    level: ''
})

const areaDialogVisible = ref(false)
const saving = ref(false)
const areaForm = reactive({
    id: 0,
    parent_id: 0,
    level: 2,
    code: '',
    name: '',
    kana: '',
    sort: 0,
    is_show: 1,
    is_recommended: 0
})

const { pager, getLists, resetPage, resetParams } = usePaging({
    fetchFun: getCabakuraAreaList,
    params: queryParams
})

const flattenAreas = (items: any[], depth = 0): any[] => {
    return items.flatMap((item) => [
        {
            ...item,
            label: `${'　'.repeat(depth)}${item.name}`
        },
        ...flattenAreas(item.children || [], depth + 1)
    ])
}

const flatAreas = computed(() => flattenAreas(pager.lists || []))
const parentOptions = computed(() => {
    const parentLevel = Number(areaForm.level) - 1
    return flatAreas.value.filter((item) => Number(item.level) === parentLevel && item.id !== areaForm.id)
})

const openAreaDialog = (row?: any) => {
    Object.assign(areaForm, {
        id: row?.id || 0,
        parent_id: row?.parent_id || 0,
        level: Number(row?.level || 2),
        code: row?.code || '',
        name: row?.name || '',
        kana: row?.kana || '',
        sort: Number(row?.sort || 0),
        is_show: row?.is_show ?? 1,
        is_recommended: row?.is_recommended ?? 0
    })
    areaDialogVisible.value = true
}

const handleLevelChange = () => {
    areaForm.parent_id = 0
}

const handleSaveArea = async () => {
    if (!areaForm.name.trim()) {
        feedback.msgError('エリア名を入力してください')
        return
    }
    if (areaForm.level > 1 && !areaForm.parent_id) {
        feedback.msgError('親エリアを選択してください')
        return
    }

    saving.value = true
    try {
        await saveCabakuraArea(areaForm)
        areaDialogVisible.value = false
        await getLists()
    } finally {
        saving.value = false
    }
}

const handleSwitchShow = async (row: any) => {
    try {
        await switchCabakuraAreaShow({
            id: row.id,
            is_show: row.is_show
        })
    } catch (error) {
        row.is_show = row.is_show ? 0 : 1
        throw error
    }
}

const handleSwitchRecommended = async (row: any) => {
    try {
        await switchCabakuraAreaRecommended({
            id: row.id,
            is_recommended: row.is_recommended
        })
    } catch (error) {
        row.is_recommended = row.is_recommended ? 0 : 1
        throw error
    }
}

const handleDeleteArea = async (row: any) => {
    await ElMessageBox.confirm(`エリア「${row.name}」を削除しますか？`, '削除確認', {
        confirmButtonText: '削除',
        cancelButtonText: 'キャンセル',
        type: 'warning',
        confirmButtonClass: 'el-button--danger'
    })
    await deleteCabakuraArea({ id: row.id })
    await getLists()
}

onActivated(() => {
    getLists()
})

getLists()
</script>
