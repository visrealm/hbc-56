# raw2cpm.py
#
# Convert raw audio to PCM data for the AY-3-8910
#
# Copyright (c) 2023 Troy Schrapel
#
# This code is licensed under the MIT license
#
# https://github.com/visrealm/hbc-56
#
#

import os, sys

            
def convertSample(s):    
    if s > 0.8535: return 0xF
    if s > 0.6035: return 0xE
    if s > 0.4015: return 0xD
    if s > 0.2765: return 0xC
    if s > 0.20075: return 0xB
    if s > 0.13825: return 0xA
    if s > 0.1029: return 0x9
    if s > 0.07165: return 0x8
    if s > 0.05145: return 0x7
    if s > 0.035825: return 0x6
    if s > 0.025725: return 0x5
    if s > 0.0179125: return 0x4
    if s > 0.0128625: return 0x3
    if s > 0.00895625: return 0x2
    if s > 0.00640625: return 0x1
    return 0x0


for infile in sys.argv[1:]:
    f, e = os.path.splitext(infile)
    try:
        rawIn = open(infile, "rb")
        pcmOut = open(f + ".pcm","wb")
        
        minVal = 255
        maxVal = 0

        sample = rawIn.read(1)
        while sample:
            sample = float(int.from_bytes(sample))
            if sample < minVal: minVal = sample
            if sample > maxVal: maxVal = sample
            sample = rawIn.read(1)
        rawIn.seek(0)
        
        multiplier = 255.0/(maxVal-minVal)

        print("Range:    ", minVal,"-",maxVal)

        print("Processing:    ", infile)
        
        sample = rawIn.read(1)
        while sample:
            sample = float(int.from_bytes(sample))
            sample = (sample - minVal) * multiplier
            outVal = convertSample(sample / 255.0) <<4
            sample = rawIn.read(1)
            if sample:
                sample = int.from_bytes(sample) - minVal
                sample = (sample - minVal) * multiplier
                outVal |= convertSample(sample / 255.0)
            
            pcmOut.write(outVal.to_bytes())            
            sample = rawIn.read(1)

        rawIn.close()
        pcmOut.close()
        
        print("PCM samples: ", os.path.getsize(f + ".pcm") * 2,"samples")
        print("PCM size: ", os.path.getsize(f + ".pcm"),"bytes")
        
    except IOError:
        print("cannot convert", infile)
            
