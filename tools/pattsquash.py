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

valDict = {}

IND_OFFSET = 200

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
            #print(val)
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
        
        print("Index size:    ", indSize)
        print("Patterns saved:", pattSaved,"=",pattSaved*8,"bytes")
        print("Total size:    ", os.path.getsize(f + ".patt")+os.path.getsize(f + ".ind"),"bytes")
        print("Created files: ", f + ".patt", f + ".ind")
        
    except IOError:
        print("cannot convert", infile)
            