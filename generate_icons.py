#!/usr/bin/env python3
"""
Generate all required app icon sizes for Google Play Console
"""
from PIL import Image
import os

# Input icon
input_icon = "assets/icons/app_icon.png"
output_dir = "C:/Users/koike/Downloads"

# Ensure output directory exists
os.makedirs(output_dir, exist_ok=True)

# Load the source image
print(f"Loading source icon: {input_icon}")
source = Image.open(input_icon)
print(f"Source image size: {source.size}")

# Google Play Console required sizes
sizes = {
    # REQUIRED for Google Play Store
    "indira_app_icon_512x512.png": 512,

    # Android launcher icons
    "indira_app_icon_48x48_mdpi.png": 48,
    "indira_app_icon_72x72_hdpi.png": 72,
    "indira_app_icon_96x96_xhdpi.png": 96,
    "indira_app_icon_144x144_xxhdpi.png": 144,
    "indira_app_icon_192x192_xxxhdpi.png": 192,

    # High-res for iOS and other stores
    "indira_app_icon_1024x1024.png": 1024,
}

print("\nGenerating icon sizes:")
for filename, size in sizes.items():
    output_path = os.path.join(output_dir, filename)

    # Resize with high-quality resampling
    resized = source.resize((size, size), Image.Resampling.LANCZOS)

    # Save as PNG
    resized.save(output_path, "PNG", optimize=True)
    print(f"  [OK] Created {filename} ({size}x{size})")

print(f"\n[SUCCESS] All icons generated in '{output_dir}/' directory")
print("\nFiles created:")
for filename in sorted(sizes.keys()):
    print(f"  - {filename}")

print("\n" + "="*60)
print("GOOGLE PLAY CONSOLE UPLOAD INSTRUCTIONS:")
print("="*60)
print("\n[REQUIRED] Upload this file to Play Console:")
print("  >> indira_app_icon_512x512.png <<")
print("\nLocation: C:/Users/koike/Downloads/")
print("\nHow to upload:")
print("  1. Go to Play Console > Your App > Store Listing")
print("  2. Scroll to 'App icon' section")
print("  3. Click 'Upload' and select: indira_app_icon_512x512.png")
print("\n" + "="*60)
