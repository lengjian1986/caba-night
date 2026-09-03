<?php

declare(strict_types=1);

namespace app\api\logic;

use app\common\model\cabakura\ShopFavorite;
use app\common\model\cabakura\CabakuraCast;
use app\common\model\cabakura\CastFavorite;
use app\common\model\cabakura\Shop;

class CabakuraFavoriteLogic
{
    public static function castStatus(int $userId, int $castId): bool
    {
        return $userId > 0 && $castId > 0 && !CastFavorite::where([
            'user_id' => $userId,
            'cast_id' => $castId,
        ])->findOrEmpty()->isEmpty();
    }

    public static function castToggle(int $userId, int $castId): bool
    {
        if ($userId <= 0 || $castId <= 0 || CabakuraCast::findOrEmpty($castId)->isEmpty()) {
            return false;
        }
        $favorite = CastFavorite::where(['user_id' => $userId, 'cast_id' => $castId])->findOrEmpty();
        if ($favorite->isEmpty()) {
            CastFavorite::create(['user_id' => $userId, 'cast_id' => $castId, 'create_time' => time()]);
            return true;
        }
        $favorite->delete();
        return false;
    }

    public static function castLists(int $userId): array
    {
        if ($userId <= 0) return [];
        $castIds = CastFavorite::where('user_id', $userId)->order('id desc')->column('cast_id');
        if (empty($castIds)) return [];
        $casts = CabakuraCast::whereIn('id', $castIds)->select()->toArray();
        $shopIds = array_values(array_unique(array_filter(array_map(fn($cast) => (int)($cast['shop_id'] ?? 0), $casts))));
        $shops = empty($shopIds) ? [] : Shop::whereIn('id', $shopIds)->column('name', 'id');
        $byId = [];
        foreach ($casts as $cast) $byId[(int)$cast['id']] = $cast;
        $result = [];
        foreach ($castIds as $castId) {
            $cast = $byId[(int)$castId] ?? null;
            if (!$cast) continue;
            $result[] = [
                'id' => (int)$cast['id'],
                'shop_id' => (int)$cast['shop_id'],
                'name' => (string)$cast['name'],
                'shop' => (string)($shops[(int)$cast['shop_id']] ?? ''),
                'area' => '',
                'image' => (string)($cast['main_image'] ?? ''),
                'main_image' => (string)($cast['main_image'] ?? ''),
                'height' => (int)($cast['height'] ?? 0),
                'age' => (int)($cast['age'] ?? 0),
                'rating' => (string)($cast['rating'] ?? ''),
                'tags' => $cast['tags'] ?? [],
                'status' => (string)($cast['attendance_status'] ?? 'off'),
                'is_new' => (int)($cast['is_new'] ?? 0),
                'is_popular' => (int)($cast['is_popular'] ?? 0),
                'is_recommended' => (int)($cast['is_recommended'] ?? 0),
            ];
        }
        return $result;
    }
    public static function status(int $userId, int $shopId): bool
    {
        return $userId > 0 && $shopId > 0 && !ShopFavorite::where([
            'user_id' => $userId,
            'shop_id' => $shopId,
        ])->findOrEmpty()->isEmpty();
    }

    public static function toggle(int $userId, int $shopId): bool
    {
        if ($userId <= 0 || $shopId <= 0 || Shop::findOrEmpty($shopId)->isEmpty()) {
            return false;
        }

        $favorite = ShopFavorite::where([
            'user_id' => $userId,
            'shop_id' => $shopId,
        ])->findOrEmpty();
        if ($favorite->isEmpty()) {
            ShopFavorite::create([
                'user_id' => $userId,
                'shop_id' => $shopId,
                'create_time' => time(),
            ]);
            return true;
        }

        $favorite->delete();
        return false;
    }

    public static function lists(int $userId): array
    {
        if ($userId <= 0) {
            return [];
        }

        $shopIds = ShopFavorite::where('user_id', $userId)
            ->order('id desc')
            ->column('shop_id');
        if (empty($shopIds)) {
            return [];
        }

        $shops = Shop::whereIn('id', $shopIds)->select()->toArray();
        $byId = [];
        foreach ($shops as $shop) {
            $byId[(int)$shop['id']] = $shop;
        }

        $result = [];
        foreach ($shopIds as $shopId) {
            $shop = $byId[(int)$shopId] ?? null;
            if (!$shop) {
                continue;
            }
            $images = is_array($shop['shop_images'] ?? null) ? $shop['shop_images'] : [];
            $image = (string)($images[0] ?? $shop['logo_image'] ?? '');
            $result[] = [
                'id' => (int)$shop['id'],
                'name' => (string)($shop['name'] ?? ''),
                'area' => (string)($shop['area'] ?? ''),
                'description' => (string)($shop['description'] ?? ''),
                'address' => (string)($shop['address'] ?? ''),
                'station' => (string)($shop['station'] ?? ''),
                'business_hours' => (string)($shop['business_hours'] ?? ''),
                'price' => (string)($shop['price_range'] ?? ''),
                'business_status' => (string)($shop['business_status'] ?? ''),
                'booking_enabled' => !empty($shop['booking_enabled']),
                'image' => $image,
                'shop_images' => $images,
                'package_sets' => $shop['package_sets'] ?? [],
                'tags' => $shop['tags'] ?? [],
                'rating' => '4.8',
            ];
        }
        return $result;
    }
}
