"""Nagi アプリアイコン + メニューバーシンボル生成器

案A: 月と水平線(夜の凪)
- 深い夜空(濃紺グラデーション)
- 中央上に温かみのある月(月光ハロー付き)
- 水平線で空と水を分割
- 月の反射と細い波紋(ripple)を水面に
- メニューバー: 円(active) と 三日月(break) の outline/fill 4 種

Output:
  Nagi/Nagi/Assets.xcassets/AppIcon.appiconset/<size>.png + Contents.json
  Nagi/Nagi/Resources/Symbols/nagi.menubar.{idle,working,pendingBreak,onBreak}.svg
  Nagi/Nagi/Resources/Symbols/README.md
  Nagi-about-logo-1024.png
  Nagi-icon-preview.png   (見比べ用ピックアップ画像)
"""

from __future__ import annotations

import io
import json
import math
from pathlib import Path


import cairosvg
from PIL import Image

# パス
ROOT = Path("/sessions/youthful-beautiful-euler/mnt/Nagi/Nagi/Nagi")
APPICON = ROOT / "Assets.xcassets" / "AppIcon.appiconset"
SYMBOLS = ROOT / "Resources" / "Symbols"
PREVIEW_DIR = Path("/sessions/youthful-beautiful-euler/mnt/outputs")


# ============================================================
# アプリアイコン SVG(月+水平線)
# ============================================================

def app_icon_svg(*, mode: str = "default") -> str:
    """mode: 'default' / 'dark' / 'tinted' / 'about' """

    if mode == "tinted":
        # tinted: 中間グレー(macOS が単色化するので luminance だけ残す)
        c_sky_top, c_sky_bot = "#2a2a2a", "#5a5a5a"
        c_water_top, c_water_bot = "#3a3a3a", "#1a1a1a"
        c_moon_top, c_moon_bot = "#f5f5f5", "#cfcfcf"
        c_moon_shadow = "#1a1a1a"
        c_glow = "#ffffff"
        c_highlight = "#ffffff"
    elif mode == "dark":
        # わずかに深め
        c_sky_top, c_sky_bot = "#04081e", "#0f1f48"
        c_water_top, c_water_bot = "#0f2655", "#040d2d"
        c_moon_top, c_moon_bot = "#fff8da", "#e9d9ad"
        c_moon_shadow = "#04081e"
        c_glow = "#fff5cf"
        c_highlight = "#fffbe6"
    elif mode == "about":
        # About 用: 同じデザインで OK
        c_sky_top, c_sky_bot = "#080f2a", "#1a2c5c"
        c_water_top, c_water_bot = "#1a3a6e", "#0a1e44"
        c_moon_top, c_moon_bot = "#fffbe6", "#f0e3b8"
        c_moon_shadow = "#080f2a"
        c_glow = "#fff9d6"
        c_highlight = "#fffbe6"
    else:  # default
        c_sky_top, c_sky_bot = "#080f2a", "#1a2c5c"
        c_water_top, c_water_bot = "#1a3a6e", "#0a1e44"
        c_moon_top, c_moon_bot = "#fffbe6", "#f0e3b8"
        c_moon_shadow = "#080f2a"
        c_glow = "#fff9d6"
        c_highlight = "#fffbe6"

    # ジオメトリ
    moon_cx, moon_cy, moon_r = 520, 360, 180
    glow_r = 360
    horizon_y = 640

    # 月のシャドウ側(左)を少しだけ暗く: waxing gibbous(月の右が明るい)
    shadow_path = (
        f"M {moon_cx} {moon_cy - moon_r} "
        f"A {moon_r} {moon_r} 0 0 0 {moon_cx} {moon_cy + moon_r} "
        f"Z"
    )

    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{c_sky_top}"/>
      <stop offset="1" stop-color="{c_sky_bot}"/>
    </linearGradient>
    <linearGradient id="water" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{c_water_top}"/>
      <stop offset="1" stop-color="{c_water_bot}"/>
    </linearGradient>
    <radialGradient id="moonglow" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="{c_glow}" stop-opacity="0.55"/>
      <stop offset="0.35" stop-color="{c_glow}" stop-opacity="0.22"/>
      <stop offset="1" stop-color="{c_glow}" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="moonfill" x1="0.25" y1="0" x2="0.75" y2="1">
      <stop offset="0" stop-color="{c_moon_top}"/>
      <stop offset="1" stop-color="{c_moon_bot}"/>
    </linearGradient>
  </defs>

  <!-- 空 -->
  <rect width="1024" height="1024" fill="url(#sky)"/>

  <!-- 月光のハロー(柔らかい円形グロー) -->
  <circle cx="{moon_cx}" cy="{moon_cy}" r="{glow_r}" fill="url(#moonglow)"/>

  <!-- 月の本体(満月寄りの waxing gibbous) -->
  <circle cx="{moon_cx}" cy="{moon_cy}" r="{moon_r}" fill="url(#moonfill)"/>
  <!-- 月の左側のごく薄い陰影(月であることを示す) -->
  <path d="{shadow_path}" fill="{c_moon_shadow}" opacity="0.14"/>

  <!-- ハイライト(右肩) -->
  <ellipse cx="{moon_cx + 70}" cy="{moon_cy - 70}" rx="40" ry="22" fill="{c_highlight}" opacity="0.30"/>

  <!-- 水面 -->
  <rect x="0" y="{horizon_y}" width="1024" height="{1024 - horizon_y}" fill="url(#water)"/>

  <!-- 水平線 -->
  <line x1="0" y1="{horizon_y}" x2="1024" y2="{horizon_y}" stroke="{c_highlight}" stroke-opacity="0.22" stroke-width="2"/>

  <!-- 月光の反射(縦の柱) -->
  <ellipse cx="{moon_cx}" cy="{horizon_y + 90}"  rx="78" ry="7" fill="{c_highlight}" opacity="0.45"/>
  <ellipse cx="{moon_cx}" cy="{horizon_y + 145}" rx="58" ry="5" fill="{c_highlight}" opacity="0.28"/>
  <ellipse cx="{moon_cx}" cy="{horizon_y + 195}" rx="42" ry="4" fill="{c_highlight}" opacity="0.16"/>
  <ellipse cx="{moon_cx}" cy="{horizon_y + 240}" rx="28" ry="3" fill="{c_highlight}" opacity="0.10"/>

  <!-- 凪の波紋(横に広がる細い ellipse) -->
  <ellipse cx="512" cy="{horizon_y + 50}"  rx="220" ry="3" fill="none" stroke="{c_highlight}" stroke-opacity="0.15" stroke-width="2"/>
  <ellipse cx="512" cy="{horizon_y + 180}" rx="320" ry="3" fill="none" stroke="{c_highlight}" stroke-opacity="0.10" stroke-width="2"/>
  <ellipse cx="512" cy="{horizon_y + 310}" rx="420" ry="3" fill="none" stroke="{c_highlight}" stroke-opacity="0.06" stroke-width="2"/>
</svg>
"""


# ============================================================
# メニューバーシンボル SVG(モノクロ、currentColor)
# ============================================================
#
# Asset Catalog に Image Set として置く前提で、fill="currentColor" を使う。
# Xcode 上で .template とすれば auto-tint される。

# -----------------------------------------------------------------
# メニューバーシンボル
#
# 月/満月をメインビジュアルにし、その中央に小さい N を Nagi ブランドの
# 印として配置する:
#
#   idle         : 円(outline) + N(小、塗り)
#   working      : 円(filled)  + N(小、cutout = 透明な hole)
#   pendingBreak : 三日月(outline) + N(小、塗り、月の広い側に配置)
#   onBreak      : 三日月(filled)  + N(小、cutout、月の広い側)
#
# Filled 系は fill-rule="evenodd" の単一 path で月+N の hole を表現する。
# Outline 系は 月の outline path + N polygon path(塗り)を別々に置く。
# -----------------------------------------------------------------

# ---- N 小グリフのジオメトリ(menubar 内、view 24x24)---------------

def _small_n_subpaths(cx: float, cy: float, h: float, bar_w: float) -> str:
    """小さい N の subpath 群(複数の Z 区切り)を返す。
    cx, cy: N の中心。h: N の高さ。bar_w: バーの太さ(対角ストロークも同じ太さ)。

    N の幾何:
      - 縦バー 2 本(rect)
      - 中央の対角ストロークは parallelogram(top-right of left bar →
        bottom-left of right bar、垂直方向の厚みは bar_w 弱)
    """
    # ベース矩形寸法
    n_w = h * 0.78               # N の総幅
    left_x  = cx - n_w / 2
    right_x = cx + n_w / 2 - bar_w
    top_y   = cy - h / 2
    bot_y   = cy + h / 2

    # 左バー rect(closed subpath)
    left_bar = (
        f"M {left_x} {top_y} "
        f"L {left_x + bar_w} {top_y} "
        f"L {left_x + bar_w} {bot_y} "
        f"L {left_x} {bot_y} Z"
    )
    # 右バー rect
    right_bar = (
        f"M {right_x} {top_y} "
        f"L {right_x + bar_w} {top_y} "
        f"L {right_x + bar_w} {bot_y} "
        f"L {right_x} {bot_y} Z"
    )
    # 対角 parallelogram。上辺/下辺は同じ傾き(slope = (h - bar_w) / (right_x - (left_x+bar_w)))。
    # 4 頂点:
    #   UL = (left_x + bar_w,        top_y)              ← 左バー右上
    #   UR = (right_x,               bot_y - bar_w)      ← 右バー左の上端から bar_w 下
    #   LR = (right_x,               bot_y)              ← 右バー左下
    #   LL = (left_x + bar_w,        top_y + bar_w)      ← 左バー右の上端から bar_w 下
    diag = (
        f"M {left_x + bar_w} {top_y} "
        f"L {right_x} {bot_y - bar_w} "
        f"L {right_x} {bot_y} "
        f"L {left_x + bar_w} {top_y + bar_w} Z"
    )
    return " ".join([left_bar, right_bar, diag])


# ---- 月(円)サブパス -----------------------------------------------

def _circle_subpath(cx: float, cy: float, r: float) -> str:
    """円を path 形式で書く(複合 path に組み込めるように)。"""
    return (
        f"M {cx - r} {cy} "
        f"a {r} {r} 0 1 0 {2*r} 0 "
        f"a {r} {r} 0 1 0 {-2*r} 0 Z"
    )


# ---- 三日月サブパス(波動・前述の closed shape を再利用)-----------

def _crescent_subpath(cx: float, cy: float, r: float,
                      offset_x: float = 4.0, offset_y: float = -1.0) -> str:
    """三日月の境界線パス。外側円(cx,cy,r) から 内側カット円
    (cx+offset_x, cy+offset_y, r) を引いた形。
    交点が path の上下になる。"""
    # 内側カット円の中心
    icx = cx + offset_x
    icy = cy + offset_y
    # 中心間距離
    d = math.hypot(offset_x, offset_y)
    if d <= 0:
        d = 0.0001
    # 弦半長 a
    a = math.sqrt(max(0.0, r * r - (d / 2) ** 2))
    # 弦の中点 = 中心間ベクトルの中点
    midx = (cx + icx) / 2
    midy = (cy + icy) / 2
    # 弦方向の単位ベクトル(中心間ベクトルの 90° 回転)
    ux, uy = -offset_y / d, offset_x / d
    p1 = (midx + a * ux, midy + a * uy)
    p2 = (midx - a * ux, midy - a * uy)
    # 上下判定(y 小さい方が top)
    top, bot = (p1, p2) if p1[1] < p2[1] else (p2, p1)

    return (
        f"M {top[0]:.3f} {top[1]:.3f} "
        f"A {r} {r} 0 1 0 {bot[0]:.3f} {bot[1]:.3f} "   # 外側、長い弧
        f"A {r} {r} 0 0 1 {top[0]:.3f} {top[1]:.3f} Z"  # 内側、短い弧
    )


# ---- 4 種の SVG ----------------------------------------------------

# 月の主寸法
MOON_CX, MOON_CY, MOON_R = 12.0, 12.0, 8.5
# N グリフ(small): 高さ ~6.5、太さ 1.3(少し太め)
N_H = 6.5
N_BAR_W = 1.3

# 三日月: 左に lit 部分、右に「欠けた」凹み(cutout area)。
# N は欠けた右側の凹みに収めて、月とセットの構図にする。
CRESCENT_OFFSET_X = 5.4
CRESCENT_OFFSET_Y = -0.8
# N の位置: 三日月の右凹みのちょうど中。
CRESCENT_N_CX = 14.6
CRESCENT_N_CY = MOON_CY
CRESCENT_N_H  = 6.4
CRESCENT_N_BAR_W = 1.2


def menubar_idle_svg() -> str:
    """idle: outline の満月 + 中央に小さい N"""
    moon = (
        f'<circle cx="{MOON_CX}" cy="{MOON_CY}" r="{MOON_R}" '
        f'fill="none" stroke="currentColor" stroke-width="1.6"/>'
    )
    n = (
        f'<path d="{_small_n_subpaths(MOON_CX, MOON_CY, N_H, N_BAR_W)}" '
        f'fill="currentColor" fill-rule="nonzero"/>'
    )
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">{moon}{n}</svg>\n'


def menubar_working_svg() -> str:
    """working: 塗りの満月 - 中央に N の hole"""
    circle = _circle_subpath(MOON_CX, MOON_CY, MOON_R)
    n_holes = _small_n_subpaths(MOON_CX, MOON_CY, N_H, N_BAR_W)
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">'
        f'<path d="{circle} {n_holes}" fill="currentColor" fill-rule="evenodd"/>'
        f'</svg>\n'
    )


def menubar_pending_break_svg() -> str:
    """pendingBreak: outline の三日月 + 広い側に小さい N"""
    crescent = (
        f'<path d="{_crescent_subpath(MOON_CX, MOON_CY, MOON_R, CRESCENT_OFFSET_X, CRESCENT_OFFSET_Y)}" '
        f'fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>'
    )
    n = (
        f'<path d="{_small_n_subpaths(CRESCENT_N_CX, CRESCENT_N_CY, CRESCENT_N_H, CRESCENT_N_BAR_W)}" '
        f'fill="currentColor"/>'
    )
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">{crescent}{n}</svg>\n'


def menubar_on_break_svg() -> str:
    """onBreak: 塗りの三日月 + 右の凹みに小さい N(塗り)。
    N は三日月の負空間に置くので cutout 不要、ただ filled で描く。"""
    crescent = (
        f'<path d="{_crescent_subpath(MOON_CX, MOON_CY, MOON_R, CRESCENT_OFFSET_X, CRESCENT_OFFSET_Y)}" '
        f'fill="currentColor"/>'
    )
    n = (
        f'<path d="{_small_n_subpaths(CRESCENT_N_CX, CRESCENT_N_CY, CRESCENT_N_H, CRESCENT_N_BAR_W)}" '
        f'fill="currentColor"/>'
    )
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">{crescent}{n}</svg>\n'


# ============================================================
# レンダーパイプライン
# ============================================================

def svg_to_png(svg: str, size: int) -> bytes:
    """SVG を指定サイズの RGBA PNG にレンダー。"""
    return cairosvg.svg2png(
        bytestring=svg.encode("utf-8"),
        output_width=size,
        output_height=size,
    )


def png_to_rgb(png_bytes: bytes, bg: tuple[int, int, int] | None = None) -> Image.Image:
    """RGBA を必要なら白などで合成して RGB(24bit) にする。背景指定なしなら RGBA のまま返す。"""
    im = Image.open(io.BytesIO(png_bytes)).convert("RGBA")
    if bg is None:
        return im
    out = Image.new("RGB", im.size, bg)
    out.paste(im, mask=im.split()[3])
    return out


def render_size(svg: str, size: int) -> Image.Image:
    """size px の RGBA Image を返す(リサンプリングではなくレンダー)。"""
    png = svg_to_png(svg, size)
    return Image.open(io.BytesIO(png)).convert("RGBA")


# ============================================================
# AppIcon.appiconset 生成
# ============================================================

# Mac slot: (size_dp, scale, filename, render_px)
MAC_SLOTS = [
    (16,  "1x",  "icon_16x16.png",         16),
    (16,  "2x",  "icon_16x16@2x.png",      32),
    (32,  "1x",  "icon_32x32.png",         32),
    (32,  "2x",  "icon_32x32@2x.png",      64),
    (128, "1x",  "icon_128x128.png",       128),
    (128, "2x",  "icon_128x128@2x.png",    256),
    (256, "1x",  "icon_256x256.png",       256),
    (256, "2x",  "icon_256x256@2x.png",    512),
    (512, "1x",  "icon_512x512.png",       512),
    (512, "2x",  "icon_512x512@2x.png",    1024),
]

# iOS universal slots (luminosity)
IOS_SLOTS = [
    (None,    "icon_universal.png",          "default"),
    ("dark",  "icon_universal_dark.png",     "dark"),
    ("tinted","icon_universal_tinted.png",   "tinted"),
]


def write_app_icon() -> None:
    APPICON.mkdir(parents=True, exist_ok=True)

    # 1024 マスター 3 種をまず作る
    masters = {
        m: render_size(app_icon_svg(mode=m), 1024)
        for m in ("default", "dark", "tinted")
    }

    # Mac slot: default(light) マスターから downscale
    for dp, scale, name, px in MAC_SLOTS:
        # LANCZOS のほうが小サイズで綺麗
        if px == 1024:
            img = masters["default"]
        else:
            img = masters["default"].resize((px, px), Image.LANCZOS)
        # AppIcon は透過なし PNG(24bit) でも問題ないが Apple は RGBA も受ける
        img.convert("RGBA").save(APPICON / name, "PNG", optimize=True)
        print(f"  wrote {name} ({px}x{px})")

    # iOS slot: 1024 RGBA をそのまま
    for appearance, name, mode in IOS_SLOTS:
        masters[mode].save(APPICON / name, "PNG", optimize=True)
        print(f"  wrote {name}")

    # Contents.json を組み立て
    images = []
    # iOS universal
    images.append({
        "filename": "icon_universal.png",
        "idiom": "universal",
        "platform": "ios",
        "size": "1024x1024",
    })
    images.append({
        "appearances": [{"appearance": "luminosity", "value": "dark"}],
        "filename": "icon_universal_dark.png",
        "idiom": "universal",
        "platform": "ios",
        "size": "1024x1024",
    })
    images.append({
        "appearances": [{"appearance": "luminosity", "value": "tinted"}],
        "filename": "icon_universal_tinted.png",
        "idiom": "universal",
        "platform": "ios",
        "size": "1024x1024",
    })
    # Mac slots
    for dp, scale, name, _ in MAC_SLOTS:
        images.append({
            "filename": name,
            "idiom": "mac",
            "scale": scale,
            "size": f"{dp}x{dp}",
        })

    contents = {
        "images": images,
        "info": {"author": "xcode", "version": 1},
    }
    (APPICON / "Contents.json").write_text(
        json.dumps(contents, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"  wrote Contents.json")


# ============================================================
# メニューバーシンボル書き出し
# ============================================================

def write_menubar_symbols() -> None:
    SYMBOLS.mkdir(parents=True, exist_ok=True)

    variants = {
        "nagi.menubar.idle.svg":         menubar_idle_svg(),
        "nagi.menubar.working.svg":      menubar_working_svg(),
        "nagi.menubar.pendingBreak.svg": menubar_pending_break_svg(),
        "nagi.menubar.onBreak.svg":      menubar_on_break_svg(),
    }
    for name, svg in variants.items():
        (SYMBOLS / name).write_text(svg, encoding="utf-8")
        print(f"  wrote {name}")

    # 取り込み手順
    readme = """# Nagi メニューバーシンボル

4 枚のモノクロ SVG。Asset Catalog に Image Set または Symbol Image として
取り込み、`Image("nagi.menubar.idle")` などで参照する。

## 取り込み手順 (Xcode 15+)

### 方式 1: Image Set として (シンプル)

1. `Nagi/Nagi/Assets.xcassets` を Xcode で開く
2. Editor → New Image Set
3. Name: `nagi.menubar.idle`
4. Universal スロットに `nagi.menubar.idle.svg` をドラッグ
5. 右ペインの Render As を **Template Image** に設定 (auto-tint 有効化)
6. Single Scale にチェック (1 枚 SVG で全 scale カバー)
7. 残り 3 つも同様に追加

### 方式 2: Custom SF Symbol として (より厳密)

1. SF Symbols.app で適当な base symbol を Export → Symbol Template
2. 出力された SVG を本リポの SVG で path を上書き
3. Xcode の Assets.xcassets にドラッグドロップ
4. `Image(systemName: "nagi.menubar.idle")` で参照可能になる

## 呼び出し例

```swift
enum TimerStatus {
    case idle, working, pendingBreak, onBreak

    var menuBarSymbol: String {
        switch self {
        case .idle:         "nagi.menubar.idle"
        case .working:      "nagi.menubar.working"
        case .pendingBreak: "nagi.menubar.pendingBreak"
        case .onBreak:      "nagi.menubar.onBreak"
        }
    }
}

MenuBarExtra(label: { Image(status.menuBarSymbol) }) { ... }
```

## デザイン

メインビジュアルは **月(満月/三日月)**。その中央に Nagi のブランド印
として **小さな N** を載せる:

- idle:         outline の満月 + 中央に小さい N(塗り)
- working:      塗りの満月 + 中央に N の hole(cutout)
- pendingBreak: outline の三日月 + 月の広い側に小さい N(塗り)
- onBreak:      塗りの三日月 + 月の広い側に N の hole(cutout)

円 = active 系、三日月 = rest 系。outline = idle/pending、fill = working/onBreak。
N は cutout (hole) になるよう evenodd fill-rule で表現。
"""
    (SYMBOLS / "README.md").write_text(readme, encoding="utf-8")
    print(f"  wrote README.md")


# ============================================================
# About ロゴ + プレビュー
# ============================================================

def write_about_logo() -> None:
    """1024×1024 PNG。アプリ内 About 画面用。AppIcon と同じデザインだが
    透明背景にしたいニーズがあれば mode='about' を別途調整する。"""
    img = render_size(app_icon_svg(mode="about"), 1024)
    out = ROOT / "Resources" / "Branding"
    out.mkdir(parents=True, exist_ok=True)
    img.save(out / "Nagi-logo-1024.png", "PNG", optimize=True)
    print(f"  wrote Resources/Branding/Nagi-logo-1024.png")


def write_preview_composite() -> None:
    """ユーザーが見比べるための合成画像を outputs/ に置く。
    上半分: AppIcon (角丸 macOS 風) + Dock 風横並び。
    下半分: メニューバー 4 種を、ライトメニューバー + ダークメニューバーの両方で。"""
    from PIL import ImageDraw, ImageFont
    W, H = 1280, 800
    canvas = Image.new("RGB", (W, H), (244, 243, 248))

    try:
        font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 26)
        font_sub   = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 15)
        font_label = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 13)
    except Exception:
        font_title = font_sub = font_label = ImageFont.load_default()

    draw = ImageDraw.Draw(canvas)

    # ===== 上部: AppIcon =====
    draw.text((60, 40), "Nagi - AppIcon", fill=(20, 20, 40), font=font_title)
    draw.text((60, 76), "Option A: Moon over calm water", fill=(100, 100, 130), font=font_sub)

    icon_master = render_size(app_icon_svg(mode="default"), 512)

    # 大きいアイコン(角丸あり) と 小さい複数サイズ並び
    def rounded(im: Image.Image, radius_ratio: float = 0.225) -> Image.Image:
        from PIL import ImageDraw as ID
        sz = im.size[0]
        m = Image.new("L", im.size, 0)
        d = ID.Draw(m)
        d.rounded_rectangle((0, 0, sz, sz), radius=int(sz * radius_ratio), fill=255)
        rgba = im.convert("RGBA")
        rgba.putalpha(m)
        return rgba

    # 大きいアイコン
    big = rounded(icon_master.resize((300, 300), Image.LANCZOS))
    canvas.paste(big, (60, 120), mask=big.split()[3])

    # 中サイズ並び (Dock 風) 128, 64, 32, 16
    base_x = 410
    base_y = 290
    label_y = base_y + 150
    for i, sz in enumerate([128, 96, 64, 48, 32, 16]):
        small_master = icon_master.resize((sz, sz), Image.LANCZOS)
        small = rounded(small_master)
        # 中央寄せ
        x = base_x + i * 140
        y = base_y + (128 - sz) // 2
        canvas.paste(small, (x, y), mask=small.split()[3])
        draw.text((x + sz // 2 - 14, label_y), f"{sz}px", fill=(110, 110, 130), font=font_label)

    # 横向きセクション区切り
    draw.line([(60, 470), (W - 60, 470)], fill=(220, 218, 230), width=1)

    # ===== 下部: メニューバーシンボル =====
    draw.text((60, 500), "Menubar Symbols (auto-tint)", fill=(20, 20, 40), font=font_title)
    draw.text((60, 536), "Moon as main visual, small N inside as Nagi mark", fill=(100, 100, 130), font=font_sub)

    states = [
        ("idle",         menubar_idle_svg(),         "Waiting"),
        ("working",      menubar_working_svg(),      "Session active"),
        ("pendingBreak", menubar_pending_break_svg(),"Break suggested"),
        ("onBreak",      menubar_on_break_svg(),     "Break in progress"),
    ]

    # currentColor を black/white で描き分けるため SVG を fill 置換してレンダー
    def render_symbol(svg: str, color: str, size: int) -> Image.Image:
        replaced = svg.replace("currentColor", color)
        png = cairosvg.svg2png(bytestring=replaced.encode("utf-8"),
                               output_width=size, output_height=size)
        return Image.open(io.BytesIO(png)).convert("RGBA")

    # 4 状態をそれぞれ「ライトメニューバー(白地に黒)」と「ダークメニューバー(黒地に白)」の 2 行
    row_w = 260
    row_h = 110
    light_y = 590
    dark_y  = 690
    for i, (name, svg, desc) in enumerate(states):
        x = 60 + i * row_w

        # ライト メニューバー風 (白ピル)
        draw.rounded_rectangle((x, light_y, x + row_w - 20, light_y + row_h - 20),
                               radius=18, fill=(252, 252, 254), outline=(220, 218, 230))
        sym_l = render_symbol(svg, "#222", 56)
        canvas.paste(sym_l, (x + 24, light_y + 14), mask=sym_l.split()[3])
        draw.text((x + 96, light_y + 22), name, fill=(20, 20, 40), font=font_sub)
        draw.text((x + 96, light_y + 50), desc, fill=(110, 110, 130), font=font_label)

        # ダーク メニューバー風 (黒ピル)
        draw.rounded_rectangle((x, dark_y, x + row_w - 20, dark_y + row_h - 20),
                               radius=18, fill=(28, 30, 46))
        sym_d = render_symbol(svg, "#fff", 56)
        canvas.paste(sym_d, (x + 24, dark_y + 14), mask=sym_d.split()[3])
        draw.text((x + 96, dark_y + 22), name, fill=(240, 240, 250), font=font_sub)
        draw.text((x + 96, dark_y + 50), desc, fill=(170, 170, 200), font=font_label)

    canvas.save(PREVIEW_DIR / "Nagi-icon-preview.png", "PNG", optimize=True)
    print(f"  wrote {PREVIEW_DIR / 'Nagi-icon-preview.png'}")


# ============================================================
# main
# ============================================================

def main() -> None:
    print("== AppIcon ==")
    write_app_icon()
    print("== Menubar Symbols ==")
    write_menubar_symbols()
    print("== About Logo ==")
    write_about_logo()
    print("== Preview composite ==")
    write_preview_composite()
    print("done")


if __name__ == "__main__":
    main()
