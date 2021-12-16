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

for infile in sys.argv[1:]:
    f, e = os.path.splitext(infile)
    outfile = f + ".bin"
    try:
        src = Image.open(infile)
        pix = src.load()
        dst = open(outfile,"wb")
        i = 0
        bv = 0
        
        for y in range(src.height):
          for x in range(src.width):
            col = pix[x,y]
            bv = (bv << 1)
            if col[0] + col[1] + col[2] < 600:
                bv = bv | 1
            i += 1
            if i % 8 == 0:
                dst.write(bytes([bv & 0xff]))
                bv = 0
            

        dst.close()
        src.close()
    except IOError:
        print("cannot convert", infile)
            