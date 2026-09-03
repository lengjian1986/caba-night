<template>
    <div>
        <el-card class="!border-none" shadow="never">
            <el-form class="mb-[-16px]" :model="queryParams" :inline="true">
                <el-form-item label="管理者信息">
                    <el-input
                        v-model="queryParams.keyword"
                        class="w-[280px]"
                        placeholder="名字/电话"
                        clearable
                        @keyup.enter="resetPage"
                    />
                </el-form-item>
                <el-form-item>
                    <el-button type="primary" @click="resetPage">查询</el-button>
                    <el-button @click="resetParams">重置</el-button>
                    <el-button class="ml-2" type="primary" @click="openForm()">创建管理者</el-button>
                </el-form-item>
            </el-form>
        </el-card>

        <el-card class="!border-none mt-4" shadow="never">
            <el-table size="large" v-loading="pager.loading" :data="pager.lists">
                <el-table-column label="管理者ID" prop="id" min-width="100" />
                <el-table-column label="名字" prop="name" min-width="160" />
                <el-table-column label="电话" prop="mobile" min-width="160" />
                <el-table-column label="创建时间" prop="create_time_text" min-width="170" />
                <el-table-column label="更新时间" prop="update_time_text" min-width="170" />
                <el-table-column label="操作" fixed="right" width="140">
                    <template #default="{ row }">
                        <el-button
                            v-perms="['cabakura.shop_manager/save']"
                            type="primary"
                            link
                            @click="openForm(row)"
                        >
                            编辑
                        </el-button>
                        <el-button
                            v-perms="['cabakura.shop_manager/delete']"
                            type="danger"
                            link
                            @click="handleDelete(row)"
                        >
                            删除
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
            :title="formData.id ? '编辑管理者' : '创建管理者'"
            width="460px"
            async
            @confirm="handleSave"
        >
            <el-form :model="formData" label-width="90px">
                <el-form-item label="名字" required>
                    <el-input v-model="formData.name" placeholder="请输入名字" />
                </el-form-item>
                <el-form-item label="电话" required>
                    <el-input v-model="formData.mobile" placeholder="请输入电话" />
                </el-form-item>
                <el-form-item :label="formData.id ? '新密码' : '密码'" :required="!formData.id">
                    <el-input
                        v-model="formData.password"
                        type="password"
                        show-password
                        :placeholder="formData.id ? '留空则不修改密码' : '请输入密码'"
                    />
                </el-form-item>
            </el-form>
        </popup>
    </div>
</template>

<script lang="ts" setup name="cabakuraShopManager">
import {
    deleteCabakuraShopManager,
    getCabakuraShopManagerList,
    saveCabakuraShopManager
} from '@/api/cabakura/shop-manager'
import { usePaging } from '@/hooks/usePaging'
import feedback from '@/utils/feedback'

const queryParams = reactive({
    keyword: ''
})

const formPopupRef = shallowRef()
const formData = reactive({
    id: 0,
    name: '',
    mobile: '',
    password: ''
})

const { pager, getLists, resetPage, resetParams } = usePaging({
    fetchFun: getCabakuraShopManagerList,
    params: queryParams
})

const resetForm = () => {
    Object.assign(formData, {
        id: 0,
        name: '',
        mobile: '',
        password: ''
    })
}

const openForm = (row?: any) => {
    resetForm()
    if (row) {
        Object.assign(formData, {
            id: row.id,
            name: row.name,
            mobile: row.mobile,
            password: ''
        })
    }
    formPopupRef.value?.open()
}

const handleSave = async () => {
    await saveCabakuraShopManager(formData)
    formPopupRef.value?.close()
    getLists()
}

const handleDelete = async (row: any) => {
    await feedback.confirm(`确认删除管理者「${row.name}」？`)
    await deleteCabakuraShopManager({ id: row.id })
    getLists()
}

onActivated(() => {
    getLists()
})

getLists()
</script>
