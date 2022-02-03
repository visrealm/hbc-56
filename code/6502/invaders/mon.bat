..\..\..\tools\acme\bin\acme -I ../lib -I ../kernel -f hex -o invaders.hex -l invaders.hex.lmap -r invaders.hex.rpt invaders.asm
python ..\..\..\tools\hex2mon.py invaders.hex