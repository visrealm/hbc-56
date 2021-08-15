; Troy's HBC-56 - 6502 - Invaders
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
; Title screen
;


TITLES !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E4,$D9,$B0,$D9,$DE
       !byte $E6,$D1,$D4,$D5,$E2,$E3,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$A0,$9F,$99
       !byte $9E,$A4,$A3,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$22,$23,$85,$7F,$81,$80,$FF,$FF,$FF,$10,$11,$81,$80
       !byte $7F,$82,$80,$FF,$FF,$FF,$06,$07,$81,$85,$7F,$83,$80,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$98,$99,$A4,$70,$A4,$98,$95,$70,$A9,$95,$9C,$9C,$9F,$A7
       !byte $70,$A3,$91,$A5,$93,$95,$A2,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$99,$9E,$70,$A4,$98,$95,$70,$93,$95,$9E,$A4,$95,$A2,$70
       !byte $96,$9F,$A2,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$9D,$91,$A8,$99,$9D,$A5,$9D,$70,$A0,$9F,$99,$9E,$A4,$A3
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$8F,$8F,$8F,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$95,$A8,$A4,$A2,$91,$70,$9D,$99,$A3,$A3,$99,$9C,$95,$70
       !byte $92,$91,$A3,$95,$70,$91,$A7,$91,$A2,$94,$95,$94,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$91,$A4,$70,$83,$80,$80,$80,$70,$A0,$9F,$99,$9E,$A4,$A3
       !byte $7E,$70,$70,$9F,$9E,$95,$70,$92,$91,$A3,$95,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$A2,$95,$A0,$91,$99,$A2,$95,$94,$70,$95,$A6,$95,$A2,$A9
       !byte $70,$81,$80,$7C,$80,$80,$80,$70,$A0,$9F,$99,$9E,$A4,$A3,$7E,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$D9,$DE,$E6,$D1,$D4,$D5,$E2
       !byte $B0,$DF,$E0,$E4,$D9,$DF,$DE,$E3,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$C1,$BE,$B0,$DD,$D5,$E2,$D5,$DC,$E9,$B0
       !byte $D1,$D7,$D7,$E2,$D5,$E3,$E3,$D9,$E6,$D5,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$C2,$BE,$B0,$D4,$DF,$E7,$DE,$E2,$D9,$D7
       !byte $D8,$E4,$B0,$DE,$D1,$E3,$E4,$E9,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$69,$5F,$65,$62,$30,$53
       !byte $58,$5F,$59,$53,$55,$4F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $FF,$FF,$FF,$FF,$FF,$90,$81,$89,$88,$81,$70,$A4,$95,$A8,$91,$A3
       !byte $70,$99,$9E,$A3,$A4,$A2,$A5,$9D,$95,$9E,$A4,$A3,$FF,$FF,$FF,$FF