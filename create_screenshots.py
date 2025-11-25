#!/usr/bin/env python3
"""
Create Google Play Console screenshots from app icon
"""
from PIL import Image, ImageDraw
import os

# Input icon - using new ChatGPT image
input_icon = "C:/Users/koike/Downloads/ChatGPT Image Nov 19, 2025, 08_51_21 PM.png"
output_dir = "C:/Users/koike/Downloads"

# Ensure output directory exists
os.makedirs(output_dir, exist_ok=True)

# Load the source image
print("Loading source icon:", input_icon)
icon = Image.open(input_icon)
print(f"Source icon size: {icon.size}")

# Background color (matching app icon color)
bg_color = (168, 77, 54)  # Rusty red color from icon

def create_screenshot(name, width, height, icon_size):
    """Create a screenshot with icon centered"""
    # Create background
    screenshot = Image.new('RGB', (width, height), bg_color)

    # Resize icon
    resized_icon = icon.resize((icon_size, icon_size), Image.Resampling.LANCZOS)

    # Calculate position to center icon
    x = (width - icon_size) // 2
    y = (height - icon_size) // 2

    # Paste icon (with alpha channel if exists)
    if resized_icon.mode == 'RGBA':
        screenshot.paste(resized_icon, (x, y), resized_icon)
    else:
        screenshot.paste(resized_icon, (x, y))

    # Save
    output_path = os.path.join(output_dir, name)
    screenshot.save(output_path, "PNG", optimize=True)
    print(f"  [OK] Created {name} ({width}x{height})")
    return output_path

print("\n=== Creating Phone Screenshots (16:9 portrait) ===")
# Phone screenshots - 1080x1920 (9:16 portrait)
for i in range(1, 3):
    create_screenshot(
        f"indira_phone_screenshot_{i}.png",
        1080, 1920, 800
    )

print("\n=== Creating 7-inch Tablet Screenshots (16:9 portrait) ===")
# 7-inch tablet screenshots - 1200x1920
for i in range(1, 3):
    create_screenshot(
        f"indira_7inch_tablet_screenshot_{i}.png",
        1200, 1920, 900
    )

print("\n=== Creating 10-inch Tablet Screenshots (16:9 portrait) ===")
# 10-inch tablet screenshots - 1536x2048
for i in range(1, 3):
    create_screenshot(
        f"indira_10inch_tablet_screenshot_{i}.png",
        1536, 2048, 1200
    )

print("\n" + "="*60)
print("SUCCESS! All screenshots created")
print("="*60)
print(f"\nLocation: {output_dir}/")
print("\nFiles created:")
print("  PHONE (2 screenshots):")
print("    - indira_phone_screenshot_1.png")
print("    - indira_phone_screenshot_2.png")
print("\n  7-INCH TABLET (2 screenshots):")
print("    - indira_7inch_tablet_screenshot_1.png")
print("    - indira_7inch_tablet_screenshot_2.png")
print("\n  10-INCH TABLET (2 screenshots):")
print("    - indira_10inch_tablet_screenshot_1.png")
print("    - indira_10inch_tablet_screenshot_2.png")
print("\n" + "="*60)
print("UPLOAD INSTRUCTIONS:")
print("="*60)
print("\n1. Go to Play Console > Store Listing")
print("2. Upload Phone screenshots to 'Phone screenshots' section")
print("3. Upload Tablet screenshots to respective tablet sections")
print("\nNote: You can create more screenshots (up to 8 each) by")
print("taking actual app screenshots from your device!")
print("="*60)
