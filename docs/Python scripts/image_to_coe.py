#!/home/fafaaa/vsc_venv/bin/python3
"""
image_to_coe.py

Converts an image into a Xilinx .coe memory-initialization file storing
RGB565 pixel data, suitable for preloading the img_src ROM via Core Generator.

Usage:
    python3 image_to_coe.py input.jpg output.coe 8
"""

import argparse
from PIL import Image


def rgb888_to_rgb565(r, g, b):
    """Pack 8-bit R/G/B into a single 16-bit RGB565 value."""
    r5 = (r >> 3) & 0x1F   # top 5 bits of red
    g6 = (g >> 2) & 0x3F   # top 6 bits of green
    b5 = (b >> 3) & 0x1F   # top 5 bits of blue
    return (r5 << 11) | (g6 << 5) | b5


def convert(input_path, output_path, width, height, radix=16):
    img = Image.open(input_path).convert("RGB")
    img = img.resize((width, height), Image.LANCZOS)

    pixels = []
    for y in range(height):
        for x in range(width):
            r, g, b = img.getpixel((x, y))
            pixels.append(rgb888_to_rgb565(r, g, b))

    with open(output_path, "w") as f:
        f.write("memory_initialization_radix=%d;\n" % radix)
        f.write("memory_initialization_vector=\n")
        lines = []
        for i, px in enumerate(pixels):
            if radix == 16:
                token = format(px, "04X")
            else:  # binary
                token = format(px, "016b")
            lines.append(token)
        f.write(",\n".join(lines))
        f.write(";\n")

    print(f"Wrote {len(pixels)} pixels ({width}x{height}) to {output_path}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("input", help="source image file (jpg/png/etc.)")
    ap.add_argument("output", help="output .coe file path")
    ap.add_argument("--width", type=int, default=80)
    ap.add_argument("--height", type=int, default=60)
    ap.add_argument("--radix", type=int, choices=[2, 16], default=16)
    args = ap.parse_args()

    convert(args.input, args.output, args.width, args.height, args.radix)
