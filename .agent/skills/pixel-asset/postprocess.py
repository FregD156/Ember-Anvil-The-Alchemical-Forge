#!/usr/bin/env python3
import argparse
import sys
from PIL import Image
import numpy as np

# 40-color master palette from ART_PROMPTS.md section A3
PALETTE = """14121C 2A2438 463C5A 6B5F7E 9A8FA3 CFC6C4 F2EBDD
2B1B17 4A2E24 6E4A32 946A44 C08F5A E2B97F
1C2B2A 264A3A 3B6E43 5E9150 94B85A CBD87F
1F3A4D 2F5F6B 4C8C8A 86BFAE A9D8E8
5A1E24 9B2D2B D4542B F28C33 FFC84A FFF1A8
B4633A C99A3C 9FA9B5 5F6B7A 8CA3B8 5FE0C8 2A1E3A
FFE45E 8AD04A""".split()

PAL = np.array([[int(h[i:i+2], 16) for i in (0, 2, 4)] for h in PALETTE])

def remove_bg(img: Image.Image, key=(255, 0, 255), tol=90) -> np.ndarray:
    a = np.array(img.convert("RGBA"))
    d = np.abs(a[..., :3].astype(int) - key).sum(axis=2)
    a[d < tol, 3] = 0
    return a

def snap(a: np.ndarray) -> np.ndarray:
    rgb = a[..., :3].reshape(-1, 3).astype(int)
    idx = ((rgb[:, None, :] - PAL[None]) ** 2).sum(axis=2).argmin(axis=1)
    a[..., :3] = PAL[idx].reshape(a.shape[:2] + (3,))
    a[..., 3] = np.where(a[..., 3] > 127, 255, 0)   # binary alpha
    return a

def main():
    p = argparse.ArgumentParser(description="Post-process generated pixel art to 40-color palette")
    p.add_argument("src", help="Source image path")
    p.add_argument("--canvas", required=True, help="Canvas size of ONE frame, e.g. 32x32 or 16x16")
    p.add_argument("--out", required=True, help="Output image path")
    p.add_argument("--frames", type=int, default=1, help="Number of horizontal frames")
    args = p.parse_args()

    w, h = map(int, args.canvas.lower().split("x"))
    W, H = w * args.frames, h

    raw_img = Image.open(args.src)
    nobg = remove_bg(raw_img)
    img = Image.fromarray(nobg).resize((W, H), Image.BOX)
    out = snap(np.array(img))

    ok = True
    vis = out[..., 3] > 0
    if not vis.any():
        print("FAIL: anh rong (all transparent)")
        ok = False
    elif (out[..., :3][vis] == 0).all(axis=1).any():
        print("FAIL: co pixel den thuan (#000000)")
        ok = False
    elif args.frames == 1 and not vis[-2:].any():
        print("WARN: goc sprite khong cham day canvas (check Y-sort)")

    Image.fromarray(out).save(args.out)
    print("OK" if ok else "FAIL", args.out, f"{W}x{H}")
    sys.exit(0 if ok else 1)

if __name__ == "__main__":
    main()
