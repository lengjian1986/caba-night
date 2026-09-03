<?php

declare(strict_types=1);

namespace app\adminapi\logic\cabakura;

use app\common\enum\cabakura\ShopReviewStatusEnum;
use app\common\model\cabakura\CabakuraCast;
use app\common\model\cabakura\CabakuraCastSchedule;
use app\common\model\cabakura\Member;
use app\common\model\cabakura\ReservationOrder;
use app\common\model\cabakura\Shop;
use app\common\model\cabakura\ShopManager;
use app\common\model\cabakura\SupportTicket;
use think\facade\Config;

class ShopPortalLogic
{
    public static function login(array $params): array
    {
        $mobile = trim((string)($params['mobile'] ?? ''));
        $password = (string)($params['password'] ?? '');
        $manager = ShopManager::where(['mobile' => $mobile])->findOrEmpty();

        if ($manager->isEmpty()) {
            return [];
        }

        $passwordSalt = Config::get('project.unique_identification');
        if ((string)$manager->password !== create_password($password, $passwordSalt)) {
            return [];
        }

        return [
            'manager' => [
                'id' => (int)$manager->id,
                'name' => (string)$manager->name,
                'mobile' => (string)$manager->mobile,
            ],
            'shops' => self::managerShops((int)$manager->id),
            'manager_token' => self::makeToken([
                'manager_id' => (int)$manager->id,
                'scope' => 'manager',
            ]),
        ];
    }

    public static function selectShop(array $params): array
    {
        $managerToken = (string)($params['manager_token'] ?? '');
        $shopId = (int)($params['shop_id'] ?? 0);
        $payload = self::verifyToken($managerToken, 'manager');
        if (empty($payload)) {
            return [];
        }

        $managerId = (int)$payload['manager_id'];
        $shop = Shop::where(['id' => $shopId, 'manager_id' => $managerId])->findOrEmpty();
        if ($shop->isEmpty()) {
            return [];
        }

        return [
            'shop' => self::shopPayload($shop->toArray()),
            'shop_token' => self::makeToken([
                'manager_id' => $managerId,
                'shop_id' => $shopId,
                'scope' => 'shop',
            ]),
        ];
    }

    public static function dashboard(string $token): array
    {
        $payload = self::verifyToken($token, 'shop');
        if (empty($payload)) {
            return [];
        }

        $shopId = (int)$payload['shop_id'];
        $managerId = (int)$payload['manager_id'];
        $shop = Shop::where(['id' => $shopId, 'manager_id' => $managerId])->findOrEmpty();
        if ($shop->isEmpty()) {
            return [];
        }

        $orders = ReservationOrder::where(['shop_name' => $shop->name])
            ->field('id,user_id,order_no,member_name,cast_name,visit_time,people_count,amount,status,pay_status_text,remark,create_time')
            ->limit(10)
            ->order('id desc')
            ->select()
            ->toArray();

        $userIds = array_values(array_filter(array_map(
            static fn(array $order): int => (int)($order['user_id'] ?? 0),
            $orders
        )));
        $memberMap = [];
        if ($userIds) {
            $members = Member::whereIn('user_id', $userIds)
                ->field('user_id,nickname,mobile,email')
                ->select()
                ->toArray();
            foreach ($members as $member) {
                $memberMap[(int)$member['user_id']] = $member;
            }
        }

        foreach ($orders as &$order) {
            $member = $memberMap[(int)($order['user_id'] ?? 0)] ?? [];
            if (trim((string)($member['nickname'] ?? '')) !== '') {
                $order['member_name'] = (string)$member['nickname'];
            }
            $order['member_mobile'] = (string)($member['mobile'] ?? '');
            $order['member_email'] = (string)($member['email'] ?? '');
            $order['visit_time_text'] = (string)($order['visit_time'] ?? '');
            $rawPaymentTime = $order['create_time'] ?? '';
            $order['payment_time_text'] = is_string($rawPaymentTime)
                && preg_match('/^\d{4}-\d{2}-\d{2}/', $rawPaymentTime)
                ? $rawPaymentTime
                : (!empty($rawPaymentTime)
                    ? (new \DateTimeImmutable('@' . (int)$rawPaymentTime))
                        ->setTimezone(new \DateTimeZone('Asia/Tokyo'))
                        ->format('Y-m-d H:i')
                    : '');
        }

        $casts = CabakuraCast::where(['shop_id' => $shopId])
            ->field('id,name,kana,age,height,measurements,attendance_status,review_status,rating')
            ->limit(20)
            ->order('sort desc,id desc')
            ->select()
            ->toArray();

        $castNameMap = [];
        foreach ($casts as $cast) {
            $castNameMap[(int)$cast['id']] = [
                'name' => (string)$cast['name'],
                'kana' => (string)$cast['kana'],
            ];
        }

        $schedules = CabakuraCastSchedule::where('shop_id', '=', $shopId)
            ->where('work_date', '>=', date('Y-m-d'))
            ->field('id,cast_id,work_date,start_time,end_time,attendance_status')
            ->limit(50)
            ->order('work_date asc,start_time asc,id desc')
            ->select()
            ->toArray();
        foreach ($schedules as &$schedule) {
            $castInfo = $castNameMap[(int)$schedule['cast_id']] ?? ['name' => '', 'kana' => ''];
            $schedule['cast_name'] = $castInfo['name'];
            $schedule['cast_kana'] = $castInfo['kana'];
        }

        $tickets = SupportTicket::where(['shop_name' => $shop->name])
            ->field('id,ticket_no,member_name,order_no,status,last_message,update_time')
            ->limit(10)
            ->order('id desc')
            ->select()
            ->toArray();

        return [
            'shop' => self::shopPayload($shop->toArray()),
            'metrics' => [
                'today_orders' => count($orders),
                'pending_orders' => count(array_filter($orders, fn($item) => $item['status'] === 'requesting')),
                'working_casts' => count(array_filter($casts, fn($item) => $item['attendance_status'] === 'working')),
                'pending_tickets' => count(array_filter($tickets, fn($item) => $item['status'] === 'open')),
            ],
            'plans' => $shop->package_sets,
            'casts' => $casts,
            'schedules' => $schedules,
            'orders' => $orders,
            'tickets' => $tickets,
        ];
    }

    public static function updateOrderStatus(string $token, array $params, string $status): bool
    {
        $payload = self::verifyToken($token, 'shop');
        $orderId = (int)($params['id'] ?? 0);
        if (empty($payload) || $orderId <= 0) {
            return false;
        }

        $shop = Shop::where([
            'id' => (int)$payload['shop_id'],
            'manager_id' => (int)$payload['manager_id'],
        ])->findOrEmpty();
        if ($shop->isEmpty()) {
            return false;
        }

        $order = ReservationOrder::where([
            'id' => $orderId,
            'shop_name' => $shop->name,
        ])->findOrEmpty();
        if ($order->isEmpty()) {
            return false;
        }

        ReservationOrder::update([
            'id' => $orderId,
            'status' => $status,
            'update_time' => time(),
        ]);
        return true;
    }

    public static function savePlan(string $token, array $params): bool
    {
        $payload = self::verifyToken($token, 'shop');
        if (empty($payload)) {
            return false;
        }

        $shopId = (int)$payload['shop_id'];
        $managerId = (int)$payload['manager_id'];
        $shop = Shop::where(['id' => $shopId, 'manager_id' => $managerId])->findOrEmpty();
        if ($shop->isEmpty()) {
            return false;
        }

        $plans = $shop->package_sets;
        $index = isset($params['index']) ? (int)$params['index'] : -1;
        $plan = self::normalizePlan($params);
        if (empty($plan)) {
            return false;
        }

        if ($index >= 0 && isset($plans[$index])) {
            $plans[$index] = $plan;
        } else {
            $plans[] = $plan;
        }

        Shop::update([
            'id' => $shopId,
            'package_sets' => json_encode(array_values($plans), JSON_UNESCAPED_UNICODE),
            'update_time' => time(),
        ]);

        return true;
    }

    public static function saveProfile(string $token, array $params): array
    {
        $context = self::shopFromToken($token);
        if (empty($context)) {
            return [];
        }

        /** @var Shop $shop */
        $shop = $context['shop'];
        $licenseFiles = self::normalizeStringList($params['license_files'] ?? []);
        if (empty($licenseFiles) && !empty($params['license_file_name'])) {
            $licenseFiles = [trim((string)$params['license_file_name'])];
        }

        $sensitiveData = [
            'phone' => trim((string)($params['phone'] ?? '')),
            'license_no' => trim((string)($params['license_no'] ?? '')),
            'license_holder_name' => trim((string)($params['license_holder_name'] ?? '')),
            'license_expires_at' => trim((string)($params['license_expires_at'] ?? '')),
            'license_files' => json_encode($licenseFiles, JSON_UNESCAPED_UNICODE),
        ];

        $reviewRequired = false;
        foreach ($sensitiveData as $field => $value) {
            if ((string)$shop->getData($field) !== (string)$value) {
                $reviewRequired = true;
                break;
            }
        }
        $name = trim((string)($params['name'] ?? ''));
        $area = trim((string)($params['area'] ?? ''));
        if ($name === '') {
            throw new \Exception('店舗名を入力してください');
        }
        if ($area === '') {
            throw new \Exception('エリアを選択してください');
        }

        $data = array_merge($sensitiveData, [
            'id' => (int)$context['shop_id'],
            'name' => $name,
            'kana' => trim((string)($params['kana'] ?? '')),
            'area' => $area,
            'station' => trim((string)($params['station'] ?? '')),
            'email' => trim((string)($params['email'] ?? '')),
            'address' => trim((string)($params['address'] ?? '')),
            'business_hours' => trim((string)($params['business_hours'] ?? '')),
            'price_range' => trim((string)($params['price_range'] ?? '')),
            'description' => trim((string)($params['description'] ?? '')),
            'keywords' => self::normalizeKeywords($params['keywords'] ?? ''),
            'license_file_name' => $licenseFiles[0] ?? '',
            'update_time' => time(),
        ]);

        if ($reviewRequired) {
            $data['review_status'] = ShopReviewStatusEnum::SUBMITTED;
            $data['booking_enabled'] = 0;
            $data['submitted_at'] = time();
        }

        Shop::update($data);
        $updatedShop = Shop::findOrEmpty((int)$context['shop_id'])->toArray();

        return [
            'review_required' => $reviewRequired,
            'shop' => self::shopPayload($updatedShop),
        ];
    }

    public static function saveBusinessStatus(string $token, array $params): array
    {
        $context = self::shopFromToken($token);
        if (empty($context)) {
            return [];
        }

        $businessStatus = self::normalizeBusinessStatus((string)($params['business_status'] ?? ''));
        Shop::update([
            'id' => (int)$context['shop_id'],
            'business_status' => $businessStatus,
            'update_time' => time(),
        ]);

        $updatedShop = Shop::findOrEmpty((int)$context['shop_id'])->toArray();

        return [
            'shop' => self::shopPayload($updatedShop),
        ];
    }

    public static function unboundCasts(string $token): ?array
    {
        if (empty(self::shopFromToken($token))) {
            return null;
        }

        return CabakuraCast::where(['shop_id' => 0])
            ->field('id,name,kana,age,height,measurements,attendance_status,review_status,rating')
            ->limit(100)
            ->order('sort desc,id desc')
            ->select()
            ->toArray();
    }

    public static function bindCast(string $token, array $params): bool
    {
        $context = self::shopFromToken($token);
        if (empty($context)) {
            return false;
        }

        $castId = (int)($params['cast_id'] ?? 0);
        if ($castId <= 0) {
            return false;
        }

        $attendanceStatus = self::normalizeAttendanceStatus((string)($params['attendance_status'] ?? 'off'));
        $cast = CabakuraCast::where(['id' => $castId, 'shop_id' => 0])->findOrEmpty();
        if ($cast->isEmpty()) {
            return false;
        }

        CabakuraCast::update([
            'id' => $castId,
            'shop_id' => (int)$context['shop_id'],
            'attendance_status' => $attendanceStatus,
            'update_time' => time(),
        ]);

        return true;
    }

    public static function saveCastAttendance(string $token, array $params): bool
    {
        $context = self::shopFromToken($token);
        if (empty($context)) {
            return false;
        }

        $castId = (int)($params['cast_id'] ?? 0);
        $workDate = trim((string)($params['work_date'] ?? ''));
        $dateRange = $params['date_range'] ?? [];
        $weekdays = $params['weekdays'] ?? [];
        $timeRange = $params['time_range'] ?? [];
        $hasTimeRange = is_array($timeRange) && count($timeRange) >= 2;
        $startTime = $hasTimeRange
            ? trim((string)$timeRange[0])
            : trim((string)($params['start_time'] ?? ''));
        $endTime = $hasTimeRange
            ? trim((string)$timeRange[1])
            : trim((string)($params['end_time'] ?? ''));
        $attendanceStatus = self::normalizeAttendanceStatus((string)($params['attendance_status'] ?? 'scheduled'));
        if ($castId <= 0 || $startTime === '' || $endTime === '') {
            return false;
        }

        $cast = CabakuraCast::where([
            'id' => $castId,
            'shop_id' => (int)$context['shop_id'],
        ])->findOrEmpty();
        if ($cast->isEmpty()) {
            return false;
        }

        $dates = [];
        if (is_array($dateRange) && count($dateRange) === 2) {
            $rangeStart = trim((string)$dateRange[0]);
            $rangeEnd = trim((string)$dateRange[1]);
            $selectedWeekdays = array_values(array_unique(array_map('intval', is_array($weekdays) ? $weekdays : [])));
            $selectedWeekdays = array_values(array_filter($selectedWeekdays, fn($day) => $day >= 1 && $day <= 7));
            if (!self::isDate($rangeStart) || !self::isDate($rangeEnd) || empty($selectedWeekdays)) {
                return false;
            }

            $start = new \DateTimeImmutable($rangeStart, new \DateTimeZone('Asia/Tokyo'));
            $end = new \DateTimeImmutable($rangeEnd, new \DateTimeZone('Asia/Tokyo'));
            if ($start > $end || $start->diff($end)->days > 366) {
                return false;
            }

            for ($date = $start; $date <= $end; $date = $date->modify('+1 day')) {
                if (in_array((int)$date->format('N'), $selectedWeekdays, true)) {
                    $dates[] = $date->format('Y-m-d');
                }
            }
            if (empty($dates)) {
                return false;
            }
        } elseif (self::isDate($workDate)) {
            $dates[] = $workDate;
        } else {
            return false;
        }

        $now = time();
        foreach ($dates as $date) {
            $existing = CabakuraCastSchedule::where([
                'shop_id' => (int)$context['shop_id'],
                'cast_id' => $castId,
                'work_date' => $date,
            ])->find();

            $scheduleData = [
                'shop_id' => (int)$context['shop_id'],
                'cast_id' => $castId,
                'work_date' => $date,
                'start_time' => $startTime,
                'end_time' => $endTime,
                'attendance_status' => $attendanceStatus,
                'update_time' => $now,
            ];
            if ($existing && !$existing->isEmpty()) {
                $scheduleData['id'] = (int)$existing->id;
                CabakuraCastSchedule::update($scheduleData);
            } else {
                $scheduleData['create_time'] = $now;
                CabakuraCastSchedule::create($scheduleData);
            }
        }

        CabakuraCast::where(['id' => $castId])->update([
            'attendance_status' => $attendanceStatus,
            'update_time' => time(),
        ]);

        return true;
    }

    public static function answerFields(string $token): ?array
    {
        $context = self::shopFromToken($token);
        if (empty($context)) {
            return null;
        }

        return AnswerSettingLogic::fields();
    }

    private static function managerShops(int $managerId): array
    {
        $shops = Shop::where(['manager_id' => $managerId])
            ->field('id,name,kana,area,station,phone,email,address,business_hours,price_range,description,keywords,business_status,booking_enabled,review_status,license_no,license_holder_name,license_expires_at,license_file_name,license_files')
            ->order('id desc')
            ->select()
            ->toArray();

        return array_map(fn($shop) => self::shopPayload($shop), $shops);
    }

    private static function shopFromToken(string $token): array
    {
        $payload = self::verifyToken($token, 'shop');
        if (empty($payload)) {
            return [];
        }

        $shopId = (int)$payload['shop_id'];
        $managerId = (int)$payload['manager_id'];
        $shop = Shop::where(['id' => $shopId, 'manager_id' => $managerId])->findOrEmpty();
        if ($shop->isEmpty()) {
            return [];
        }

        return [
            'shop_id' => $shopId,
            'manager_id' => $managerId,
            'shop' => $shop,
        ];
    }

    private static function shopPayload(array $shop): array
    {
        return [
            'id' => (int)$shop['id'],
            'name' => (string)$shop['name'],
            'kana' => (string)($shop['kana'] ?? ''),
            'area' => (string)($shop['area'] ?? ''),
            'station' => (string)($shop['station'] ?? ''),
            'phone' => (string)($shop['phone'] ?? ''),
            'email' => (string)($shop['email'] ?? ''),
            'address' => (string)($shop['address'] ?? ''),
            'business_hours' => (string)($shop['business_hours'] ?? ''),
            'price_range' => (string)($shop['price_range'] ?? ''),
            'description' => (string)($shop['description'] ?? ''),
            'keywords' => (string)($shop['keywords'] ?? ''),
            'license_no' => (string)($shop['license_no'] ?? ''),
            'license_holder_name' => (string)($shop['license_holder_name'] ?? ''),
            'license_expires_at' => (string)($shop['license_expires_at'] ?? ''),
            'license_file_name' => (string)($shop['license_file_name'] ?? ''),
            'license_files' => is_array($shop['license_files'] ?? null)
                ? $shop['license_files']
                : self::decodeStringList($shop['license_files'] ?? ''),
            'business_status' => (string)($shop['business_status'] ?? ''),
            'booking_enabled' => (bool)($shop['booking_enabled'] ?? false),
            'review_status' => (string)($shop['review_status'] ?? ''),
        ];
    }

    private static function normalizePlan(array $params): array
    {
        $name = trim((string)($params['name'] ?? ''));
        $price = max((int)($params['price'] ?? 0), 0);
        $description = trim((string)($params['description'] ?? ''));
        if ($name === '' || $price <= 0) {
            return [];
        }

        $discountType = trim((string)($params['discount_type'] ?? 'none'));
        if (!in_array($discountType, ['none', 'amount', 'percent'], true)) {
            $discountType = 'none';
        }
        $discountValue = max((int)($params['discount_value'] ?? 0), 0);
        if ($discountType === 'percent') {
            $discountValue = min($discountValue, 100);
        }
        if ($discountType === 'none') {
            $discountValue = 0;
        }

        $limitType = trim((string)($params['limit_type'] ?? 'date_range'));
        if (!in_array($limitType, ['date_range', 'usage_count'], true)) {
            $limitType = 'date_range';
        }

        return [
            'name' => $name,
            'description' => $description,
            'image' => trim((string)($params['image'] ?? '')),
            'cast_names' => self::normalizeStringList($params['cast_names'] ?? []),
            'price' => $price,
            'discount_type' => $discountType,
            'discount_value' => $discountValue,
            'limit_type' => $limitType,
            'valid_range' => $limitType === 'date_range'
                ? self::normalizeStringList($params['valid_range'] ?? [])
                : [],
            'usage_limit' => $limitType === 'usage_count'
                ? max((int)($params['usage_limit'] ?? 0), 0)
                : 0,
            'max_people' => max((int)($params['max_people'] ?? 1), 1),
            'status' => self::normalizePlanStatus($params['status'] ?? ($params['is_show'] ?? ($params['is_enabled'] ?? 'public'))),
            'tags' => self::normalizeStringList($params['tags'] ?? []),
        ];
    }

    private static function normalizePlanStatus($status): string
    {
        return in_array($status, [0, false, '0', 'private', 'hidden', 'inactive', 'off', '下架', '非公開'], true)
            ? 'private'
            : 'public';
    }

    private static function decodeStringList($value): array
    {
        if (is_array($value)) {
            return self::normalizeStringList($value);
        }

        $decoded = json_decode((string)$value, true);
        return is_array($decoded) ? self::normalizeStringList($decoded) : [];
    }

    private static function normalizeStringList($items): array
    {
        if (!is_array($items)) {
            return [];
        }

        $normalized = [];
        foreach ($items as $item) {
            $value = trim((string)$item);
            if ($value !== '') {
                $normalized[] = $value;
            }
        }

        return $normalized;
    }

    private static function normalizeKeywords($value): string
    {
        $normalized = preg_replace('/\s+/u', ' ', trim((string)$value));
        return mb_substr($normalized ?? '', 0, 500);
    }

    private static function normalizeAttendanceStatus(string $status): string
    {
        return in_array($status, ['working', 'scheduled', 'off'], true) ? $status : 'off';
    }

    private static function normalizeBusinessStatus(string $status): string
    {
        return in_array($status, ['営業中', '休業中'], true) ? $status : '休業中';
    }

    private static function isDate(string $date): bool
    {
        $time = strtotime($date);
        return $time !== false && date('Y-m-d', $time) === $date;
    }

    private static function makeToken(array $payload): string
    {
        $json = json_encode($payload, JSON_UNESCAPED_UNICODE);
        $body = rtrim(strtr(base64_encode($json), '+/', '-_'), '=');
        $signature = hash_hmac('sha256', $body, (string)Config::get('project.unique_identification'));
        return $body . '.' . $signature;
    }

    private static function verifyToken(string $token, string $scope): array
    {
        if (strpos($token, '.') === false) {
            return [];
        }
        [$body, $signature] = explode('.', $token, 2);
        $expected = hash_hmac('sha256', $body, (string)Config::get('project.unique_identification'));
        if (!hash_equals($expected, $signature)) {
            return [];
        }

        $json = base64_decode(strtr($body, '-_', '+/'));
        $payload = json_decode((string)$json, true);
        if (!is_array($payload) || ($payload['scope'] ?? '') !== $scope) {
            return [];
        }

        return $payload;
    }
}
