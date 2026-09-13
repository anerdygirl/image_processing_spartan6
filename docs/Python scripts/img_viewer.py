#!/home/fafaaa/vsc_venv/bin/python3
"""
img_viewer.py

Reads one frame from the Nexys 3 over UART, reconstructs it into an image,
and displays it with matplotlib.

Protocol (matches tx.vhd):
    START_MARKER (1 byte, 0xAA)
    WIDTH_HI, WIDTH_LO   (2 bytes, big-endian)
    HEIGHT_HI, HEIGHT_LO (2 bytes, big-endian)
    pixel[0].HI, pixel[0].LO, pixel[1].HI, pixel[1].LO, ... (2 bytes per pixel,
        raster order: left-to-right, top-to-bottom)
    END_MARKER (1 byte, 0x55)

Usage:
    python3 img_viewer.py --port /dev/ttyUSB0 --mode grayscale
    python3 img_viewer.py --port COM3 --mode passthrough
"""

import argparse
import sys
import numpy as np
import serial
import matplotlib
matplotlib.use('TkAgg')  # Prevents FigureCanvasAgg GUI display warning
import matplotlib.pyplot as plt

START_MARKER = 0xAA
END_MARKER   = 0x55
BAUD_RATE    = 115200

WIDTH  = 80
HEIGHT = 60

def read_exact(ser, n):
    """Utility to safely read n bytes from serial without dropping data."""
    data = bytearray()
    while len(data) < n:
        chunk = ser.read(n - len(data))
        if not chunk:
            raise TimeoutError(f"Expected {n} bytes, got {len(data)} (timeout or disconnect)")
        data.extend(chunk)
    return bytes(data)

def receive_frame(port, mode):
    ser = serial.Serial(port, BAUD_RATE, timeout=15)

    try:
        ser.reset_input_buffer()

        # 1. Synchronize to 0xAA Start Marker
        while True:
            b = read_exact(ser, 1)[0]
            if b == START_MARKER:
                break

        # 2. Read 16-bit payload (80x60 x 2 bytes = 9,600 bytes)
        expected_bytes = WIDTH * HEIGHT * 2
        raw = read_exact(ser, expected_bytes)

        # 3. Combine high/low bytes into 16-bit values
        pixels = np.frombuffer(raw, dtype=np.uint8).reshape(WIDTH * HEIGHT, 2)
        val16 = (pixels[:, 0].astype(np.uint16) << 8) | pixels[:, 1]
        val16 = val16.reshape(HEIGHT, WIDTH)

        # 4. Mode-based post-processing
        if mode == "passthrough":
            # Extract RGB565 channels
            r5 = (val16 >> 11) & 0x1F
            g6 = (val16 >> 5) & 0x3F
            b5 = val16 & 0x1F

            r = (r5 << 3) | (r5 >> 2)
            g = (g6 << 2) | (g6 >> 4)
            b = (b5 << 3) | (b5 >> 2)

            img = np.stack([r, g, b], axis=-1).astype(np.uint8)
        else:
            # Grayscale, Sobel, and Median modes:
            # Extract upper 8 bits calculated by VHDL
            gray8 = (val16 >> 8).astype(np.uint8)
            img = np.stack([gray8, gray8, gray8], axis=-1)

        return img, mode

    finally:
        ser.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="FPGA Frame Grabber")
    parser.add_argument("--port", required=True, help="Serial port (e.g. /dev/ttyUSB0)")
    parser.add_argument("--mode", default="passthrough", choices=["passthrough", "grayscale", "sobel", "median"])
    args = parser.parse_args()

    img, current_mode = receive_frame(args.port, args.mode)

    plt.figure()
    plt.imshow(img)
    plt.title(f"Received frame ({current_mode})")
    plt.axis("off")
    plt.show()