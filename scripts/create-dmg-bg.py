#!/usr/bin/env python3
"""Generate a DMG background image with an arrow between app and Applications."""
import subprocess
import struct
import zlib
import os

WIDTH = 660
HEIGHT = 400
OUTPUT = os.path.join(os.path.dirname(__file__), "..", "build", "dmg-background.png")
os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)

# Create a simple PNG with a light gray background and a dark arrow
def create_png(width, height, filepath):
    def make_pixel_data():
        rows = []
        for y in range(height):
            row = b""
            for x in range(width):
                # Light background
                r, g, b, a = 245, 245, 247, 255

                # Draw arrow in center (pointing right)
                cx, cy = width // 2, height // 2 - 10
                # Arrow shaft
                if cy - 3 <= y <= cy + 3 and cx - 30 <= x <= cx + 20:
                    r, g, b = 160, 160, 165
                # Arrow head
                dx = x - (cx + 20)
                dy = abs(y - cy)
                if 0 <= dx <= 20 and dy <= (20 - dx):
                    r, g, b = 160, 160, 165

                row += struct.pack("BBBB", r, g, b, a)
            rows.append(b"\x00" + row)  # filter byte
        return b"".join(rows)

    pixel_data = make_pixel_data()

    def make_chunk(chunk_type, data):
        chunk = chunk_type + data
        return struct.pack(">I", len(data)) + chunk + struct.pack(">I", zlib.crc32(chunk) & 0xFFFFFFFF)

    # PNG signature
    sig = b"\x89PNG\r\n\x1a\n"

    # IHDR
    ihdr_data = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    ihdr = make_chunk(b"IHDR", ihdr_data)

    # IDAT
    compressed = zlib.compress(pixel_data)
    idat = make_chunk(b"IDAT", compressed)

    # IEND
    iend = make_chunk(b"IEND", b"")

    with open(filepath, "wb") as f:
        f.write(sig + ihdr + idat + iend)

create_png(WIDTH * 2, HEIGHT * 2, OUTPUT)  # @2x for retina
print(f"Created: {OUTPUT}")
