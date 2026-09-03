<template>
    <div>
        <el-card class="!border-none" shadow="never">
            <el-form :inline="true" :model="queryParams">
                <el-form-item label="クーポン"><el-input v-model="queryParams.keyword" placeholder="コード/名称" clearable @keyup.enter="resetPage" /></el-form-item>
                <el-form-item label="状態"><el-select v-model="queryParams.status" clearable class="w-[150px]"><el-option label="下書き" value="draft" /><el-option label="公開中" value="published" /><el-option label="停止" value="disabled" /></el-select></el-form-item>
                <el-form-item><el-button type="primary" @click="resetPage">検索</el-button><el-button @click="resetParams">リセット</el-button><el-button v-perms="['cabakura.coupon/save']" type="primary" @click="openDialog()">クーポン作成</el-button></el-form-item>
            </el-form>
        </el-card>
        <el-card class="!border-none mt-4" shadow="never">
            <el-table v-loading="pager.loading" :data="pager.lists" size="large">
                <el-table-column label="コード" prop="code" min-width="140" /><el-table-column label="クーポン名" prop="name" min-width="160" />
                <el-table-column label="割引" prop="discount_text" width="120" /><el-table-column label="使用回数" width="110"><template #default="{row}">{{ row.used_count }} / {{ row.usage_limit }}</template></el-table-column>
                <el-table-column label="有効期間" min-width="130"><template #default="{row}">{{ row.validity_days }}日間</template></el-table-column>
                <el-table-column label="状態" width="110"><template #default="{row}"><el-tag :type="row.status === 'published' ? 'success' : row.status === 'disabled' ? 'danger' : 'info'">{{ statusText(row.status) }}</el-tag></template></el-table-column>
                <el-table-column label="操作" width="230" fixed="right"><template #default="{row}"><el-button v-perms="['cabakura.coupon/distribute']" link type="success" @click="openDistribute(row)">配布</el-button><el-button v-perms="['cabakura.coupon/save']" link type="primary" @click="openDialog(row)">編集</el-button><el-button v-perms="['cabakura.coupon/delete']" link type="danger" @click="remove(row)">削除</el-button></template></el-table-column>
            </el-table><div class="flex justify-end mt-4"><pagination v-model="pager" @change="getLists" /></div>
        </el-card>
        <el-dialog v-model="dialogVisible" :title="form.id ? 'クーポン編集' : 'クーポン作成'" width="620px"><el-form :model="form" label-width="110px">
            <el-form-item label="コード" required><el-input v-model="form.code" placeholder="例 WELCOME1000" /></el-form-item><el-form-item label="名称" required><el-input v-model="form.name" /></el-form-item><el-form-item label="説明"><el-input v-model="form.description" type="textarea" :rows="2" /></el-form-item><el-form-item label="ロゴ画像"><material-picker v-model="form.logo_image" :limit="1" size="110px" /></el-form-item>
            <el-form-item label="割引方式"><el-radio-group v-model="form.discount_type"><el-radio value="fixed">固定額</el-radio><el-radio value="percent">割引率</el-radio></el-radio-group></el-form-item><el-form-item label="割引額/率" required><el-input-number v-model="form.discount_value" :min="1" :max="form.discount_type === 'percent' ? 100 : undefined" class="w-full" :controls="false" /></el-form-item>
            <el-form-item label="適用店舗"><el-select v-model="form.applicable_shop_ids" multiple collapse-tags collapse-tags-tooltip class="w-full" placeholder="店舗を選択"><el-option v-for="shop in shopOptions" :key="shop.id" :label="`${shop.name}（${shop.area || 'エリア未設定'}）`" :value="shop.id" /></el-select><el-button class="mt-2" @click="selectAllShops">すべての店舗を選択</el-button><el-button class="mt-2" @click="form.applicable_shop_ids = []">選択を解除</el-button></el-form-item>
            <el-form-item label="使用回数"><el-input-number v-model="form.usage_limit" :min="1" class="w-full" :controls="false" /><small class="text-gray-400">設定回数を使用すると自動的に利用不可になります</small></el-form-item>
            <el-form-item label="有効期限"><el-input-number v-model="form.validity_days" :min="1" class="w-full" :controls="false" /><small class="text-gray-400">会員が取得した日から計算</small></el-form-item><el-form-item label="状態"><el-select v-model="form.status"><el-option label="下書き" value="draft" /><el-option label="公開中" value="published" /><el-option label="停止" value="disabled" /></el-select></el-form-item>
        </el-form><template #footer><el-button @click="dialogVisible = false">キャンセル</el-button><el-button type="primary" :loading="saving" @click="save">保存</el-button></template></el-dialog>
        <el-dialog v-model="distributeVisible" title="クーポン配布" width="620px"><el-form label-width="90px"><el-form-item label="クーポン"><el-input :model-value="`${distributeCoupon?.name || ''}（${distributeCoupon?.code || ''}）`" disabled /></el-form-item><el-form-item label="電話番号"><div class="flex w-full"><el-input v-model="memberKeyword" placeholder="電話番号で検索" clearable @keyup.enter="searchMembers" /><el-button class="ml-2" @click="searchMembers">検索</el-button></div></el-form-item><el-form-item label="配布先"><el-select v-model="selectedUserIds" multiple collapse-tags collapse-tags-tooltip class="w-full" placeholder="会員を選択"><el-option v-for="member in memberOptions" :key="member.user_id" :label="`${member.nickname || '名称未設定'}（${member.mobile || member.email || '連絡先なし'}）`" :value="member.user_id" /></el-select><el-button class="mt-2" @click="selectAllMembers">すべての会員を選択</el-button><el-button class="mt-2" @click="selectedUserIds = []">選択を解除</el-button></el-form-item><el-form-item label="配布数量"><el-input-number v-model="distributeQuantity" :min="1" :max="selectedUserIds.length || 1" class="w-full" :controls="false" /><small class="text-gray-400">選択した会員のうち、指定人数に配布します</small></el-form-item></el-form><template #footer><el-button @click="distributeVisible = false">キャンセル</el-button><el-button type="primary" :loading="distributing" @click="distribute">配布する</el-button></template></el-dialog>
    </div>
</template>
<script lang="ts" setup name="cabakuraCouponSettings">
import { getCabakuraCoupons, getCabakuraCouponMembers, getCabakuraCouponShops, saveCabakuraCoupon, deleteCabakuraCoupon, distributeCabakuraCoupon } from '@/api/cabakura/coupon'
import { usePaging } from '@/hooks/usePaging'; import feedback from '@/utils/feedback'
const queryParams = reactive({ keyword: '', status: '' }); const dialogVisible = ref(false); const saving = ref(false)
const shopOptions = ref<any[]>([]); const memberOptions = ref<any[]>([]); const memberKeyword = ref(''); const distributeVisible = ref(false); const distributing = ref(false); const selectedUserIds = ref<number[]>([]); const distributeQuantity = ref(1); const distributeCoupon = ref<any>(null)
const form = reactive<any>({ id: 0, code: '', name: '', description: '', logo_image: '', discount_type: 'fixed', discount_value: 0, applicable_shop_ids: [], usage_limit: 1, validity_days: 30, status: 'draft' })
const { pager, getLists, resetPage, resetParams } = usePaging({ fetchFun: getCabakuraCoupons, params: queryParams })
const statusText = (s: string) => ({ draft: '下書き', published: '公開中', disabled: '停止' } as any)[s] || s
const openDialog = (row?: any) => { Object.assign(form, { ...form, ...row, discount_value: Number(row?.discount_value || 0), usage_limit: Number(row?.usage_limit || 1), validity_days: Number(row?.validity_days || 30), applicable_shop_ids: Array.isArray(row?.applicable_shop_ids) ? [...row.applicable_shop_ids] : [] }); dialogVisible.value = true }
const selectAllShops = () => { form.applicable_shop_ids = shopOptions.value.map((shop) => shop.id) }
const openDistribute = (row: any) => { distributeCoupon.value = row; selectedUserIds.value = []; distributeQuantity.value = 1; memberKeyword.value = ''; distributeVisible.value = true; getMembers() }
const selectAllMembers = () => { selectedUserIds.value = memberOptions.value.map((member) => member.user_id) }
const searchMembers = () => getMembers(memberKeyword.value)
const distribute = async () => { if (!selectedUserIds.value.length) return feedback.msgError('配布先を選択してください'); distributing.value = true; try { await distributeCabakuraCoupon({ coupon_id: distributeCoupon.value.id, user_ids: selectedUserIds.value.slice(0, distributeQuantity.value) }); distributeVisible.value = false } finally { distributing.value = false } }
const save = async () => { if (!form.code.trim() || !form.name.trim()) return feedback.msgError('コードと名称を入力してください'); saving.value = true; try { await saveCabakuraCoupon(form); dialogVisible.value = false; await getLists() } finally { saving.value = false } }
const remove = async (row: any) => { await feedback.confirm('クーポンを削除しますか？'); await deleteCabakuraCoupon({ id: row.id }); await getLists() }
const getShops = async () => { const data = await getCabakuraCouponShops(); shopOptions.value = data.lists || [] }
const getMembers = async (keyword = '') => { const data = await getCabakuraCouponMembers({ keyword }); memberOptions.value = data.lists || [] }
onActivated(() => { getLists(); getShops(); getMembers() }); getLists(); getShops(); getMembers()
</script>
