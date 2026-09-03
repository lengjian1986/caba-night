<template>
    <div>
        <el-card class="!border-none" shadow="never">
            <el-form class="mb-[-16px]" :model="queryParams" :inline="true">
                <el-form-item label="本文">
                    <el-input
                        v-model="queryParams.keyword"
                        class="w-[280px]"
                        placeholder="本文で検索"
                        clearable
                        @keyup.enter="resetPage"
                    />
                </el-form-item>
                <el-form-item label="表示">
                    <el-select
                        v-model="queryParams.is_show"
                        class="w-[160px]"
                        clearable
                        placeholder="すべて"
                    >
                        <el-option label="表示" value="1" />
                        <el-option label="非表示" value="0" />
                    </el-select>
                </el-form-item>
                <el-form-item>
                    <el-button type="primary" @click="resetPage">検索</el-button>
                    <el-button @click="resetParams">リセット</el-button>
                    <el-button
                        v-perms="['cabakura.news/save']"
                        class="ml-2"
                        type="primary"
                        @click="openNewsDialog()"
                    >
                        ニュース作成
                    </el-button>
                </el-form-item>
            </el-form>
        </el-card>

        <el-card class="!border-none mt-4" shadow="never">
            <el-table size="large" v-loading="pager.loading" :data="pager.lists">
                <el-table-column label="Logo" width="110">
                    <template #default="{ row }">
                        <el-image
                            v-if="row.logo_image"
                            class="news-logo"
                            :src="row.logo_image"
                            fit="cover"
                            :preview-src-list="[row.logo_image]"
                        />
                        <div v-else class="news-logo is-empty">NEWS</div>
                    </template>
                </el-table-column>
                <el-table-column label="本文" min-width="360">
                    <template #default="{ row }">
                        <div class="news-content">{{ row.content || '-' }}</div>
                    </template>
                </el-table-column>
                <el-table-column label="タイトル" prop="title" min-width="220" />
                <el-table-column label="リンク先" prop="link" min-width="240" />
                <el-table-column label="表示" width="110">
                    <template #default="{ row }">
                        <el-switch
                            v-model="row.is_show"
                            v-perms="['cabakura.news/switchShow']"
                            :active-value="1"
                            :inactive-value="0"
                            @change="handleSwitchShow(row)"
                        />
                    </template>
                </el-table-column>
                <el-table-column label="排序" prop="sort" width="90" />
                <el-table-column label="更新日時" prop="updated_at" min-width="160" />
                <el-table-column label="操作" width="110" fixed="right">
                    <template #default="{ row }">
                        <el-button
                            v-perms="['cabakura.news/save']"
                            type="primary"
                            link
                            @click="openNewsDialog(row)"
                        >
                            編集
                        </el-button>
                    </template>
                </el-table-column>
            </el-table>
            <div class="flex justify-end mt-4">
                <pagination v-model="pager" @change="getLists" />
            </div>
        </el-card>

        <el-dialog
            v-model="newsDialogVisible"
            :title="newsForm.id ? 'ニュース編集' : 'ニュース作成'"
            width="680px"
        >
            <el-form :model="newsForm" label-width="90px">
                <el-form-item label="Logo">
                    <material-picker v-model="newsForm.logo_image" :limit="1" size="100px" />
                </el-form-item>
                <el-form-item label="タイトル">
                    <el-input
                        v-model="newsForm.title"
                        placeholder="ニュースタイトルを入力してください"
                        maxlength="255"
                        show-word-limit
                    />
                </el-form-item>
                <el-form-item label="リンク先">
                    <el-input
                        v-model="newsForm.link"
                        placeholder="deeplinkまたはURLを入力してください"
                        maxlength="500"
                    />
                </el-form-item>
                <el-form-item label="本文" required>
                    <el-input
                        v-model="newsForm.content"
                        type="textarea"
                        :rows="8"
                        placeholder="ニュース本文を入力してください"
                    />
                </el-form-item>
                <el-form-item label="排序">
                    <el-input-number
                        v-model="newsForm.sort"
                        class="w-full"
                        :min="0"
                        :controls="false"
                    />
                </el-form-item>
                <el-form-item label="表示">
                    <el-switch
                        v-model="newsForm.is_show"
                        :active-value="1"
                        :inactive-value="0"
                    />
                </el-form-item>
            </el-form>
            <template #footer>
                <el-button @click="newsDialogVisible = false">キャンセル</el-button>
                <el-button type="primary" :loading="saving" @click="handleSaveNews">
                    保存
                </el-button>
            </template>
        </el-dialog>
    </div>
</template>

<script lang="ts" setup name="cabakuraNews">
import {
    getCabakuraNewsList,
    saveCabakuraNews,
    switchCabakuraNewsShow
} from '@/api/cabakura/news'
import { usePaging } from '@/hooks/usePaging'
import feedback from '@/utils/feedback'

const queryParams = reactive({
    keyword: '',
    is_show: ''
})

const newsDialogVisible = ref(false)
const saving = ref(false)
const newsForm = reactive({
    id: 0,
    logo_image: '',
    title: '',
    link: '',
    content: '',
    sort: 0,
    is_show: 1
})

const { pager, getLists, resetPage, resetParams } = usePaging({
    fetchFun: getCabakuraNewsList,
    params: queryParams
})

const openNewsDialog = (row?: any) => {
    Object.assign(newsForm, {
        id: row?.id || 0,
        logo_image: row?.logo_image || '',
        title: row?.title || '',
        link: row?.link || '',
        content: row?.content || '',
        sort: Number(row?.sort || 0),
        is_show: row?.is_show ?? 1
    })
    newsDialogVisible.value = true
}

const handleSaveNews = async () => {
    if (!newsForm.content.trim()) {
        feedback.msgError('本文を入力してください')
        return
    }

    saving.value = true
    try {
        await saveCabakuraNews(newsForm)
        newsDialogVisible.value = false
        await getLists()
    } finally {
        saving.value = false
    }
}

const handleSwitchShow = async (row: any) => {
    try {
        await switchCabakuraNewsShow({
            id: row.id,
            is_show: row.is_show
        })
    } catch (error) {
        row.is_show = row.is_show ? 0 : 1
        throw error
    }
}

onActivated(() => {
    getLists()
})

getLists()
</script>

<style lang="scss" scoped>
.news-logo {
    width: 64px;
    height: 64px;
    border-radius: 6px;
}

.news-logo.is-empty {
    display: flex;
    align-items: center;
    justify-content: center;
    border: 1px solid var(--el-border-color-light);
    color: #667085;
    font-size: 12px;
}

.news-content {
    display: -webkit-box;
    overflow: hidden;
    white-space: pre-line;
    -webkit-box-orient: vertical;
    -webkit-line-clamp: 3;
}
</style>
