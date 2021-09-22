# img2mode2.py
#
# Convert an image into a graphics mode 2 binary stream
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

TILE_SIZE  = 8

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
            xOff = x * TILE_SIZE
            yOff = y * TILE_SIZE
            for sy in range(TILE_SIZE):
              bv = 0  #byte value
              for sx in range(TILE_SIZE):
                pixelX = xOff + sx
                pixelY = yOff + sy
                col = pix[pixelX,pixelY]
                bv = (bv << 1)
                if col[0] + col[1] + col[2] < 200:
                    bv = bv | 1
              dst.write(bytes([bv & 0xff]))

        dst.close()
        src.close()
    except IOError:
        print("cannot convert", infile)
            