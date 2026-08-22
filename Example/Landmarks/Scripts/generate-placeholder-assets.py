#!/usr/bin/env python3
"""Regenerates the placeholder asset catalog for the Landmarks example.

Apple's sample-code license excludes the sample's photographs, so this
example ships with generated art instead: one deterministic landscape per
landmark id, so the app looks coherent without redistributing anything.

    Scripts/generate-placeholder-assets.py

Run this before committing if you imported the real photographs with
Scripts/import-apple-assets.sh.
"""
import json
import math
import os
import shutil
import struct
import zlib

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Sources", "Resources", "Assets.xcassets")
# Landmark ids used by LandmarkData.swift, plus the collection cover ids.
IDS = list(range(1001, 1023))


def png(path, w, h, pixel):
    raw = b""
    for y in range(h):
        raw += b"\x00"
        row = bytearray()
        for x in range(w):
            r, g, b = pixel(x / (w - 1), y / (h - 1))
            row += bytes((max(0, min(255, int(r))), max(0, min(255, int(g))), max(0, min(255, int(b)))))
        raw += bytes(row)

    def chunk(tag, data):
        c = tag + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(raw, 6)))
        f.write(chunk(b"IEND", b""))


def hsv(hue, s, v):
    i = int(hue * 6) % 6
    f = hue * 6 - int(hue * 6)
    p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
    rgb = [(v, t, p), (q, v, p), (p, v, t), (p, q, v), (t, p, v), (v, p, q)][i]
    return tuple(c * 255 for c in rgb)


def scene(seed):
    hue = (seed * 0.6180339887) % 1.0
    sky_top, sky_bottom = hsv(hue, 0.55, 0.55), hsv((hue + 0.08) % 1.0, 0.35, 0.95)
    ground = hsv((hue + 0.45) % 1.0, 0.5, 0.45)

    def ridge(x):
        return (0.62
                + 0.10 * math.sin(6.28 * (x * (1.5 + seed % 3) + seed))
                + 0.05 * math.sin(6.28 * (x * (4 + seed % 5) + seed * 2)))

    def pixel(u, v):
        r = ridge(u)
        if v < r:
            t = v / r
            return tuple(a + (b - a) * t for a, b in zip(sky_top, sky_bottom))
        shade = 1 - (v - r) * 0.8
        return tuple(c * shade for c in ground)

    return pixel


def imageset(name, w, h, seed):
    d = os.path.join(ROOT, "Landmark placeholders", name + ".imageset")
    os.makedirs(d, exist_ok=True)
    png(os.path.join(d, name + ".png"), w, h, scene(seed))
    json.dump({"images": [{"filename": name + ".png", "idiom": "universal"}],
               "info": {"author": "scaffolding-example", "version": 1}},
              open(os.path.join(d, "Contents.json"), "w"), indent=2)


def colorset(name, contents):
    d = os.path.join(ROOT, name + ".colorset")
    os.makedirs(d, exist_ok=True)
    json.dump(contents, open(os.path.join(d, "Contents.json"), "w"), indent=2)


def main():
    shutil.rmtree(ROOT, ignore_errors=True)
    os.makedirs(ROOT, exist_ok=True)
    json.dump({"info": {"author": "scaffolding-example", "version": 1}},
              open(os.path.join(ROOT, "Contents.json"), "w"), indent=2)
    for landmark_id in IDS:
        imageset(str(landmark_id), 480, 320, landmark_id)
        imageset(f"{landmark_id}-thumb", 240, 180, landmark_id)
    colorset("AccentColor", {
        "colors": [{"color": {"platform": "universal", "reference": "systemIndigoColor"}, "idiom": "universal"}],
        "info": {"author": "scaffolding-example", "version": 1}})
    colorset("badgeShowHideColor", {
        "colors": [
            {"color": {"color-space": "srgb", "components": {"alpha": "1.000", "red": "0.000", "green": "0.000", "blue": "0.000"}}, "idiom": "universal"},
            {"appearances": [{"appearance": "luminosity", "value": "dark"}],
             "color": {"color-space": "srgb", "components": {"alpha": "1.000", "red": "1.000", "green": "1.000", "blue": "1.000"}}, "idiom": "universal"},
        ],
        "info": {"author": "scaffolding-example", "version": 1}})
    print(f"Regenerated placeholder art for {len(IDS)} landmarks in {ROOT}")


if __name__ == "__main__":
    main()
