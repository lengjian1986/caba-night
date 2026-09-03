<template>
    <div>
        <el-row :gutter="16">
            <el-col v-for="item in summary.metrics" :key="item.key" :xs="24" :sm="12" :md="8" :lg="4">
                <el-card class="!border-none mb-4" shadow="never">
                    <div class="text-sm text-tx-secondary">{{ item.label }}</div>
                    <div class="mt-3 flex items-end">
                        <span class="text-3xl font-medium">{{ item.value }}</span>
                        <span class="ml-1 text-sm text-tx-secondary">{{ item.unit }}</span>
                    </div>
                </el-card>
            </el-col>
        </el-row>

        <el-card class="!border-none" shadow="never">
            <template #header>
                <span class="font-medium">待办事项</span>
            </template>
            <el-table v-loading="loading" :data="summary.todo" size="large">
                <el-table-column label="类型" prop="type" min-width="140" />
                <el-table-column label="事项" prop="title" min-width="320" />
                <el-table-column label="时间" prop="time" min-width="180" />
            </el-table>
        </el-card>
    </div>
</template>

<script lang="ts" setup name="cabakuraDashboard">
import { getCabakuraDashboardSummary } from '@/api/cabakura/dashboard'

const loading = ref(false)
const summary = reactive({
    metrics: [] as any[],
    todo: [] as any[]
})

const getSummary = async () => {
    loading.value = true
    try {
        const data = await getCabakuraDashboardSummary()
        summary.metrics = data.metrics || []
        summary.todo = data.todo || []
    } finally {
        loading.value = false
    }
}

onActivated(() => {
    getSummary()
})

getSummary()
</script>
