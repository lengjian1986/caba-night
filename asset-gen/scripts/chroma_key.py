#!/usr/bin/env python3
"""纯色背景 → 透明 PNG + bbox 裁剪 + 质量判定。

用法:
  python chroma_key.py 输入.png --out 输出.png [--color auto|green|magenta|#RRGGBB] [--pad 12] [--max-size 512]

核心原则:脚本最后输出 VERDICT ——
  OK          → 可直接用
  REGENERATE  → 抠图污染严重(彩边/前景撞色),**不要本地硬修**,换个背景色重新生成一张
"""
import argparse, sys
import numpy as np
from PIL import Image

NAMED = {'green': (0, 255, 0), 'magenta': (255, 0, 255), 'blue': (0, 0, 255),
         'cyan': (0, 255, 255), 'black': (0, 0, 0), 'white': (255, 255, 255)}


def detect_bg(a):
    """采样四角 + 边中点,取中位数当背景色"""
    h, w = a.shape[:2]; m = 6
    pts = [a[:m, :m], a[:m, -m:], a[-m:, :m], a[-m:, -m:],
           a[:m, w // 2 - m:w // 2 + m], a[-m:, w // 2 - m:w // 2 + m],
           a[h // 2 - m:h // 2 + m, :m], a[h // 2 - m:h // 2 + m, -m:]]
    s = np.concatenate([p.reshape(-1, 3) for p in pts])
    return tuple(int(x) for x in np.median(s, axis=0))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('input'); ap.add_argument('--out', required=True)
    ap.add_argument('--color', default='auto')
    ap.add_argument('--pad', type=int, default=12)
    ap.add_argument('--max-size', type=int, default=0, help='裁剪后最长边缩放(0=不缩放)')
    ap.add_argument('--thresh', type=float, default=90, help='背景色距阈值')
    ap.add_argument('--soft', type=float, default=40, help='半透明过渡带宽')
    args = ap.parse_args()

    im = Image.open(args.input).convert('RGB')
    a = np.asarray(im).astype(np.float64)
    if args.color == 'auto':
        bg = detect_bg(a)
    elif args.color.startswith('#'):
        bg = tuple(int(args.color[i:i + 2], 16) for i in (1, 3, 5))
    else:
        bg = NAMED[args.color]
    print(f'背景色: {bg}')

    dist = np.sqrt(((a - np.array(bg)) ** 2).sum(-1))
    # alpha: 距离 < thresh 全透, thresh..thresh+soft 渐变, 之外不透明
    alpha = np.clip((dist - args.thresh) / max(args.soft, 1), 0, 1)
    out = np.dstack([a, alpha * 255]).astype(np.uint8)

    # 去彩边(despill): 过渡带像素往去背景色方向压
    edge = (alpha > 0) & (alpha < 1)
    if edge.any():
        bg_arr = np.array(bg, dtype=np.float64)
        px = out[..., :3].astype(np.float64)
        px[edge] = px[edge] - (bg_arr - px[edge].mean(axis=-1, keepdims=True)) * 0.35
        out[..., :3] = np.clip(px, 0, 255).astype(np.uint8)

    img = Image.fromarray(out, 'RGBA')
    bb = img.getchannel('A').point(lambda v: 255 if v > 8 else 0).getbbox()
    if bb is None:
        print('VERDICT: REGENERATE (整图被判为背景 —— 背景色判定失败或素材与背景同色)')
        sys.exit(2)
    p = args.pad
    bb = (max(0, bb[0] - p), max(0, bb[1] - p), min(img.width, bb[2] + p), min(img.height, bb[3] + p))
    img = img.crop(bb)
    if args.max_size and max(img.size) > args.max_size:
        s = args.max_size / max(img.size)
        img = img.resize((max(1, int(img.width * s)), max(1, int(img.height * s))), Image.LANCZOS)
    img.save(args.out)

    # ---- 质量判定 ----
    oa = np.asarray(img).astype(np.float64)
    solid = oa[..., 3] > 200                    # 实心前景
    d2 = np.sqrt(((oa[..., :3] - np.array(bg)) ** 2).sum(-1))
    contaminated = (solid & (d2 < args.thresh * 0.8)).sum() / max(solid.sum(), 1)   # 前景撞背景色
    ring = (oa[..., 3] > 40) & (oa[..., 3] < 200)
    spill = (ring & (d2 < args.thresh)).sum() / max(ring.sum(), 1) if ring.any() else 0  # 彩边残留
    cov = solid.sum() / (img.width * img.height)
    print(f'尺寸 {img.size}  前景覆盖 {cov:.0%}  前景撞色 {contaminated:.1%}  彩边残留 {spill:.1%}')
    if contaminated > 0.02 or spill > 0.30:
        alt = 'magenta(#FF00FF)' if bg[1] >= max(bg[0], bg[2]) else 'green(#00FF00)'
        print(f'VERDICT: REGENERATE (建议换 {alt} 背景色重新生成,不要硬修)')
        sys.exit(2)
    print('VERDICT: OK')


if __name__ == '__main__':
    main()
