# hex2mon.py
#
# Convert an Intel HEX image to HBC-56 Monitor commands
#
# Copyright (c) 2022 Troy Schrapel
#
# This code is licensed under the MIT license
#
# https://github.com/visrealm/hbc-56
#
#

import os, sys


for infile in sys.argv[1:]:
    f, e = os.path.splitext(infile)
    outfile = f + ".mon"
    try:
        src = open(infile,"r")
        dst = open(outfile,"w")
        
        lines = src.readlines()

        for index, line in enumerate(lines):
            if line[7:9]=="00":
                dst.write("$"+line[3:7]+"\r")
                dst.write("w"+line[9:-3]+"\r")
        
        lmapf = open(infile+".lmap","r")
        for i,line in enumerate(list(lmapf)):
            if line[:11]=="	hbc56Main	": 
                dst.write(line[13:18]+"\re\r")
        
        dst.close()
        src.close()
        lmapf.close();
    except IOError:
        print("cannot convert", infile)
            