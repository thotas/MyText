#!/usr/bin/env python3
"""
Generate a high-quality macOS app icon for MyText.
Creates an Apple-style icon similar to the News app icon.
"""

import os
from PIL import Image, ImageDraw

# Icon sizes needed for macOS app icons (in pixels)
SIZES = [
    (16, 16),
    (32, 32),
    (64, 64),
    (128, 128),
    (256, 256),
    (512, 512),
    (1024, 1024),
]

def create_squircle(size):
    """Create a squircle mask for the icon."""
    # For very small sizes, just return a simple rounded rectangle
    if size <= 32:
        return None

    # Create a mask for the squircle shape
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)

    # Calculate corner radius (Apple uses approximately 22% of size for icons)
    radius = int(size * 0.22)

    # Draw a rounded rectangle
    draw.rounded_rectangle(
        [(0, 0), (size - 1, size - 1)],
        radius=radius,
        fill=255
    )

    return mask


def create_icon(size, scale=1):
    """Create a single icon at the given size."""
    actual_size = size * scale

    # Create the base image with a gradient-like solid color
    # Using a rich blue-purple gradient that Apple often uses
    img = Image.new('RGBA', (actual_size, actual_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Apple News app style: rich gradient from purple to blue
    # We'll create a pseudo-gradient using color blocks
    center_x = actual_size // 2
    center_y = actual_size // 2

    # Create a gradient effect by drawing overlapping circles with varying colors
    for i in range(10, 0, -1):
        radius = int(actual_size * 0.9 * (i / 10))
        color_val = int(255 * (1 - i/20))

        # Purple to blue gradient
        if i <= 5:
            # Purple tones
            r = 139
            g = 92
            b = 246
        else:
            # Blue tones
            r = 59
            g = 130
            b = 246

        # Draw filled circle
        draw.ellipse(
            [
                center_x - radius,
                center_y - radius,
                center_x + radius,
                center_y + radius
            ],
            fill=(r, g, b, 255)
        )

    # Add a subtle highlight at the top for that Apple 3D effect
    highlight_radius = int(actual_size * 0.35)
    highlight_y = int(actual_size * 0.3)
    for i in range(5):
        r = max(1, highlight_radius - i * 3)
        alpha = 30 - i * 5
        draw.ellipse(
            [
                max(0, center_x - r),
                max(0, highlight_y - r),
                min(actual_size, center_x + r),
                min(actual_size, highlight_y + r)
            ],
            fill=(255, 255, 255, alpha)
        )

    # Add document/text symbol in white
    # Calculate document dimensions
    doc_left = int(actual_size * 0.25)
    doc_right = int(actual_size * 0.75)
    doc_top = int(actual_size * 0.2)
    doc_bottom = int(actual_size * 0.8)
    doc_width = doc_right - doc_left
    doc_height = doc_bottom - doc_top

    # Draw document background (white with slight transparency)
    corner_radius = int(doc_width * 0.1)
    draw.rounded_rectangle(
        [doc_left, doc_top, doc_right, doc_bottom],
        radius=corner_radius,
        fill=(255, 255, 255, 240)
    )

    # Draw "M" letter for MyText
    # Simple M shape using lines
    line_width = max(2, int(actual_size * 0.04))
    m_left = int(actual_size * 0.32)
    m_right = int(actual_size * 0.68)
    m_top = int(actual_size * 0.35)
    m_bottom = int(actual_size * 0.65)
    m_height = m_bottom - m_top

    # Draw M shape - left vertical
    draw.line(
        [(m_left, m_top), (m_left, m_bottom)],
        fill=(139, 92, 246),  # Purple
        width=line_width
    )

    # Draw M shape - right vertical
    draw.line(
        [(m_right, m_top), (m_right, m_bottom)],
        fill=(139, 92, 246),  # Purple
        width=line_width
    )

    # Draw M shape - left diagonal
    mid_x = (m_left + m_right) // 2
    draw.line(
        [(m_left, m_top), (mid_x, m_top + m_height // 2)],
        fill=(139, 92, 246),  # Purple
        width=line_width
    )

    # Draw M shape - right diagonal
    draw.line(
        [(mid_x, m_top + m_height // 2), (m_right, m_top)],
        fill=(139, 92, 246),  # Purple
        width=line_width
    )

    # Draw lines representing text below the M
    line_y_start = int(actual_size * 0.7)
    line_y_end = int(actual_size * 0.75)
    line_spacing = int(actual_size * 0.06)

    for line_idx in range(3):
        y = line_y_start + line_idx * line_spacing
        if y < doc_bottom - int(actual_size * 0.05):
            # Vary line lengths for visual interest
            if line_idx == 0:
                line_start = int(actual_size * 0.32)
                line_end = int(actual_size * 0.68)
            elif line_idx == 1:
                line_start = int(actual_size * 0.35)
                line_end = int(actual_size * 0.65)
            else:
                line_start = int(actual_size * 0.38)
                line_end = int(actual_size * 0.55)

            draw.line(
                [(line_start, y), (line_end, y)],
                fill=(156, 163, 175),  # Gray
                width=max(1, line_width // 2)
            )

    # Apply squircle mask for sizes > 32
    if size > 32:
        mask = create_squircle(actual_size)
        if mask:
            # Ensure mask matches image size
            if mask.size != img.size:
                mask = mask.resize(img.size, Image.LANCZOS)
            # Apply mask
            img.putalpha(mask)

    return img


def main():
    # Output directory
    output_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'Resources', 'Assets.xcassets', 'AppIcon.appiconset')

    print(f"Generating app icons in: {output_dir}")

    # Generate icons at different sizes
    for size in SIZES:
        base_size = size[0]
        print(f"  Creating {base_size}x{base_size} icon...")

        # Create 1x and 2x versions
        for scale in [1, 2]:
            img = create_icon(base_size, scale)

            filename = f"icon_{base_size}x{base_size}"
            if scale == 2:
                filename += "@2x"
            filename += ".png"

            filepath = os.path.join(output_dir, filename)
            img.save(filepath, 'PNG')
            print(f"    Saved: {filename}")

    print("Done!")


if __name__ == '__main__':
    main()
