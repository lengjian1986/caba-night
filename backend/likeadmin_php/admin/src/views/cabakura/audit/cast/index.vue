<template>
    <div>
        <el-card class="!border-none" shadow="never">
            <el-form class="mb-[-16px]" :inline="true">
                <el-form-item label="Cast 信息">
                    <el-input class="w-[280px]" placeholder="Cast名/店铺名/手机号" disabled />
                </el-form-item>
                <el-form-item label="审核状态">
                    <el-select class="w-[180px]" model-value="reviewing" disabled>
                        <el-option label="审核中" value="reviewing" />
                    </el-select>
                </el-form-item>
                <el-form-item>
                    <el-button type="primary" disabled>查询</el-button>
                    <el-button disabled>重置</el-button>
                </el-form-item>
            </el-form>
        </el-card>

        <el-card class="!border-none mt-4" shadow="never">
            <el-empty description="Cast 审核数据表和接口接入后，将在这里处理入驻审核。" />
        </el-card>
    </div>
</template>

<script lang="ts" setup name="cabakuraAuditCast"></script>
