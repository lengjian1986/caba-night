<template>
    <div class="shop-portal">
        <aside class="portal-side">
            <div class="side-brand">
                <div class="brand-mark">CN</div>
                <div>
                    <strong>Caba Night 店舗管理</strong>
                    <span>{{ selectedShop.name }}</span>
                </div>
            </div>
            <nav>
                <button
                    v-for="item in navItems"
                    :key="item.key"
                    :class="{ active: activeSection === item.key }"
                    @click="activeSection = item.key"
                >
                    {{ item.label }}
                </button>
            </nav>
            <el-button class="logout" @click="logout">ログアウト</el-button>
        </aside>

        <main class="portal-main">
            <header class="portal-header">
                <div>
                    <h1>{{ selectedShop.name }}</h1>
                    <p>{{ selectedShop.area }} / {{ selectedShop.station }}</p>
                </div>
                <div class="portal-header-actions">
                    <el-tag :type="businessStatusTagType" size="large">
                        {{ normalizedBusinessStatus }}
                    </el-tag>
                    <el-tag :type="selectedShop.booking_enabled ? 'success' : 'info'" size="large">
                        {{ selectedShop.booking_enabled ? '予約受付中' : '準備中' }}
                    </el-tag>
                    <el-button
                        :type="normalizedBusinessStatus === '営業中' ? 'warning' : 'success'"
                        :loading="businessStatusSaving"
                        @click="toggleBusinessStatus"
                    >
                        {{ normalizedBusinessStatus === '営業中' ? '休業に切替' : '営業に切替' }}
                    </el-button>
                </div>
            </header>

            <section class="summary-grid">
                <div v-for="item in metrics" :key="item.label" class="summary-card">
                    <span>{{ item.label }}</span>
                    <strong>{{ item.value }}</strong>
                    <small>{{ item.note }}</small>
                </div>
            </section>

            <section v-if="activeSection === 'profile'" class="panel-grid">
                <div class="panel large">
                    <div class="panel-head">
                        <h2>店舗資料</h2>
                    </div>
                    <el-form :model="shopForm" label-position="top">
                        <div class="form-section form-section-head">
                            <div class="form-section-title">基本資料</div>
                            <div class="section-actions">
                                <template v-if="basicEditing">
                                    <el-button @click="cancelBasicEdit">キャンセル</el-button>
                                    <el-button type="primary" :loading="profileSaving" @click="saveBasicProfile">
                                        保存
                                    </el-button>
                                </template>
                                <el-button v-else type="primary" @click="basicEditing = true">編集</el-button>
                            </div>
                        </div>
                        <el-row :gutter="16">
                            <el-col :span="12">
                                <el-form-item label="店舗名">
                                    <el-input v-model="shopForm.name" :disabled="!basicEditing" />
                                </el-form-item>
                            </el-col>
                            <el-col :span="12">
                                <el-form-item label="フリガナ">
                                    <el-input v-model="shopForm.kana" :disabled="!basicEditing" />
                                </el-form-item>
                            </el-col>
                            <el-col :span="12">
                                <el-form-item label="エリア" required>
                                    <div class="grid grid-cols-2 gap-3 w-full">
                                        <el-select
                                            v-model="selectedPrefecture"
                                            filterable
                                            placeholder="都道府県を選択"
                                            :disabled="!basicEditing"
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
                                            v-model="shopForm.area"
                                            filterable
                                            placeholder="市区町村を選択"
                                            :disabled="!basicEditing || !selectedPrefecture"
                                        >
                                            <el-option
                                                v-for="item in cityOptions"
                                                :key="item.id || item.name"
                                                :label="item.name"
                                                :value="item.name"
                                            />
                                        </el-select>
                                    </div>
                                </el-form-item>
                            </el-col>
                            <el-col :span="12">
                                <el-form-item label="メール">
                                    <el-input v-model="shopForm.email" :disabled="!basicEditing" />
                                </el-form-item>
                            </el-col>
                            <el-col :span="12">
                                <el-form-item label="最寄り駅">
                                    <el-input v-model="shopForm.station" :disabled="!basicEditing" />
                                </el-form-item>
                            </el-col>
                            <el-col :span="12">
                                <el-form-item label="営業時間">
                                    <el-input v-model="shopForm.business_hours" :disabled="!basicEditing" />
                                </el-form-item>
                            </el-col>
                            <el-col :span="12">
                                <el-form-item label="価格帯">
                                    <el-input v-model="shopForm.price_range" :disabled="!basicEditing" />
                                </el-form-item>
                            </el-col>
                            <el-col :span="24">
                                <el-form-item label="住所">
                                    <el-input v-model="shopForm.address" :disabled="!basicEditing" />
                                </el-form-item>
                            </el-col>
                            <el-col :span="24">
                                <el-form-item label="店舗説明">
                                    <el-input
                                        v-model="shopForm.description"
                                        type="textarea"
                                        :rows="5"
                                        maxlength="2000"
                                        show-word-limit
                                        :disabled="!basicEditing"
                                        placeholder="店舗の紹介、特徴、注意事項など"
                                    />
                                </el-form-item>
                            </el-col>
                            <el-col :span="24">
                                <el-form-item label="検索キーワード">
                                    <el-input
                                        v-model="shopForm.keywords"
                                        maxlength="500"
                                        show-word-limit
                                        :disabled="!basicEditing"
                                        placeholder="例：新宿 高級 個室 スペース区切りで入力"
                                    />
                                </el-form-item>
                            </el-col>
                        </el-row>

                        <div class="form-section review-required-section">
                            <div class="form-section-head">
                                <div>
                                    <div class="form-section-title">管理画面審査が必要な項目</div>
                                    <div class="form-section-note">
                                        電話番号または営業許可情報を変更すると、管理画面の審査が完了するまで予約受付が停止されます。
                                    </div>
                                </div>
                                <div class="section-actions">
                                    <template v-if="reviewEditing">
                                        <el-button @click="cancelReviewEdit">キャンセル</el-button>
                                        <el-button type="warning" :loading="profileSaving" @click="submitReviewProfile">
                                            審査申請
                                        </el-button>
                                    </template>
                                    <el-button v-else type="primary" @click="reviewEditing = true">編集</el-button>
                                </div>
                            </div>
                        </div>
                        <el-row :gutter="16">
                            <el-col :span="12">
                                <el-form-item label="電話番号">
                                    <el-input v-model="shopForm.phone" :disabled="!reviewEditing" />
                                </el-form-item>
                            </el-col>
                            <el-col :span="12">
                                <el-form-item label="営業許可番号" required>
                                    <el-input v-model="shopForm.license_no" :disabled="!reviewEditing" />
                                </el-form-item>
                            </el-col>
                            <el-col :span="12">
                                <el-form-item label="経営主体">
                                    <el-input v-model="shopForm.license_holder_name" :disabled="!reviewEditing" />
                                </el-form-item>
                            </el-col>
                            <el-col :span="12">
                                <el-form-item label="許可有効期限">
                                    <el-date-picker
                                        v-model="shopForm.license_expires_at"
                                        class="w-full"
                                        type="date"
                                        value-format="YYYY-MM-DD"
                                        placeholder="日付を選択"
                                        :disabled="!reviewEditing"
                                    />
                                </el-form-item>
                            </el-col>
                            <el-col :span="24">
                                <el-form-item label="営業許可証">
                                    <material-picker
                                        v-model="shopForm.license_files"
                                        :limit="6"
                                        size="90px"
                                        :disabled="!reviewEditing"
                                    />
                                </el-form-item>
                            </el-col>
                        </el-row>
                    </el-form>
                </div>
                <div class="panel">
                    <h2>審査ステータス</h2>
                    <el-timeline>
                        <el-timeline-item timestamp="2026-08-05">資料更新</el-timeline-item>
                        <el-timeline-item timestamp="2026-08-06">審査承認</el-timeline-item>
                    </el-timeline>
                </div>
            </section>

            <section v-else-if="activeSection === 'plans'" class="panel">
                <div class="panel-head">
                    <h2>セットプラン</h2>
                    <el-button type="primary" @click="openPlanDialog()">プラン作成</el-button>
                </div>
                <el-table :data="plans" size="large">
                    <el-table-column label="プラン名" prop="name" min-width="180" />
                    <el-table-column label="価格" min-width="120">
                        <template #default="{ row }">¥{{ row.price.toLocaleString() }}</template>
                    </el-table-column>
                    <el-table-column label="人数" prop="people" min-width="100" />
                    <el-table-column label="状態" min-width="120">
                        <template #default="{ row }"><el-tag>{{ row.status_text }}</el-tag></template>
                    </el-table-column>
                    <el-table-column label="操作" width="120" fixed="right">
                        <template #default="{ row }">
                            <el-button type="primary" link @click="openPlanDialog(row)">編集</el-button>
                        </template>
                    </el-table-column>
                </el-table>
            </section>

            <section v-else-if="activeSection === 'casts'" class="panel">
                <div class="panel-head">
                    <h2>キャスト</h2>
                    <el-button type="primary" @click="openCastBindDialog">キャスト追加</el-button>
                </div>
                <el-table :data="casts" size="large">
                    <el-table-column label="名前" prop="name" min-width="140" />
                    <el-table-column label="年齢" prop="age" min-width="80" />
                    <el-table-column label="身長" min-width="90">
                        <template #default="{ row }">{{ row.height }}cm</template>
                    </el-table-column>
                    <el-table-column label="出勤" min-width="120">
                        <template #default="{ row }"><el-tag>{{ row.attendance }}</el-tag></template>
                    </el-table-column>
                    <el-table-column label="操作" width="120" fixed="right">
                        <template #default="{ row }">
                            <el-button type="primary" link @click="openAttendanceDialog(row)">出勤設定</el-button>
                        </template>
                    </el-table-column>
                </el-table>
            </section>

            <section v-else-if="activeSection === 'schedule'" class="panel">
                <div class="panel-head">
                    <h2>出勤シフト</h2>
                    <el-button type="primary" @click="openAttendanceDialog">出勤作成</el-button>
                </div>
                <div v-if="schedule.length" class="schedule-grid">
                    <div v-for="day in schedule" :key="day.id" class="schedule-day">
                        <strong>{{ day.date }}</strong>
                        <span>{{ day.cast }}</span>
                        <small>{{ day.time }}</small>
                    </div>
                </div>
                <el-empty v-else description="出勤シフトはまだ作成されていません。" />
            </section>

            <section v-else-if="activeSection === 'orders'" class="panel">
                <div class="panel-head">
                    <h2>予約注文</h2>
                    <el-select
                        v-model="activeOrderFilter"
                        class="order-filter-select"
                        size="small"
                    >
                        <el-option
                            v-for="item in orderFilterOptions"
                            :key="item.value"
                            :label="item.label"
                            :value="item.value"
                        />
                    </el-select>
                </div>
                <el-table :data="filteredOrders" size="large">
                    <el-table-column label="注文番号" prop="order_no" min-width="170" />
                    <el-table-column label="会員" prop="member" min-width="120" />
                    <el-table-column label="電話番号" prop="member_mobile" min-width="150" />
                    <el-table-column label="メールアドレス" prop="member_email" min-width="200" show-overflow-tooltip />
                    <el-table-column label="来店時間" prop="visit_time" min-width="160" />
                    <el-table-column label="支払時間" prop="payment_time" min-width="160" />
                    <el-table-column label="人数" prop="people" min-width="80" />
                    <el-table-column label="金額" min-width="120">
                        <template #default="{ row }">¥{{ row.amount.toLocaleString() }}</template>
                    </el-table-column>
                    <el-table-column label="备注" prop="remark" min-width="180" show-overflow-tooltip />
                    <el-table-column label="状態" min-width="120">
                        <template #default="{ row }">
                            <el-tag :type="orderStatusTagType(row.status)">
                                {{ row.status_text }}
                            </el-tag>
                        </template>
                    </el-table-column>
                    <el-table-column label="操作" width="160" fixed="right">
                        <template #default="{ row }">
                            <template v-if="row.status === 'confirmed'">
                                <el-button type="danger" link @click="handleCancelOrder(row)">キャンセル</el-button>
                            </template>
                            <template v-else-if="!['cancelled', 'rejected'].includes(row.status)">
                                <el-button type="primary" link @click="handleConfirmOrder(row)">確認</el-button>
                                <el-button type="danger" link @click="handleRejectOrder(row)">拒否</el-button>
                            </template>
                            <el-icon v-else class="order-action-disabled" title="操作不可">
                                <CircleClose />
                            </el-icon>
                        </template>
                    </el-table-column>
                </el-table>
            </section>

            <section v-else class="panel">
                <div class="panel-head">
                    <h2>カスタマサービス</h2>
                    <div class="support-filter">
                        <span>
                            {{ supportOnlyPending ? '未対応のみ' : 'すべて' }}
                            {{ filteredTickets.length }} / {{ tickets.length }}
                        </span>
                        <el-button
                            :type="supportOnlyPending ? 'primary' : 'default'"
                            @click.stop="handleSupportFilterToggle"
                        >
                            {{ supportOnlyPending ? 'すべて表示' : '未対応' }}
                        </el-button>
                    </div>
                </div>
                <el-table v-if="filteredTickets.length" :data="filteredTickets" size="large">
                    <el-table-column label="チケット番号" prop="ticket_no" min-width="160" />
                    <el-table-column label="会員" prop="member" min-width="120" />
                    <el-table-column label="内容" prop="message" min-width="260" />
                    <el-table-column label="状態" min-width="120">
                        <template #default="{ row }">
                            <el-tag :type="supportStatusTagType(row.status)">
                                {{ row.status_text }}
                            </el-tag>
                        </template>
                    </el-table-column>
                    <el-table-column label="操作" width="120" fixed="right">
                        <el-button type="primary" link>返信</el-button>
                    </el-table-column>
                </el-table>
                <el-empty
                    v-else
                    :description="supportOnlyPending ? '未対応のチケットはありません' : 'チケットはありません'"
                />
            </section>
        </main>

        <el-dialog
            v-model="planDialogVisible"
            :title="editingPlanIndex >= 0 ? 'プラン編集' : 'プラン作成'"
            width="620px"
        >
            <el-form :model="planForm" label-position="top">
                <el-form-item label="プラン名" required>
                    <el-input v-model="planForm.name" placeholder="例 Premium Set" />
                </el-form-item>
                <el-form-item label="説明">
                    <el-input
                        v-model="planForm.description"
                        type="textarea"
                        :rows="3"
                        placeholder="プラン説明を入力"
                    />
                </el-form-item>
                <el-row :gutter="16">
                    <el-col :span="12">
                        <el-form-item label="価格" required>
                            <el-input-number
                                v-model="planForm.price"
                                class="w-full"
                                :min="0"
                                :controls="false"
                            />
                        </el-form-item>
                    </el-col>
                    <el-col :span="12">
                        <el-form-item label="最大人数">
                            <el-input-number
                                v-model="planForm.max_people"
                                class="w-full"
                                :min="1"
                                :controls="false"
                            />
                        </el-form-item>
                    </el-col>
                </el-row>
                <el-form-item label="割引タイプ">
                    <el-select
                        v-model="planForm.discount_type"
                        class="w-full"
                        @change="handlePlanDiscountTypeChange"
                    >
                        <el-option label="割引なし" value="none" />
                        <el-option label="固定金額" value="amount" />
                        <el-option label="パーセント" value="percent" />
                    </el-select>
                </el-form-item>
                <el-form-item label="公開状態">
                    <el-radio-group v-model="planForm.status">
                        <el-radio value="public">公開中</el-radio>
                        <el-radio value="private">非公開</el-radio>
                    </el-radio-group>
                </el-form-item>
                <el-form-item v-if="planForm.discount_type !== 'none'" label="割引">
                    <el-input-number
                        v-model="planForm.discount_value"
                        class="w-full"
                        :min="0"
                        :max="planForm.discount_type === 'percent' ? 100 : undefined"
                        :controls="false"
                        :placeholder="
                            planForm.discount_type === 'percent'
                                ? '割引率を入力してください'
                                : '割引後の金額を入力してください'
                        "
                    />
                    <div class="field-hint">
                        {{
                            planForm.discount_type === 'percent'
                                ? '割引率を入力してください（例：20 = 20%OFF）'
                                : '割引後の金額を入力してください（例：8000）'
                        }}
                    </div>
                </el-form-item>
                <el-form-item label="制限方式">
                    <el-radio-group v-model="planForm.limit_type">
                        <el-radio value="date_range">期間指定</el-radio>
                        <el-radio value="usage_count">回数限定</el-radio>
                    </el-radio-group>
                </el-form-item>
                <el-form-item v-if="planForm.limit_type === 'date_range'" label="期間">
                    <el-date-picker
                        v-model="planForm.valid_range"
                        class="w-full"
                        type="daterange"
                        value-format="YYYY-MM-DD"
                        start-placeholder="開始日"
                        end-placeholder="終了日"
                    />
                </el-form-item>
                <el-form-item v-else label="限定回数">
                    <el-input-number
                        v-model="planForm.usage_limit"
                        class="w-full"
                        :min="0"
                        :controls="false"
                    />
                </el-form-item>
                <el-form-item label="紐付けキャスト">
                    <el-select
                        v-model="planForm.cast_names"
                        multiple
                        filterable
                        allow-create
                        class="w-full"
                        placeholder="キャスト名を入力して Enter"
                    />
                </el-form-item>
                <el-form-item label="タグ">
                    <el-select
                        v-model="planForm.tags"
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
                <el-button @click="planDialogVisible = false">キャンセル</el-button>
                <el-button type="primary" :loading="planSaving" @click="savePlan">
                    保存
                </el-button>
            </template>
        </el-dialog>

        <el-dialog v-model="castBindDialogVisible" title="キャスト追加" width="720px">
            <el-table
                v-loading="castBindLoading"
                :data="unboundCasts"
                size="large"
                max-height="420"
            >
                <el-table-column label="名前" prop="name" min-width="140" />
                <el-table-column label="フリガナ" prop="kana" min-width="140" />
                <el-table-column label="年齢" prop="age" min-width="80" />
                <el-table-column label="身長" min-width="90">
                    <template #default="{ row }">{{ row.height ? `${row.height}cm` : '-' }}</template>
                </el-table-column>
                <el-table-column label="初期出勤" width="150">
                    <template #default="{ row }">
                        <el-select v-model="row.attendance_status" size="small">
                            <el-option label="休み" value="off" />
                            <el-option label="出勤予定" value="scheduled" />
                            <el-option label="出勤中" value="working" />
                        </el-select>
                    </template>
                </el-table-column>
                <el-table-column label="操作" width="110" fixed="right">
                    <template #default="{ row }">
                        <el-button
                            type="primary"
                            link
                            :loading="bindingCastId === row.id"
                            @click="bindCast(row)"
                        >
                            追加
                        </el-button>
                    </template>
                </el-table-column>
            </el-table>
            <el-empty
                v-if="!castBindLoading && !unboundCasts.length"
                description="未绑定のキャストはありません"
            />
        </el-dialog>

        <el-dialog v-model="attendanceDialogVisible" title="出勤作成" width="560px">
            <el-form :model="attendanceForm" label-position="top">
                <el-form-item label="キャスト" required>
                    <el-select
                        v-model="attendanceForm.cast_id"
                        class="w-full"
                        filterable
                        placeholder="キャストを選択"
                    >
                        <el-option
                            v-for="cast in casts"
                            :key="cast.id"
                            :label="cast.name || cast.kana || `#${cast.id}`"
                            :value="cast.id"
                        />
                    </el-select>
                </el-form-item>
                <el-form-item label="日付範囲" required>
                    <el-date-picker
                        v-model="attendanceForm.date_range"
                        class="w-full"
                        type="daterange"
                        value-format="YYYY-MM-DD"
                        range-separator="~"
                        start-placeholder="開始日"
                        end-placeholder="終了日"
                    />
                </el-form-item>
                <el-form-item label="曜日" required>
                    <el-checkbox-group v-model="attendanceForm.weekdays" class="weekday-list">
                        <el-checkbox v-for="day in weekdayOptions" :key="day.value" :label="day.value">
                            {{ day.label }}
                        </el-checkbox>
                    </el-checkbox-group>
                </el-form-item>
                <el-form-item label="出勤状態" required>
                    <el-radio-group v-model="attendanceForm.attendance_status" size="default">
                        <el-radio-button label="scheduled">出勤予定</el-radio-button>
                        <el-radio-button label="working">出勤中</el-radio-button>
                        <el-radio-button label="off">休み</el-radio-button>
                    </el-radio-group>
                </el-form-item>
                <el-form-item label="時間" required>
                    <div class="time-range-row">
                        <el-time-select
                            v-model="attendanceForm.start_time"
                            class="time-select"
                            start="00:00"
                            step="00:15"
                            end="23:45"
                            placeholder="開始時間"
                        />
                        <span>~</span>
                        <el-time-select
                            v-model="attendanceForm.end_time"
                            class="time-select"
                            start="00:00"
                            step="00:15"
                            end="23:45"
                            placeholder="終了時間"
                        />
                    </div>
                </el-form-item>
            </el-form>
            <template #footer>
                <el-button @click="attendanceDialogVisible = false">キャンセル</el-button>
                <el-button
                    type="primary"
                    :loading="attendanceSaving"
                    @click="saveAttendance"
                >
                    保存
                </el-button>
            </template>
        </el-dialog>
    </div>
</template>

<script lang="ts" setup name="shopPortalDashboard">
import {
    bindShopPortalCast,
    getShopPortalDashboard,
    getShopPortalUnboundCasts,
    saveShopPortalCastAttendance,
    saveShopPortalBusinessStatus,
    saveShopPortalPlan,
    saveShopPortalProfile,
    getShopPortalAnswerFields,
    confirmShopPortalOrder,
    rejectShopPortalOrder,
    cancelShopPortalOrder
} from '@/api/cabakura/shop-portal'
import { getCabakuraAreaList } from '@/api/cabakura/area'
import feedback from '@/utils/feedback'
import { CircleClose } from '@element-plus/icons-vue'
import { ElMessageBox } from 'element-plus'

const router = useRouter()
type ElTagType = 'primary' | 'success' | 'warning' | 'danger' | 'info'

const selectedShop = reactive({
    id: 0,
    name: '',
    kana: '',
    area: '',
    station: '',
    phone: '',
    email: '',
    address: '',
    business_hours: '',
    price_range: '',
    description: '',
    keywords: '',
    business_status: '',
    license_no: '',
    license_holder_name: '',
    license_expires_at: '',
    license_files: [] as string[],
    review_status: '',
    booking_enabled: false
})

const storedShop = localStorage.getItem('cabago_shop_portal_shop')
if (storedShop) {
    Object.assign(selectedShop, JSON.parse(storedShop))
}

const activeSection = ref('profile')
const navItems = [
    { key: 'profile', label: '店舗資料' },
    { key: 'plans', label: 'セットプラン' },
    { key: 'casts', label: 'キャスト' },
    { key: 'schedule', label: '出勤シフト' },
    { key: 'orders', label: '予約注文' },
    { key: 'support', label: 'カスタマサービス' }
]

const metrics = ref([
    { label: '本日予約', value: '0', note: '所属店舗のみ' },
    { label: '確認待ち', value: '0', note: '店舗確認中' },
    { label: '出勤キャスト', value: '0', note: '所属店舗のみ' },
    { label: '未対応', value: '0', note: '所属店舗のみ' }
])

const shopForm = reactive({ ...selectedShop })
const plans = ref<any[]>([])
const casts = ref<any[]>([])
const schedule = ref<any[]>([])
const orders = ref<any[]>([])
const tickets = ref<any[]>([])
const supportOnlyPending = ref(false)
const activeOrderFilter = ref('all')
const profileSaving = ref(false)
const businessStatusSaving = ref(false)
const basicEditing = ref(false)
const reviewEditing = ref(false)
const planDialogVisible = ref(false)
const planSaving = ref(false)
const editingPlanIndex = ref(-1)
const castBindDialogVisible = ref(false)
const castBindLoading = ref(false)
const bindingCastId = ref(0)
const unboundCasts = ref<any[]>([])
const areaOptions = ref<any[]>([])
const answerSettingFields = ref<any[]>([])
const selectedPrefecture = ref('')
const cityOptions = computed(() => {
    const prefecture = areaOptions.value.find((item) => item.name === selectedPrefecture.value)
    return prefecture?.children || []
})
const attendanceDialogVisible = ref(false)
const attendanceSaving = ref(false)
const attendanceForm = reactive({
    cast_id: undefined as number | undefined,
    date_range: [] as string[],
    weekdays: [] as number[],
    start_time: '',
    end_time: '',
    attendance_status: 'scheduled'
})
const weekdayOptions = [
    { value: 1, label: '月' },
    { value: 2, label: '火' },
    { value: 3, label: '水' },
    { value: 4, label: '木' },
    { value: 5, label: '金' },
    { value: 6, label: '土' },
    { value: 7, label: '日' }
]

const createEmptyPlan = () => ({
    index: -1,
    name: '',
    description: '',
    image: '',
    cast_names: [] as string[],
    price: 0,
    discount_type: 'none',
    discount_value: undefined as number | undefined,
    limit_type: 'date_range',
    valid_range: [] as string[],
    usage_limit: 0,
    max_people: 1,
    status: 'public',
    tags: [] as string[]
})

const planForm = reactive(createEmptyPlan())
const pendingSupportStatuses = ['open']
const supportStatusTextMap: Record<string, string> = {
    open: '未対応',
    pending_operator: '対応中',
    pending_user: '対応中',
    resolved: '対応済み',
    closed: '対応済み'
}

const supportStatusTagType = (status: string): ElTagType =>
    ({
        open: 'warning',
        pending_operator: 'primary',
        pending_user: 'primary',
        resolved: 'success',
        closed: 'success'
    } as Record<string, ElTagType>)[status] || 'info'

const normalizePlanStatus = (item: Record<string, any>) => {
    const value = item.status ?? item.is_show ?? item.is_enabled ?? 'public'
    if ([0, false, '0', 'private', 'hidden', 'inactive', 'off', '下架', '非公開'].includes(value)) {
        return 'private'
    }
    return 'public'
}

const planStatusText = (status: string) => (status === 'private' ? '非公開' : '公開中')

const orderFilterOptions = [
    { label: 'すべて', value: 'all' },
    { label: '確認待ち', value: 'requesting' },
    { label: 'キャンセル済み', value: 'cancelled' },
    { label: '来店待ち', value: 'visit_waiting' },
    { label: '売上', value: 'sales' }
]

const orderStatusTextMap: Record<string, string> = {
    requesting: '確認待ち',
    confirmed: '予約確定',
    unpaid: '未決済',
    paid: '決済済み',
    visited: '来店済み',
    completed: '売上確定',
    cancel_requested: 'キャンセル申請中',
    cancelled: 'キャンセル済み',
    refund_pending: '返金処理中',
    refunded: '返金済み',
    refund_failed: '返金失敗'
}

const orderFilterStatusGroups: Record<string, string[]> = {
    requesting: ['requesting'],
    cancelled: ['cancel_requested', 'cancelled', 'refund_pending', 'refunded', 'refund_failed'],
    visit_waiting: ['confirmed', 'unpaid', 'paid'],
    sales: ['visited', 'completed']
}

const orderStatusTagType = (status: string): ElTagType =>
    ({
        requesting: 'warning',
        confirmed: 'primary',
        unpaid: 'info',
        paid: 'success',
        visited: 'success',
        completed: 'success',
        cancel_requested: 'warning',
        cancelled: 'info',
        refund_pending: 'warning',
        refunded: 'info',
        refund_failed: 'danger'
    } as Record<string, ElTagType>)[status] || 'info'

const filteredOrders = computed(() => {
    if (activeOrderFilter.value === 'all') {
        return orders.value
    }

    const statuses = orderFilterStatusGroups[activeOrderFilter.value] || []
    return orders.value.filter((item) => statuses.includes(item.status))
})

const filteredTickets = computed(() => {
    if (!supportOnlyPending.value) {
        return tickets.value
    }

    return tickets.value.filter((item) => pendingSupportStatuses.includes(item.status))
})

const normalizeBusinessStatus = (status: string) =>
    ['営業中', '营业中', 'open', 'opened', 'business'].includes(status) ? '営業中' : '休業中'

const normalizedBusinessStatus = computed(() => normalizeBusinessStatus(selectedShop.business_status))
const businessStatusTagType = computed(() => (normalizedBusinessStatus.value === '営業中' ? 'success' : 'info'))

const syncAreaSelection = () => {
    if (!shopForm.area || !areaOptions.value.length) return
    const matchedPrefecture = areaOptions.value.find(
        (prefecture) =>
            prefecture.name === shopForm.area ||
            (prefecture.children || []).some((city: any) => city.name === shopForm.area)
    )
    selectedPrefecture.value = matchedPrefecture?.name || ''
}

const handlePrefectureChange = () => {
    shopForm.area = ''
}

const handleSupportFilterToggle = () => {
    supportOnlyPending.value = !supportOnlyPending.value
}

const basicProfileFields = [
    'name',
    'kana',
    'area',
    'email',
    'station',
    'business_hours',
    'price_range',
    'address',
    'description'
]

const reviewProfileFields = [
    'phone',
    'license_no',
    'license_holder_name',
    'license_expires_at',
    'license_files'
]

const copyShopFields = (fields: string[], source: Record<string, any>) => {
    fields.forEach((field) => {
        const value = source[field]
        ;(shopForm as Record<string, any>)[field] = Array.isArray(value) ? [...value] : value
    })
}

const loadDashboard = async () => {
    const token = localStorage.getItem('cabago_shop_portal_token')
    if (!token) {
        router.replace('/shop-portal/login')
        return
    }

    const data = await getShopPortalDashboard(token)
    Object.assign(selectedShop, data.shop || {})
    Object.assign(shopForm, data.shop || {})
    syncAreaSelection()
    localStorage.setItem('cabago_shop_portal_shop', JSON.stringify(data.shop || {}))
    plans.value = (data.plans || []).map((item: any, index: number) => ({
        ...item,
        index,
        name: item.name || '-',
        price: Number(item.price || 0),
        people: item.max_people ? `1-${item.max_people}` : '-',
        status: normalizePlanStatus(item),
        status_text: planStatusText(normalizePlanStatus(item))
    }))
    casts.value = (data.casts || []).map((item: any) => ({
        ...item,
        attendance: item.attendance_status === 'working' ? '出勤中' : item.attendance_status === 'scheduled' ? '出勤予定' : '休み'
    }))
    schedule.value = (data.schedules || []).map((item: any) => ({
        id: item.id,
        date: item.work_date,
        cast: item.cast_name || item.cast_kana || '-',
        time: `${item.start_time || '-'}-${item.end_time || '-'}`,
        attendance_status: item.attendance_status
    }))
    orders.value = (data.orders || []).map((item: any) => ({
        id: Number(item.id || 0),
        order_no: item.order_no,
        member: item.member_name,
        member_mobile: item.member_mobile || '',
        member_email: item.member_email || '',
        visit_time: item.visit_time_text,
        payment_time: item.payment_time_text || '',
        people: item.people_count,
        amount: Number(item.amount || 0),
        remark: item.remark || '',
        status: item.status,
        status_text: orderStatusTextMap[item.status] || item.status
    }))
    tickets.value = (data.tickets || []).map((item: any) => ({
        ticket_no: item.ticket_no,
        member: item.member_name,
        message: item.last_message,
        status: item.status,
        status_text: supportStatusTextMap[item.status] || item.status
    }))
    metrics.value = [
        { label: '本日予約', value: String(data.metrics?.today_orders || 0), note: '所属店舗のみ' },
        { label: '確認待ち', value: String(data.metrics?.pending_orders || 0), note: '店舗確認中' },
        { label: '出勤キャスト', value: String(data.metrics?.working_casts || 0), note: '所属店舗のみ' },
        { label: '未対応', value: String(data.metrics?.pending_tickets || 0), note: '所属店舗のみ' }
    ]
}

const updateOrder = async (
    row: any,
    action: (token: string, id: number) => Promise<any>,
    successMessage: string
) => {
    const token = getShopToken()
    if (!token || !row.id) return
    await action(token, row.id)
    row.status = successMessage === '予約を確定しました' ? 'confirmed' : 'cancelled'
    row.status_text = orderStatusTextMap[row.status]
    feedback.msgSuccess(successMessage)
}

const confirmOrderAction = async (message: string) => {
    try {
        await ElMessageBox.confirm(message, '確認', {
            confirmButtonText: '確認',
            cancelButtonText: 'キャンセル',
            type: 'warning'
        })
        return true
    } catch {
        return false
    }
}

const handleConfirmOrder = async (row: any) => {
    if (await confirmOrderAction('この予約を確定しますか？')) {
        await updateOrder(row, confirmShopPortalOrder, '予約を確定しました')
    }
}

const handleRejectOrder = async (row: any) => {
    if (await confirmOrderAction('この予約を拒否しますか？')) {
        await updateOrder(row, rejectShopPortalOrder, '予約を拒否しました')
    }
}

const handleCancelOrder = async (row: any) => {
    if (await confirmOrderAction('この予約をキャンセルしますか？')) {
        await updateOrder(row, cancelShopPortalOrder, '予約をキャンセルしました')
    }
}

const loadAreaOptions = async () => {
    const data = await getCabakuraAreaList({
        is_show: 1
    })
    areaOptions.value = (data.lists || []).filter((item: any) => Number(item.level) === 1)
    syncAreaSelection()
}

const saveShopProfile = async () => {
    const token = getShopToken()
    if (!token) {
        return null
    }

    return saveShopPortalProfile(token, {
        ...shopForm,
        license_files: Array.isArray(shopForm.license_files) ? shopForm.license_files : []
    })
}

const applySavedShopProfile = async (data: any) => {
    Object.assign(selectedShop, data.shop || {})
    Object.assign(shopForm, data.shop || {})
    syncAreaSelection()
    localStorage.setItem('cabago_shop_portal_shop', JSON.stringify(data.shop || {}))
    await loadDashboard()
}

const toggleBusinessStatus = async () => {
    const token = getShopToken()
    if (!token) {
        return
    }

    const nextStatus = normalizedBusinessStatus.value === '営業中' ? '休業中' : '営業中'
    businessStatusSaving.value = true
    try {
        const data = await saveShopPortalBusinessStatus(token, {
            business_status: nextStatus
        })
        Object.assign(selectedShop, data.shop || {})
        Object.assign(shopForm, data.shop || {})
        localStorage.setItem('cabago_shop_portal_shop', JSON.stringify(data.shop || {}))
        feedback.msgSuccess(`営業状態を${nextStatus}に更新しました`)
    } finally {
        businessStatusSaving.value = false
    }
}

const cancelBasicEdit = () => {
    copyShopFields(basicProfileFields, selectedShop)
    syncAreaSelection()
    basicEditing.value = false
}

const cancelReviewEdit = () => {
    copyShopFields(reviewProfileFields, selectedShop)
    reviewEditing.value = false
}

const saveBasicProfile = async () => {
    if (!shopForm.name.trim()) {
        feedback.msgError('店舗名を入力してください')
        return
    }
    if (!selectedPrefecture.value) {
        feedback.msgError('都道府県を選択してください')
        return
    }
    if (!shopForm.area.trim()) {
        feedback.msgError('市区町村を選択してください')
        return
    }

    profileSaving.value = true
    try {
        const data = await saveShopProfile()
        if (!data) {
            return
        }
        await applySavedShopProfile(data)
        basicEditing.value = false
        feedback.msgSuccess('基本資料を保存しました')
    } finally {
        profileSaving.value = false
    }
}

const submitReviewProfile = async () => {
    if (!shopForm.license_no.trim()) {
        feedback.msgError('営業許可番号を入力してください')
        return
    }

    profileSaving.value = true
    try {
        const data = await saveShopProfile()
        if (!data) {
            return
        }
        await applySavedShopProfile(data)
        reviewEditing.value = false
        feedback.msgSuccess(
            data.review_required
                ? '審査申請を送信しました'
                : '審査対象項目を保存しました'
        )
    } finally {
        profileSaving.value = false
    }
}

const openPlanDialog = (row?: any) => {
    editingPlanIndex.value = typeof row?.index === 'number' ? row.index : -1
    Object.assign(
        planForm,
        row
            ? {
                  ...createEmptyPlan(),
                  ...row,
                  index: editingPlanIndex.value,
                  cast_names: Array.isArray(row.cast_names) ? row.cast_names : [],
                  valid_range: Array.isArray(row.valid_range) ? row.valid_range : [],
                  tags: Array.isArray(row.tags) ? row.tags : [],
                  price: Number(row.price || 0),
                  discount_value:
                      row.discount_value === null || row.discount_value === undefined || row.discount_value === ''
                          ? undefined
                          : Number(row.discount_value),
                  usage_limit: Number(row.usage_limit || 0),
                  max_people: Number(row.max_people || 1)
              }
            : createEmptyPlan()
    )
    loadAnswerSettingFields()
    planDialogVisible.value = true
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

const loadAnswerSettingFields = async () => {
    const token = localStorage.getItem('cabago_shop_portal_token')
    if (!token) {
        return
    }
    answerSettingFields.value = await getShopPortalAnswerFields(token)
}

const handlePlanDiscountTypeChange = () => {
    planForm.discount_value = undefined
}

const getShopToken = () => {
    const token = localStorage.getItem('cabago_shop_portal_token')
    if (!token) {
        router.replace('/shop-portal/login')
        return ''
    }

    return token
}

const openCastBindDialog = async () => {
    const token = getShopToken()
    if (!token) {
        return
    }

    castBindDialogVisible.value = true
    castBindLoading.value = true
    try {
        const data = await getShopPortalUnboundCasts(token)
        unboundCasts.value = (data || []).map((item: any) => ({
            ...item,
            attendance_status: item.attendance_status || 'off'
        }))
    } finally {
        castBindLoading.value = false
    }
}

const bindCast = async (row: any) => {
    const token = getShopToken()
    if (!token) {
        return
    }

    bindingCastId.value = row.id
    try {
        await bindShopPortalCast(token, {
            cast_id: row.id,
            attendance_status: row.attendance_status || 'off'
        })
        feedback.msgSuccess('キャストを追加しました')
        unboundCasts.value = unboundCasts.value.filter((item) => item.id !== row.id)
        await loadDashboard()
    } finally {
        bindingCastId.value = 0
    }
}

const openAttendanceDialog = (cast?: any) => {
    attendanceForm.cast_id = cast?.id ? Number(cast.id) : undefined
    attendanceForm.date_range = []
    attendanceForm.weekdays = []
    attendanceForm.start_time = ''
    attendanceForm.end_time = ''
    attendanceForm.attendance_status = 'scheduled'
    attendanceDialogVisible.value = true
}

const saveAttendance = async () => {
    if (!attendanceForm.cast_id) {
        feedback.msgError('キャストを選択してください')
        return
    }
    if (attendanceForm.date_range.length !== 2) {
        feedback.msgError('日付範囲を選択してください')
        return
    }
    if (!attendanceForm.weekdays.length) {
        feedback.msgError('曜日を選択してください')
        return
    }
    if (!attendanceForm.start_time || !attendanceForm.end_time) {
        feedback.msgError('時間を選択してください')
        return
    }
    if (attendanceForm.start_time === attendanceForm.end_time) {
        feedback.msgError('開始時間と終了時間は別の時間を選択してください')
        return
    }

    const token = getShopToken()
    if (!token) {
        return
    }

    attendanceSaving.value = true
    try {
        await saveShopPortalCastAttendance(token, {
            cast_id: attendanceForm.cast_id,
            date_range: attendanceForm.date_range,
            weekdays: attendanceForm.weekdays,
            start_time: attendanceForm.start_time,
            end_time: attendanceForm.end_time,
            attendance_status: attendanceForm.attendance_status
        })
        feedback.msgSuccess('出勤状態を保存しました')
        attendanceDialogVisible.value = false
        await loadDashboard()
    } finally {
        attendanceSaving.value = false
    }
}

const savePlan = async () => {
    if (!planForm.name.trim()) {
        feedback.msgError('プラン名を入力してください')
        return
    }
    if (Number(planForm.price) <= 0) {
        feedback.msgError('価格を入力してください')
        return
    }

    const token = localStorage.getItem('cabago_shop_portal_token')
    if (!token) {
        router.replace('/shop-portal/login')
        return
    }

    planSaving.value = true
    try {
        await saveShopPortalPlan(token, {
            ...planForm,
            index: editingPlanIndex.value
        })
        planDialogVisible.value = false
        await loadDashboard()
    } finally {
        planSaving.value = false
    }
}

const logout = () => {
    localStorage.removeItem('cabago_shop_portal_shop')
    localStorage.removeItem('cabago_shop_portal_token')
    router.push('/shop-portal/login')
}

loadAreaOptions()
loadDashboard()
loadAnswerSettingFields()

const orderRefreshTimer = window.setInterval(() => {
    if (activeSection.value === 'orders') {
        loadDashboard()
    }
}, 15000)

onUnmounted(() => {
    window.clearInterval(orderRefreshTimer)
})
</script>

<style lang="scss" scoped>
.shop-portal {
    display: grid;
    grid-template-columns: 248px minmax(0, 1fr);
    height: 100vh;
    min-height: 0;
    background: #f5f7fb;
}

.portal-side {
    display: flex;
    flex-direction: column;
    min-height: 0;
    padding: 20px 16px;
    background: #172033;
    color: #ffffff;
}

.side-brand {
    display: flex;
    gap: 12px;
    align-items: center;
    padding: 10px 8px 22px;

    span {
        display: block;
        margin-top: 4px;
        color: rgba(255, 255, 255, 0.7);
        font-size: 12px;
    }
}

.brand-mark {
    display: flex;
    width: 38px;
    height: 38px;
    align-items: center;
    justify-content: center;
    border-radius: 8px;
    background: #ffffff;
    color: #172033;
    font-weight: 700;
}

nav {
    display: grid;
    gap: 6px;

    button {
        height: 42px;
        padding: 0 12px;
        border: 0;
        border-radius: 8px;
        color: rgba(255, 255, 255, 0.75);
        background: transparent;
        text-align: left;

        &.active,
        &:hover {
            color: #ffffff;
            background: rgba(255, 255, 255, 0.12);
        }
    }
}

.logout {
    margin-top: auto;
}

.portal-main {
    min-height: 0;
    padding: 24px;
    overflow-x: hidden;
    overflow-y: auto;
}

.portal-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    margin-bottom: 18px;

    h1 {
        margin: 0;
        font-size: 24px;
        font-weight: 700;
    }

    p {
        margin: 6px 0 0;
        color: #667085;
    }
}

.portal-header-actions {
    display: flex;
    flex: none;
    align-items: center;
    gap: 10px;
}

.summary-grid {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 14px;
    margin-bottom: 18px;
}

.summary-card,
.panel {
    border: 1px solid #e4e7ef;
    border-radius: 8px;
    background: #ffffff;
}

.summary-card {
    padding: 16px;

    span,
    small {
        color: #667085;
    }

    strong {
        display: block;
        margin: 8px 0 4px;
        font-size: 28px;
    }
}

.panel {
    padding: 18px;
}

.panel-grid {
    display: grid;
    grid-template-columns: minmax(0, 1fr) 360px;
    gap: 18px;
}

.panel-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 16px;

    h2 {
        margin: 0;
        font-size: 18px;
        font-weight: 700;
    }
}

.order-filter-select {
    width: 150px;
}

.order-action-disabled {
    color: #98a2b3;
    font-size: 18px;
    cursor: not-allowed;
}

.support-filter {
    display: flex;
    align-items: center;
    gap: 10px;

    span {
        color: #667085;
        font-size: 13px;
    }
}

.schedule-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
    gap: 12px;
}

.schedule-day {
    padding: 14px;
    border: 1px solid #e4e7ef;
    border-radius: 8px;

    span,
    small {
        display: block;
        margin-top: 8px;
        color: #667085;
    }
}

.time-range-row {
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto minmax(0, 1fr);
    width: 100%;
    align-items: center;
    gap: 10px;

    span {
        color: #667085;
    }
}

.weekday-list {
    display: flex;
    flex-wrap: wrap;
    gap: 8px 16px;
}

.time-select {
    width: 100%;
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
    color: #667085;
    font-size: 12px;
    line-height: 1.4;
}

.form-section {
    margin: 4px 0 14px;
}

.form-section-head {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 16px;
}

.section-actions {
    display: flex;
    flex: none;
    gap: 8px;
}

.form-section-title {
    color: #303133;
    font-size: 15px;
    font-weight: 700;
}

.form-section-note {
    margin-top: 6px;
    color: #667085;
    font-size: 12px;
    line-height: 1.5;
}

.review-required-section {
    margin-top: 8px;
    padding-top: 16px;
    border-top: 1px solid #e4e7ef;
}

@media (max-width: 1100px) {
    .shop-portal {
        grid-template-columns: 1fr;
        overflow-y: auto;
    }

    .portal-side {
        position: sticky;
        top: 0;
        z-index: 10;
        min-height: auto;
    }

    .portal-main {
        overflow: visible;
    }

    .summary-grid,
    .panel-grid {
        grid-template-columns: 1fr;
    }
}
</style>
