#!/usr/bin/env python3
"""
Generate reel beat frames: AI background + bold text overlay.

Input:  JSON brief (--brief path)
Output: beat_001.png, beat_002.png, ... in --outdir

Design rules (from visual QA):
  - ALL text is white for maximum contrast — no colored text
  - Font size ESCALATES across beats (hook → body → accent → payoff)
  - Unified dark blue palette — cohesive progression, not random colors
  - Text positioned in Instagram-safe zone (avoid bottom 20%, top 10%)
  - Strong text shadow/glow for readability on any background
  - Brand watermark outside the text danger zone

Designed for 1080×1920 (9:16 Instagram Reels).
"""

import argparse
import base64
import json
import math
import os
import random
import subprocess
import sys
from io import BytesIO
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance
except ImportError:
    print("ERROR: Pillow not installed. Run: pip3 install Pillow", file=sys.stderr)
    sys.exit(1)

# ── Constants ──────────────────────────────────────────────────────────────
W, H = 1080, 1920
# Instagram safe zone: top 10% and bottom 20% are covered by UI
SAFE_TOP = int(H * 0.12)      # ~230px
SAFE_BOTTOM = int(H * 0.78)   # ~1498px — above like/comment/share buttons
SAFE_CENTER_Y = (SAFE_TOP + SAFE_BOTTOM) // 2  # ~864px

FONT_DIR = (
    Path(__file__).resolve().parent.parent.parent.parent
    / "insta-templates" / "fonts" / "extras" / "ttf"
)
FALLBACK_FONT = "/System/Library/Fonts/Helvetica.ttc"

# ── Style presets ──────────────────────────────────────────────────────────
# ALL styles use white text. Size escalates to build visual energy.
STYLES = {
    "hook": {
        "font": "InterDisplay-Black.ttf",
        "size": 86,
        "color": (255, 255, 255, 255),
        "line_spacing": 1.12,
    },
    "body": {
        "font": "InterDisplay-Bold.ttf",
        "size": 76,
        "color": (255, 255, 255, 245),
        "line_spacing": 1.16,
    },
    "accent": {
        "font": "InterDisplay-ExtraBold.ttf",
        "size": 80,
        "color": (255, 255, 255, 255),
        "line_spacing": 1.14,
    },
    "cta": {
        "font": "InterDisplay-Black.ttf",
        "size": 92,
        "color": (255, 255, 255, 255),
        "line_spacing": 1.10,
    },
}

# ── Background palette (unified dark-blue progression) ────────────────────
# Each entry: (top_rgb, bottom_rgb, accent_rgb_for_subtle_glow)
BG_PALETTE = [
    ((8, 14, 28),   (4, 8, 18),   (0, 60, 120)),    # deep navy
    ((10, 12, 30),  (5, 6, 18),   (40, 20, 80)),     # navy → indigo
    ((6, 16, 32),   (3, 8, 16),   (0, 80, 100)),     # navy → teal hint
    ((12, 10, 26),  (6, 5, 14),   (60, 0, 90)),      # dark purple
    ((8, 8, 20),    (4, 4, 12),   (20, 40, 80)),     # near black + blue
]

# AI background prompts — all dark, all cohesive blue/indigo palette
BG_PROMPTS = [
    "Dark cinematic data center interior, server racks with subtle blue LED lights, deep shadows, volumetric fog, extremely dark moody atmosphere, color palette dark navy and black only, no text no people no logos, 9:16 portrait",
    "Abstract dark neural network visualization, faint glowing nodes and connections in deep blue tones, mostly black with subtle blue highlights, cinematic, no text no people no logos, 9:16 portrait",
    "Dark futuristic corridor with faint blue ambient light, deep shadows, minimal details, extremely dark and moody, color palette dark navy and indigo only, no text no people no logos, 9:16 portrait",
    "Abstract dark technology background, subtle circuit board patterns barely visible in deep navy blue, mostly black, cinematic depth, no text no people no logos, 9:16 portrait",
    "Dark minimalist space, subtle blue gradient from deep navy to black, abstract geometric shapes barely visible, extremely dark, no text no people no logos, 9:16 portrait",
]


def get_font(name: str, size: int) -> ImageFont.FreeTypeFont:
    font_path = FONT_DIR / name
    if font_path.exists():
        return ImageFont.truetype(str(font_path), size)
    try:
        return ImageFont.truetype(FALLBACK_FONT, size)
    except Exception:
        return ImageFont.load_default()


# ── AI Background Generation ──────────────────────────────────────────────
def generate_ai_background(
    prompt: str, api_key: str, index: int, outdir: Path
) -> "Image.Image | None":
    import urllib.request

    cache_path = outdir / f"bg_cache_{index}.png"
    if cache_path.exists():
        return Image.open(cache_path).convert("RGBA")

    try:
        url = "https://api.openai.com/v1/images/generations"
        payload = json.dumps({
            "model": "gpt-image-1",
            "prompt": prompt,
            "n": 1,
            "size": "1024x1536",
            "quality": "low",
        }).encode()

        req = urllib.request.Request(url, data=payload, headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        })

        with urllib.request.urlopen(req, timeout=60) as resp:
            data = json.loads(resp.read())

        if "data" in data and data["data"]:
            item = data["data"][0]
            if "b64_json" in item:
                raw = base64.b64decode(item["b64_json"])
                img = Image.open(BytesIO(raw)).convert("RGBA")
            elif "url" in item:
                with urllib.request.urlopen(item["url"], timeout=30) as r:
                    img = Image.open(BytesIO(r.read())).convert("RGBA")
            else:
                return None

            img = img.resize((W, H), Image.LANCZOS)
            img = _darken_for_text(img)
            img.save(cache_path, "PNG")
            return img

    except Exception as e:
        print(f"  ⚠ AI background failed: {e}", file=sys.stderr)
        return None


def _darken_for_text(img: "Image.Image") -> "Image.Image":
    """Heavy darkening + desaturation so text pops on any AI image."""
    img = ImageEnhance.Color(img).enhance(0.35)
    img = ImageEnhance.Brightness(img).enhance(0.30)
    img = ImageEnhance.Contrast(img).enhance(1.1)

    # Vignette: darken edges, especially top/bottom for IG UI zones
    vig = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vig)
    for y in range(H):
        # Stronger at top and bottom (IG UI zones)
        dist_from_center = abs(y - H / 2) / (H / 2)
        alpha = int(100 * (dist_from_center ** 1.2))
        # Extra darkening in text zone for contrast
        if SAFE_TOP < y < SAFE_BOTTOM:
            alpha = max(alpha, 60)
        vd.rectangle([(0, y), (W, y + 1)], fill=(0, 0, 0, alpha))

    return Image.alpha_composite(img, vig)


# ── Gradient Background (fallback) ────────────────────────────────────────
def generate_gradient_background(index: int, total: int) -> "Image.Image":
    """Smooth dark gradient with subtle accent glow. No banding."""
    pal = BG_PALETTE[index % len(BG_PALETTE)]
    top, bot, accent = pal

    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    pixels = img.load()

    for y in range(H):
        t = y / H
        # Smooth cubic interpolation (avoids banding)
        t_smooth = t * t * (3 - 2 * t)
        r = int(top[0] * (1 - t_smooth) + bot[0] * t_smooth)
        g = int(top[1] * (1 - t_smooth) + bot[1] * t_smooth)
        b = int(top[2] * (1 - t_smooth) + bot[2] * t_smooth)
        for x in range(W):
            pixels[x, y] = (r, g, b, 255)

    # Subtle radial accent glow near center
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    cx, cy = W // 2, SAFE_CENTER_Y
    max_r = 500
    for radius in range(max_r, 0, -4):
        alpha = int(18 * (1 - radius / max_r) ** 2)
        gd.ellipse(
            [cx - radius, cy - radius, cx + radius, cy + radius],
            fill=(*accent, alpha),
        )
    img = Image.alpha_composite(img, glow)

    # Noise/grain overlay to eliminate gradient banding on OLED screens
    random.seed(index * 7 + 13)
    noise = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    np_arr = noise.load()
    for y in range(0, H, 2):
        for x in range(0, W, 2):
            a = random.randint(2, 12)
            c = random.randint(220, 255)
            np_arr[x, y] = (c, c, c, a)
    noise = noise.filter(ImageFilter.GaussianBlur(radius=0.8))
    img = Image.alpha_composite(img, noise)

    return img


# ── Text Rendering ─────────────────────────────────────────────────────────
def render_text_on_frame(
    bg: "Image.Image",
    text: str,
    style_name: str = "body",
    beat_index: int = 0,
    total_beats: int = 4,
    brand: str = "your-brand",
) -> "Image.Image":
    """Render bold white text centered in the IG-safe zone."""
    img = bg.copy()
    style = STYLES.get(style_name, STYLES["body"])

    font = get_font(style["font"], style["size"])
    brand_font = get_font("InterDisplay-Medium.ttf", 22)

    lines = [l for l in text.split("\n") if l.strip()]
    line_height = int(style["size"] * style["line_spacing"])
    total_text_h = len(lines) * line_height

    # Center in safe zone (biased slightly above geometric center)
    start_y = SAFE_CENTER_Y - total_text_h / 2 - 30

    # ── Shadow layer (blurred for glow effect) ──
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    for i, line in enumerate(lines):
        y = start_y + i * line_height
        bbox = sd.textbbox((0, 0), line.strip(), font=font)
        tw = bbox[2] - bbox[0]
        x = (W - tw) / 2
        # Multiple shadow passes for strong backing
        for dx, dy, a in [(0, 6, 200), (0, 3, 160), (3, 3, 140)]:
            sd.text((x + dx, y + dy), line.strip(), fill=(0, 0, 0, a), font=font)

    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=5))
    img = Image.alpha_composite(img, shadow)

    # ── Main text ──
    draw = ImageDraw.Draw(img)
    for i, line in enumerate(lines):
        y = start_y + i * line_height
        bbox = draw.textbbox((0, 0), line.strip(), font=font)
        tw = bbox[2] - bbox[0]
        x = (W - tw) / 2
        draw.text((x, y), line.strip(), fill=style["color"], font=font)

    # ── Brand watermark (safely above IG bottom UI) ──
    draw.text(
        (W - 170, SAFE_BOTTOM - 30),
        brand,
        fill=(255, 255, 255, 45),
        font=brand_font,
    )

    return img


# ── Main ───────────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="Generate reel beat frames")
    parser.add_argument("--brief", required=True, help="Path to JSON brief")
    parser.add_argument("--outdir", required=True, help="Output directory")
    parser.add_argument(
        "--no-ai", action="store_true", help="Skip AI backgrounds, use gradients"
    )
    args = parser.parse_args()

    with open(args.brief) as f:
        brief = json.load(f)

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    beats = brief.get("beats", [])
    if not beats:
        print("ERROR: No beats in brief", file=sys.stderr)
        sys.exit(1)

    # Resolve OpenAI key
    api_key = os.environ.get("OPENAI_API_KEY", "")
    if not api_key:
        try:
            r = subprocess.run(
                ["security", "find-generic-password", "-s", "openai-api-key", "-a", "openai", "-w"],
                capture_output=True, text=True, timeout=5,
            )
            if r.returncode == 0:
                api_key = r.stdout.strip()
        except Exception:
            pass

    use_ai = bool(api_key) and not args.no_ai

    print(f"Generating {len(beats)} beat frames...")
    print(f"AI backgrounds: {'enabled' if use_ai else 'disabled (gradient fallback)'}")

    # Generate backgrounds (one per beat, max 5 unique)
    num_bgs = min(len(beats), 5)
    backgrounds: list["Image.Image"] = []

    for i in range(num_bgs):
        prompt = beats[i].get("bg_prompt", BG_PROMPTS[i % len(BG_PROMPTS)])
        bg = None

        if use_ai:
            print(f"  Generating AI background {i + 1}/{num_bgs}...")
            bg = generate_ai_background(prompt, api_key, i, outdir)
            if bg:
                print(f"    ✓ AI background ready")
            else:
                print(f"    ⚠ Falling back to gradient")

        if bg is None:
            print(f"  Generating gradient background {i + 1}/{num_bgs}...")
            bg = generate_gradient_background(i, num_bgs)

        backgrounds.append(bg)

    # Render beat frames
    manifest = {"frames": [], "brief": brief}

    for i, beat in enumerate(beats):
        bg = backgrounds[i % len(backgrounds)]
        text = beat.get("text", "")
        style = beat.get("style", "body")
        duration = beat.get("duration", 3)

        frame = render_text_on_frame(
            bg, text, style,
            beat_index=i, total_beats=len(beats),
        )
        path = outdir / f"beat_{i + 1:03d}.png"
        frame.convert("RGB").save(path, "PNG", optimize=True)

        manifest["frames"].append({
            "path": str(path),
            "duration": duration,
            "index": i + 1,
        })
        print(f"  ✓ beat_{i + 1:03d}.png ({duration}s) [{style}]")

    # Write manifest
    manifest_path = outdir / "manifest.json"
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)

    print(f"\n✓ {len(beats)} frames → {outdir}")


if __name__ == "__main__":
    main()
