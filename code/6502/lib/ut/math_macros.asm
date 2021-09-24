; 6502
;
; Math macros
;
; Copyright (c) 2020 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;


!macro lsr2 {
        lsr
        lsr
}

!macro lsr3 {
        +lsr2
        lsr
}

!macro lsr4 {
        +lsr3
        lsr
}

!macro lsr5 {
        +lsr4
        lsr
}

!macro lsr6 {
        +lsr5
        lsr
}

!macro lsr7 {
        +lsr6
        lsr
}

!macro div2   { lsr }
!macro div4   { +lsr2 }
!macro div8   { +lsr3 }
!macro div16  { +lsr4 }
!macro div32  { +lsr5 }
!macro div64  { +lsr6 }
!macro div128 { +lsr7 }

!macro asl2 {
        asl
        asl
}

!macro asl3 {
        +asl2
        asl
}

!macro asl4 {
        +asl3
        asl
}

!macro asl5 {
        +asl4
        asl
}

!macro asl6 {
        +asl5
        asl
}

!macro asl7 {
        +asl6
        asl
}

!macro mul2   { asl }
!macro mul4   { +asl2 }
!macro mul8   { +asl3 }
!macro mul16  { +asl4 }
!macro mul32  { +asl5 }
!macro mul64  { +asl6 }
!macro mul128 { +asl7 }
