# img2strip.py
#
# Convert an image into a multicolor mode binary stream
#
# Copyright (c) 2021 Troy Schrapel
#
# This code is licensed under the MIT license
#
# https://github.com/visrealm/hbc-56
#
#

import os, sys, csv
from PIL import Image

TILE_SIZE  = 2

data = []
data.extend(range(2048))

for infile in sys.argv[1:]:
    f, e = os.path.splitext(infile)
    outfile = f + ".bin"
    try:
        src = Image.open(infile)
        pix = src.load()
        dst = open(outfile,"wb")
        
        inTilesX = int(src.width / TILE_SIZE)
        inTilesY = int(src.height / TILE_SIZE)
        numInTiles = inTilesX * inTilesY

        for y in range(inTilesY):
          for x in range(inTilesX):
            tile = (x + ((y & 0xfc) << 3)) * 8

            pixelX = x * TILE_SIZE
            pixelY = y * TILE_SIZE
            col = (pix[pixelX, pixelY] << 4) | pix[pixelX + 1, pixelY]

            index = tile + (y & 0x03) * 2

            data[index] = col

            col = (pix[pixelX, pixelY + 1] << 4) | pix[pixelX + 1, pixelY + 1]
            data[index + 1] = col

        for d in data:
            dst.write(bytes([d & 0xff]))

        dst.close()
        src.close()
    except IOError:
        print("cannot convert", infile)
            