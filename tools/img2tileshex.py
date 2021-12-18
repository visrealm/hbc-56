# img2strip.py
#
# Convert an image into a binary stream
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

TILE_SIZE_X  = 8
TILE_SIZE_Y  = 8

for infile in sys.argv[1:]:
    f, e = os.path.splitext(infile)
    outfile = f + ".hex"
    try:
        src = Image.open(infile)
        pix = src.load()
        dst = open(outfile,"wb")
        
        inTilesX = int(src.width / TILE_SIZE_X)
        inTilesY = int(src.height / TILE_SIZE_Y)
        numInTiles = inTilesX * inTilesY

        for x in range(inTilesX):
          for y in range(inTilesY):
            xOff = x * TILE_SIZE_X
            yOff = y * TILE_SIZE_Y
            for sy in range(TILE_SIZE_Y):
              bv = 0  #byte value
              for sx in range(TILE_SIZE_X):
                pixelX = xOff + sx
                pixelY = yOff + sy
                col = pix[pixelX,pixelY]
                bv = (bv << 1)
                if col[0] + col[1] + col[2] < 400:
                    bv = bv | 1
              dst.write((hex(bv & 0xff)+",").encode('ascii'))
            dst.write("\n".encode('ascii'))

        dst.close()
        src.close()
    except IOError:
        print("cannot convert", infile)
            