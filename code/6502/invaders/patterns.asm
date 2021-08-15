; Troy's HBC-56 - 6502 - Invaders
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
; Sprite / character patterns
;

playerSprite:
       !byte $00,$00,$00,$00,$00,$00,$08,$08
       !byte $08,$08,$1C,$7F,$FF,$FF,$FF,$63
       !byte $00,$00,$00,$00,$00,$00,$00,$00
       !byte $00,$00,$00,$00,$80,$80,$80,$00

bulletSprite:
       !byte $80,$80,$80,$80,$80,$00,$00,$00
       !byte $00,$00,$00,$00,$00,$00,$00,$00
       !byte $00,$00,$00,$00,$00,$00,$00,$00
       !byte $00,$00,$00,$00,$00,$00,$00,$00

EMPTY:
       !byte $00,$00,$00,$00,$00,$00,$00,$00

INVADER1:
IP10L  !byte $1E,$FF,$CC,$FF,$FF,$12,$21,$C0
IP10R  !byte $00,$C0,$C0,$C0,$C0,$00,$00,$C0
IP12L  !byte $1E,$FF,$CC,$FF,$FF,$12,$21,$33
IP12R  !byte $00,$C0,$C0,$C0,$C0,$00,$00,$00

INVADER2:
IP20L  !byte $63,$22,$3E,$6B,$FF,$BE,$A2,$36
IP20R  !byte $00,$00,$00,$00,$80,$80,$80,$00
IP22L  !byte $63,$22,$BE,$AB,$FF,$3E,$22,$C1
IP22R  !byte $00,$00,$80,$80,$80,$00,$00,$80

INVADER3:
IP30L  !byte $08,$1C,$3E,$6B,$7F,$14,$22,$41
IP30R  !byte $00,$00,$00,$00,$00,$00,$00,$00
IP32L  !byte $08,$1C,$3E,$6B,$7F,$14,$22,$14
IP32R  !byte $00,$00,$00,$00,$00,$00,$00,$00

BBORDR !byte $00,$00,$1F,$3F,$7F,$78,$70,$70
       !byte $00,$00,$FF,$FF,$FF,$00,$00,$00
       !byte $00,$00,$FC,$FE,$FF,$0F,$07,$07
       !byte $70,$70,$70,$70,$70,$70,$70,$70
       !byte $07,$07,$07,$07,$07,$07,$07,$07
       !byte $70,$70,$70,$70,$78,$7F,$3F,$1F
       !byte $00,$00,$00,$00,$00,$FF,$FF,$FF
       !byte $07,$07,$07,$07,$0F,$FF,$FE,$FC

SHIELD !byte $00,$03,$07,$0F,$1F,$3F,$3F,$3F
       !byte $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
       !byte $00,$C0,$E0,$F0,$F8,$FC,$FC,$FC
       !byte $3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F
       !byte $FF,$FF,$FF,$FF,$C3,$81,$81,$81
       !byte $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC