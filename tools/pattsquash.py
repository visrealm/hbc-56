# pattsquash.py
#
# Attempt to find duplicate patterns and produce a new pattern and index file
#
# Copyright (c) 2021 Troy Schrapel
#
# This code is licensed under the MIT license
#
# https://github.com/visrealm/hbc-56
#
#

import os, sys, csv, struct

#valDict = {0xfffffffffcf8f0f0:248,0xffffff0000000000:249,0xffffffff3f1f0f0f:250,0xe0e0e0e0e0e0e0e0:251,0x0707070707070707:252,0x0f0f1f3fffffffff:253,0x0000000000ffffff:254,0xf0f0f8fcffffffff:255}
                    
valDict = {}

IND_OFFSET = 0

for infile in sys.argv[1:]:
    f, e = os.path.splitext(infile)
    try:
        pattIn = open(infile, "rb")
        pattOut = open(f + ".patt","wb")
        indOut = open(f + ".ind","wb")
        indSize = 0
        pattSaved = 0

        print("Processing:    ", infile)
        
        index = IND_OFFSET
        ul = pattIn.read(8)
        while ul:
            val = struct.unpack('Q', ul)[0]
            if val in valDict:
                indOut.write(bytes([valDict[val] & 0xff]))
                pattSaved += 1
                indSize += 1
            else:
                valDict[val] = index
                indOut.write(bytes([index & 0xff]))
                pattOut.write(struct.pack('Q', val))
                index += 1
                indSize += 1
            ul = pattIn.read(8)

        pattIn.close()
        pattOut.close()
        indOut.close()
        
        print("Index size:    ", os.path.getsize(f + ".ind"),"bytes")
        print("Patterns size: ", os.path.getsize(f + ".patt"),"bytes")
        print("Total size:    ", os.path.getsize(f + ".patt")+os.path.getsize(f + ".ind"),"bytes")
        print("Total patterns:", int(os.path.getsize(f + ".patt")/8))
        print("Patterns saved:", pattSaved,"=",pattSaved*8,"bytes")
        print("Created files: ", f + ".patt", f + ".ind")
        
    except IOError:
        print("cannot convert", infile)
            