10 DISPLAY 2
20 X=128: Y=96: C=$41
30 COLOR C: CLS
40 N1 = NOT PEEK($7F82)
50 IF NOT N1 AND $80 THEN UNPLOT X,Y
60 IF N1 AND $10 THEN CLS
70 IF N1 AND $20 THEN 150
80 IF N1 AND $01 AND X < 255 THEN X=X+1
90 IF N1 AND $02 AND X > 0 THEN X=X-1
100 IF N1 AND $04 AND Y < 191 THEN Y=Y+1
110 IF N1 AND $08 AND Y > 0 THEN Y=Y-1
120 PLOT X,Y
130 IF N1 AND $40 THEN 170
140 GOTO 40
150 C=(C+16) AND $FF:IF C<32 THEN 150
160 COLOR C:WAIT $7F82,$20: GOTO 40
170 FOR I=0 TO 500 :NEXT: GOTO 40