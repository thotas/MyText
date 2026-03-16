#!/usr/bin/env python3
"""
Generate high-resolution macOS app icon for MyText.
Creates Apple-style icon with a modern text editor aesthetic.
"""

import os
import math
from PIL import Image, ImageDraw

def create_icon(size):
    """Create a single icon at the specified size."""
    # Create image with RGBA
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Apple-style rounded rectangle parameters
    corner_radius = int(size * 0.22)  # Apple uses ~22% corner radius

    # Gradient background - deep blue/purple like Apple's news app
    # Base color: deep indigo
    base_color = (45, 45, 80)  # #2D2D50
    # Lighter top-right for gradient
    light_color = (70, 70, 120)  # #464678

    # Draw base rounded rectangle
    draw.rounded_rectangle(
        [0, 0, size - 1, size - 1],
        radius=corner_radius,
        fill=base_color
    )

    # Add gradient overlay (lighter at top)
    gradient_height = int(size * 0.6)
    for i in range(gradient_height):
        alpha = int(60 * (1 - i / gradient_height))
        y = i
        draw.rectangle(
            [corner_radius, y, size - corner_radius - 1, y + 1],
            fill=(light_color[0], light_color[1], light_color[2], alpha)
        )

    # Add a subtle inner highlight at top
    highlight_height = int(size * 0.08)
    for i in range(highlight_height):
        alpha = int(40 * (1 - i / highlight_height))
        draw.rectangle(
            [corner_radius, i, size - corner_radius, i + 1],
            fill=(255, 255, 255, alpha)
        )

    # Draw stylized document icon
    # Outer document shape
    doc_left = int(size * 0.25)
    doc_top = int(size * 0.2)
    doc_right = int(size * 0.75)
    doc_bottom = int(size * 0.8)

    # Document background (lighter)
    doc_color = (255, 255, 255, 235)
    draw.rounded_rectangle(
        [doc_left, doc_top, doc_right, doc_bottom],
        radius=int(size * 0.06),
        fill=doc_color
    )

    # Draw lines representing text
    line_color = (45, 45, 80, 200)  # Match background color
    line_height = max(2, int(size * 0.055))
    line_spacing = max(3, int(size * 0.085))
    line_margin = int(size * 0.12)
    start_y = doc_top + int(size * 0.15)

    # Various line lengths to look like code/text
    line_configs = [
        (line_margin, 0.7),   # Short
        (line_margin, 0.9),   # Long
        (line_margin, 0.5),   # Short
        (line_margin, 0.8),   # Medium
        (line_margin, 0.6),   # Medium
        (line_margin, 0.85),  # Long
    ]

    for i, (margin, length_ratio) in enumerate(line_configs):
        y = start_y + i * line_spacing
        if y + line_height > doc_bottom - int(size * 0.1):
            break
        x1 = doc_left + margin
        x2 = doc_left + margin + int((doc_right - doc_left - 2 * margin) * length_ratio)
        if x2 > x1:
            draw.rounded_rectangle(
                [x1, y, x2, y + line_height],
                radius=max(1, int(line_height / 3)),
                fill=line_color
            )

    # Add a small "edit" indicator - a small colored dot
    dot_size = max(2, int(size * 0.07))
    dot_x = doc_right - int(size * 0.12)
    dot_y = doc_bottom - int(size * 0.1)
    draw.ellipse(
        [dot_x - dot_size//2, dot_y - dot_size//2,
         dot_x + dot_size//2, dot_y + dot_size//2],
        fill=(100, 150, 255, 255)  # Apple blue
    )

    return img

def create_icon_set(output_dir):
    """Create all required icon sizes."""
    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png"),
    ]

    os.makedirs(output_dir, exist_ok=True)

    for size, filename in sizes:
        icon = create_icon(size)
        filepath = os.path.join(output_dir, filename)
        icon.save(filepath, "PNG")
        print(f"Created: {filename} ({size}x{size})")

if __name__ == "__main__":
    # Get the directory where this script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.join(script_dir, "Resources", "Assets.xcassets", "AppIcon.appiconset")

    print("Generating MyText app icons...")
    create_icon_set(output_dir)
    print("\nIcon generation complete!")
