<?php

declare(strict_types=1);

namespace app\api\logic;

use app\common\model\cabakura\MemberPaymentMethod;

class CabakuraPaymentLogic
{
    public static function lists(int $userId): array
    {
        if ($userId <= 0) return [];

        return MemberPaymentMethod::where('user_id', $userId)
            ->field('id,provider,brand,last4,expiry,holder_name,is_default,create_time')
            ->order('is_default desc,id desc')
            ->select()
            ->toArray();
    }

    public static function create(int $userId, array $params): array
    {
        $cardNumber = preg_replace('/\D+/', '', (string)($params['card_number'] ?? ''));
        $expiry = trim((string)($params['expiry'] ?? ''));
        $cvc = preg_replace('/\D+/', '', (string)($params['cvc'] ?? ''));
        $holderName = trim((string)($params['holder_name'] ?? ''));
        if ($userId <= 0 || !self::validCardNumber($cardNumber) ||
            !preg_match('/^(0[1-9]|1[0-2])\s*\/\s*\d{2}$/', $expiry) ||
            !preg_match('/^\d{3,4}$/', $cvc) || $holderName === '') {
            return [];
        }

        $isDefault = (int)($params['is_default'] ?? 0) === 1;
        if ($isDefault) {
            MemberPaymentMethod::where('user_id', $userId)->update(['is_default' => 0]);
        }
        $now = time();
        $method = MemberPaymentMethod::create([
            'user_id' => $userId,
            'provider' => 'card',
            'provider_method_id' => '',
            'brand' => self::brand($cardNumber),
            'last4' => substr($cardNumber, -4),
            'expiry' => str_replace(' ', '', $expiry),
            'holder_name' => strtoupper($holderName),
            'is_default' => $isDefault ? 1 : 0,
            'create_time' => $now,
            'update_time' => $now,
        ]);

        return ['id' => (int)$method->id];
    }

    private static function validCardNumber(string $number): bool
    {
        return preg_match('/^\d{13,19}$/', $number) === 1;
    }

    private static function brand(string $number): string
    {
        if (str_starts_with($number, '4')) return 'VISA';
        if (preg_match('/^(5[1-5]|2[2-7])/', $number)) return 'Mastercard';
        if (str_starts_with($number, '3')) return 'JCB';
        return 'CARD';
    }
}
