#!/usr/bin/env python3
"""Generate App Icon: Growth Coin design for Personal Finance app."""

from PIL import Image, ImageDraw, ImageFont
import math
import os

SIZE = 1024
CENTER = SIZE // 2
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "personal_finance", "Assets.xcassets", "AppIcon.appiconset")

# Use SF Rounded for the $ symbol
FONT_PATH = "/System/Library/Fonts/SFNSRounded.ttf"


def hex_to_rgb(hex_color):
    h = hex_color.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))


def create_gradient(size, color1, color2):
    """Create a diagonal linear gradient from top-left to bottom-right."""
    img = Image.new("RGBA", (size, size))
    pixels = img.load()
    c1 = hex_to_rgb(color1)
    c2 = hex_to_rgb(color2)
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size)
            r = int(c1[0] + (c2[0] - c1[0]) * t)
            g = int(c1[1] + (c2[1] - c1[1]) * t)
            b = int(c1[2] + (c2[2] - c1[2]) * t)
            pixels[x, y] = (r, g, b, 255)
    return img


def draw_coin_ring(draw, center, radius, stroke_width, color):
    """Draw a circle ring (outline only)."""
    bbox = [
        center - radius, center - radius,
        center + radius, center + radius
    ]
    draw.ellipse(bbox, outline=color, width=stroke_width)


def draw_dollar_with_font(img, center_x, center_y, font_size, color):
    """Draw $ using SF Rounded font, centered."""
    draw = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype(FONT_PATH, font_size)
    except Exception:
        # Fallback
        font = ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", font_size)

    text = "$"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    x = center_x - text_w // 2 - bbox[0]
    y = center_y - text_h // 2 - bbox[1]
    draw.text((x, y), text, fill=color, font=font)


def draw_leaf(img, base_x, base_y, leaf_len, leaf_angle_deg, color):
    """Draw a clean, minimal leaf from base point at given angle."""
    draw = ImageDraw.Draw(img)
    angle = math.radians(leaf_angle_deg)

    # Tip of the leaf
    tip_x = base_x + leaf_len * math.cos(angle)
    tip_y = base_y - leaf_len * math.sin(angle)

    # Build leaf shape via polygon
    points = []
    num_points = 80

    for i in range(num_points + 1):
        t = i / num_points

        cx = base_x + t * (tip_x - base_x)
        cy = base_y + t * (tip_y - base_y)

        # Width: tapers at both ends, fuller near 35%
        width = leaf_len * 0.30 * math.sin(t * math.pi) * (1 - 0.25 * t)

        perp_x = -math.sin(angle)
        perp_y = -math.cos(angle)

        points.append((cx + width * perp_x, cy + width * perp_y))

    # Return path (other side)
    for i in range(num_points, -1, -1):
        t = i / num_points
        cx = base_x + t * (tip_x - base_x)
        cy = base_y + t * (tip_y - base_y)
        width = leaf_len * 0.30 * math.sin(t * math.pi) * (1 - 0.25 * t)
        perp_x = -math.sin(angle)
        perp_y = -math.cos(angle)
        points.append((cx - width * perp_x, cy - width * perp_y))

    draw.polygon(points, fill=color)


def generate_light_icon():
    """Generate the default (light) app icon."""
    img = create_gradient(SIZE, "#8BC34A", "#2E7D32")
    draw = ImageDraw.Draw(img)

    white = (255, 255, 255, 255)
    white_subtle = (255, 255, 255, 70)

    # Draw coin ring
    draw_coin_ring(draw, CENTER, 300, 36, white)

    # Draw inner subtle ring
    draw_coin_ring(draw, CENTER, 262, 3, white_subtle)

    # Draw $ sign with font
    draw_dollar_with_font(img, CENTER, CENTER + 8, 420, white)

    # Draw leaf growing from top of $ bar, angled up-right
    leaf_base_x = CENTER + 15
    leaf_base_y = CENTER - 180
    draw_leaf(img, leaf_base_x, leaf_base_y, 200, 52, white)

    return img


def generate_dark_icon():
    """Generate the dark mode app icon."""
    bg_color = hex_to_rgb("#1B5E20")
    img = Image.new("RGBA", (SIZE, SIZE), (*bg_color, 255))
    draw = ImageDraw.Draw(img)

    green = (139, 195, 74, 255)  # #8BC34A
    green_subtle = (139, 195, 74, 70)

    # Draw coin ring
    draw_coin_ring(draw, CENTER, 300, 36, green)

    # Inner subtle ring
    draw_coin_ring(draw, CENTER, 262, 3, green_subtle)

    # Draw $ sign
    draw_dollar_with_font(img, CENTER, CENTER + 8, 420, green)

    # Draw leaf
    leaf_base_x = CENTER + 15
    leaf_base_y = CENTER - 180
    draw_leaf(img, leaf_base_x, leaf_base_y, 200, 52, green)

    return img


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print("Generating light icon...")
    light = generate_light_icon()
    light_path = os.path.join(OUTPUT_DIR, "icon_light.png")
    light.save(light_path, "PNG")
    print(f"  Saved: {light_path}")

    print("Generating dark icon...")
    dark = generate_dark_icon()
    dark_path = os.path.join(OUTPUT_DIR, "icon_dark.png")
    dark.save(dark_path, "PNG")
    print(f"  Saved: {dark_path}")

    # Update Contents.json
    import json
    contents = {
        "images": [
            {
                "filename": "icon_light.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024"
            },
            {
                "appearances": [
                    {
                        "appearance": "luminosity",
                        "value": "dark"
                    }
                ],
                "filename": "icon_dark.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024"
            },
            {
                "appearances": [
                    {
                        "appearance": "luminosity",
                        "value": "tinted"
                    }
                ],
                "filename": "icon_light.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    contents_path = os.path.join(OUTPUT_DIR, "Contents.json")
    with open(contents_path, "w") as f:
        json.dump(contents, f, indent=2)
    print(f"  Updated: {contents_path}")
    print("\nDone!")


if __name__ == "__main__":
    main()
