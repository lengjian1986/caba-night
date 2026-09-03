import request from '@/utils/request'

export const getCabakuraCoupons = (params: Record<string, any>) => request.get({ url: '/cabakura.coupon/settings', params }, { ignoreCancelToken: true })
export const getCabakuraCouponShops = () => request.get({ url: '/cabakura.coupon/shops' })
export const getCabakuraCouponMembers = (params: Record<string, any> = {}) => request.get({ url: '/cabakura.coupon/members', params })
export const distributeCabakuraCoupon = (params: Record<string, any>) => request.post({ url: '/cabakura.coupon/distribute', params })
export const saveCabakuraCoupon = (params: Record<string, any>) => request.post({ url: '/cabakura.coupon/save', params })
export const deleteCabakuraCoupon = (params: Record<string, any>) => request.post({ url: '/cabakura.coupon/delete', params })
export const switchCabakuraCouponStatus = (params: Record<string, any>) => request.post({ url: '/cabakura.coupon/switchStatus', params })
export const getCabakuraCouponUsage = (params: Record<string, any>) => request.get({ url: '/cabakura.coupon/usage', params }, { ignoreCancelToken: true })
export const getCabakuraCouponDistribution = (params: Record<string, any>) => request.get({ url: '/cabakura.coupon/distribution', params }, { ignoreCancelToken: true })
