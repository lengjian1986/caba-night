<template>
    <div class="shop-portal-login">
        <section class="login-panel">
            <div class="brand">
                <div class="brand-mark">CN</div>
                <div>
                    <div class="brand-title">Caba Night 店舗管理</div>
                    <div class="brand-subtitle">店舗管理者ログイン</div>
                </div>
            </div>

            <el-form v-if="step === 'account'" :model="loginForm" label-position="top" class="login-form">
                <el-form-item label="電話番号">
                    <el-input v-model="loginForm.mobile" size="large" placeholder="03-1234-5678" />
                </el-form-item>
                <el-form-item label="パスワード">
                    <el-input
                        v-model="loginForm.password"
                        size="large"
                        type="password"
                        show-password
                        placeholder="password"
                        @keyup.enter="handleLogin"
                    />
                </el-form-item>
                <el-button class="w-full" size="large" type="primary" @click="handleLogin">
                    ログイン
                </el-button>
            </el-form>

            <div v-else class="shop-select">
                <div class="section-title">店舗を選択</div>
                <el-empty
                    v-if="!availableShops.length"
                    description="管理できる店舗がありません"
                    :image-size="80"
                />
                <button
                    v-for="shop in availableShops"
                    :key="shop.id"
                    class="shop-option"
                    :class="{ active: selectedShopId === shop.id }"
                    @click="selectedShopId = shop.id"
                >
                    <span>
                        <strong>{{ shop.name }}</strong>
                        <small>{{ shop.area }} / {{ shop.station }}</small>
                    </span>
                    <el-tag size="small" :type="shop.booking_enabled ? 'success' : 'info'">
                        {{ shop.booking_enabled ? '予約受付中' : '準備中' }}
                    </el-tag>
                </button>
                <el-button
                    class="w-full mt-4"
                    size="large"
                    type="primary"
                    :disabled="!availableShops.length"
                    @click="enterDashboard"
                >
                    店舗管理画面へ
                </el-button>
                <el-button class="w-full mt-2" size="large" @click="step = 'account'">
                    戻る
                </el-button>
            </div>
        </section>

        <section class="side-panel">
            <div class="metric-grid">
                <div v-for="item in previewMetrics" :key="item.label" class="metric">
                    <span>{{ item.label }}</span>
                    <strong>{{ item.value }}</strong>
                </div>
            </div>
        </section>
    </div>
</template>

<script lang="ts" setup name="shopPortalLogin">
import { loginShopPortal, selectShopPortalShop } from '@/api/cabakura/shop-portal'
import feedback from '@/utils/feedback'

const router = useRouter()
const step = ref<'account' | 'shop'>('account')
const selectedShopId = ref(1)
const managerToken = ref('')
const loginForm = reactive({
    mobile: '',
    password: ''
})

const availableShops = ref<any[]>([])

const previewMetrics = [
    { label: '本日予約', value: '8' },
    { label: '確認待ち', value: '3' },
    { label: '出勤キャスト', value: '12' },
    { label: '未対応', value: '2' }
]

const handleLogin = async () => {
    if (!loginForm.mobile || !loginForm.password) {
        feedback.msgError('電話番号とパスワードを入力してください')
        return
    }
    const data = await loginShopPortal(loginForm)
    managerToken.value = data.manager_token
    availableShops.value = data.shops || []
    selectedShopId.value = availableShops.value[0]?.id || 0
    step.value = 'shop'
}

const enterDashboard = async () => {
    if (!managerToken.value || !selectedShopId.value) return
    const data = await selectShopPortalShop({
        manager_token: managerToken.value,
        shop_id: selectedShopId.value
    })
    localStorage.setItem('cabago_shop_portal_shop', JSON.stringify(data.shop))
    localStorage.setItem('cabago_shop_portal_token', data.shop_token)
    router.push('/shop-portal/dashboard')
}
</script>

<style lang="scss" scoped>
.shop-portal-login {
    display: grid;
    grid-template-columns: minmax(360px, 480px) minmax(0, 1fr);
    min-height: 100vh;
    background: #f5f7fb;
}

.login-panel {
    display: flex;
    flex-direction: column;
    justify-content: center;
    padding: 56px;
    background: #ffffff;
}

.brand {
    display: flex;
    gap: 14px;
    align-items: center;
    margin-bottom: 36px;
}

.brand-mark {
    display: flex;
    width: 44px;
    height: 44px;
    align-items: center;
    justify-content: center;
    border-radius: 8px;
    color: #ffffff;
    font-weight: 700;
    background: #1f2a44;
}

.brand-title {
    font-size: 22px;
    font-weight: 700;
}

.brand-subtitle {
    margin-top: 4px;
    color: #667085;
}

.login-form,
.shop-select {
    width: 100%;
}

.section-title {
    margin-bottom: 14px;
    font-size: 16px;
    font-weight: 700;
}

.shop-option {
    display: flex;
    width: 100%;
    align-items: center;
    justify-content: space-between;
    padding: 14px 16px;
    margin-bottom: 10px;
    border: 1px solid #d9dee8;
    border-radius: 8px;
    background: #ffffff;
    text-align: left;

    small {
        display: block;
        margin-top: 4px;
        color: #667085;
    }

    &.active {
        border-color: #1f2a44;
        box-shadow: 0 0 0 2px rgba(31, 42, 68, 0.08);
    }
}

.side-panel {
    display: flex;
    align-items: center;
    padding: 56px;
    background:
        linear-gradient(rgba(22, 30, 47, 0.74), rgba(22, 30, 47, 0.74)),
        url('@/views/account/images/login_bg.png') center/cover;
}

.metric-grid {
    display: grid;
    width: 100%;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 16px;
}

.metric {
    padding: 22px;
    border: 1px solid rgba(255, 255, 255, 0.22);
    border-radius: 8px;
    color: #ffffff;
    background: rgba(255, 255, 255, 0.1);

    span {
        display: block;
        color: rgba(255, 255, 255, 0.76);
    }

    strong {
        display: block;
        margin-top: 8px;
        font-size: 30px;
    }
}

@media (max-width: 900px) {
    .shop-portal-login {
        grid-template-columns: 1fr;
    }

    .login-panel,
    .side-panel {
        padding: 28px;
    }

    .side-panel {
        min-height: 280px;
    }
}
</style>
