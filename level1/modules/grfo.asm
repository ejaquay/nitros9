********************************************************************
* GRFO - CoCo 2 Graphics co-driver
*
* $Id$
*
* Ed.    Comments                                       Who YY/MM/DD
* ------------------------------------------------------------------
*        From Tandy OS-9 Level One VR 02.00.00

         nam   GRFO
         ttl   CoCo 2 Graphics co-driver

* Disassembled 98/08/23 18:01:47 by Disasm v1.6 (C) 1988 by RML

         ifp1
         use   defsfile
         endc

tylg     set   Systm+Objct   
atrv     set   ReEnt+rev
rev      set   $00
edition  set   $01

         mod   eom,name,tylg,atrv,start,size

u0000    rmb   0
size     equ   .
         fcb   $07 

name     fcs   /GRFO/
         fcb   edition

start    lbra  L006A
         lbra  L002A
         lbra  L0026
         lbra  L0026
         lbra  L006A

L0022    fcb   $00,$55,$aa,$ff

L0026    comb
         ldb   #E$UnkSvc
         rts
L002A    suba  #$15
         leax  <L0034,pcr
         lsla  
         ldd   a,x
         jmp   d,x

L0034    fdb   $0029,$005f,$005c,$003b,$0038,$0121
         fdb   $0036,$011e,$0204,$0036,$0036

L004A    ldd   <$28,u
         cmpb  #$C0
         bcs   L0053
         ldb   #$BF
L0053    tst   <$24,u
         bmi   L0059
         lsra
L0059    std   <$28,u
         rts
         leax  <L0065,pcr
L0060    ldb   #$02
         lbra  L015A
L0065    bsr   L004A
         std   <$45,u

L006A    clrb  
         rts   
         clr   <$47,u
         leax  <L0074,pcr
         bra   L0060
L0074    bsr   L004A
         std   <$45,u
         bsr   L007E
         lbra  L014A
L007E    jsr   [<$5D,u]
L0081    tfr   a,b
         comb  
         andb  ,x
         stb   ,x
         anda  <$47,u
         ora   ,x
         sta   ,x
         rts   
         clr   <$47,u
         leax  <L0098,pcr
         bra   L0060

L0098    fdb   $8db0,$3272,$ed6c,$add8
         fdb   $5daf,$62a7,$61ec,$c845,$add8,$5da7,$e44f,$5fed
         fdb   $6486,$bfa0,$c846,$a7c8,$4686,$bfa0,$c829,$a7c8
         fdb   $2986,$ffa7,$664f,$e6c8,$45e0,$c828,$8200,$2a06
         fdb   $4050,$8200,$6066,$ed68,$2605,$ccff,$ffed,$6486
         fdb   $e0a7,$674f,$e6c8,$46e0,$c829,$8200,$2a06,$4050
         fdb   $8200,$6067,$ed6a,$2008

L00F8    sta   ,s
         ldd   $04,s
         subd  $0A,s
         std   $04,s
L0100    lda   ,s
         lbsr  L0081
         cmpx  $02,s
         bne   L010F
         lda   ,s
         cmpa  $01,s
         beq   L0143
L010F    ldd   $04,s
         bpl   L011D
         addd  $08,s
         std   $04,s
         lda   $07,s
         leax  a,x
         bra   L0100
L011D    lda   ,s
         ldb   $06,s
         bpl   L0133
         lsla  
         ldb   <$24,u
         bmi   L012A
         lsla  
L012A    bcc   L00F8
         lda   <$4A,u
         leax  -$01,x
         bra   L00F8
L0133    lsra  
         ldb   <$24,u
         bmi   L013A
         lsra  
L013A    bcc   L00F8
         lda   <$49,u
         leax  $01,x
         bra   L00F8
L0143    ldd   $0C,s
         std   <$45,u
         leas  $0E,s
L014A    lda   <$48,u
         sta   <$47,u
         clrb  
         rts   
         clr   <$47,u
         leax  <L0162,pcr
         ldb   #$01
L015A    stb   <$25,u
         stx   <$26,u
         clrb  
         rts   

L0162    fdb   $327c,$e6c8,$29e7,$614f,$a7e4,$eb61,$8900
         fdb   $4050,$8200,$c300,$03ed
         fcb   $62

L0179    lda   ,s
         cmpa  $01,s
         bcc   L01AB
         ldb   $01,s
         bsr   L01B9
         clra  
         ldb   $02,s
         bpl   L0193
         ldb   ,s
         lslb  
         rola  
         lslb  
         rola  
         addd  #$0006
         bra   L01A3
L0193    dec   $01,s
         clra  
         ldb   ,s
         subb  $01,s
         sbca  #$00
         lslb  
         rola  
         lslb  
         rola  
         addd  #$000A
L01A3    addd  $02,s
         std   $02,s
         inc   ,s
         bra   L0179
L01AB    lda   ,s
         cmpa  $01,s
         bne   L01B5
         ldb   $01,s
         bsr   L01B9
L01B5    leas  $04,s
         bra   L014A
L01B9    leas  -$08,s
         sta   ,s
         clra  
         std   $02,s
         nega  
         negb  
         sbca  #$00
         std   $06,s
         ldb   ,s
         clra  
         std   ,s
         nega  
         negb  
         sbca  #$00
         std   $04,s
         ldx   $06,s
         bsr   L0202
         ldd   $04,s
         ldx   $02,s
         bsr   L0202
         ldd   ,s
         ldx   $02,s
         bsr   L0202
         ldd   ,s
         ldx   $06,s
         bsr   L0202
         ldd   $02,s
         ldx   ,s
         bsr   L0202
         ldd   $02,s
         ldx   $04,s
         bsr   L0202
         ldd   $06,s
         ldx   $04,s
         bsr   L0202
         ldd   $06,s
         ldx   ,s
         bsr   L0202
         leas  $08,s
         rts   
L0202    pshs  b,a
         ldb   <$46,u
         clra  
         leax  d,x
         cmpx  #$0000
         bmi   L0214
         cmpx  #$00BF
         ble   L0216
L0214    puls  pc,b,a
L0216    ldb   <$45,u
         clra  
         tst   <$24,u
         bmi   L0221
         lslb  
         rola  
L0221    addd  ,s++
         tsta  
         beq   L0227
         rts   
L0227    pshs  b
         tfr   x,d
         puls  a
         tst   <$24,u
         lbmi  L007E
         lsra  
         lbra  L007E
         clr   <$41,u
         leas  -$07,s
         lbsr  L03AB
         lbcs  L0346
         lda   #$FF
         sta   <$4F,u
         ldd   <$45,u
         lbsr  L0351
         lda   <$4C,u
         sta   <$4D,u
         tst   <$24,u
         bpl   L0261
         tsta  
         beq   L0267
         lda   #$FF
         bra   L0267
L0261    leax  >L0022,pcr
         lda   a,x
L0267    sta   <$4E,u
         cmpa  <$47,u
         lbeq  L0346
         ldd   <$45,u
L0274    suba  #$01
         bcs   L027F
         lbsr  L0351
         bcs   L027F
         beq   L0274
L027F    inca  
         std   $01,s
L0282    lbsr  L0384
         adda  #$01
         bcs   L0290
         lbsr  L0351
         bcs   L0290
         beq   L0282
L0290    deca  
         ldx   $01,s
         lbsr  L03D3
         neg   <$4F,u
         lbsr  L03D3
L029C    lbsr  L03F9
         lbcs  L0346
         tst   <$4F,u
         bpl   L02B3
         subb  #$01
         bcs   L029C
         std   $03,s
         tfr   x,d
         decb  
         bra   L02BD
L02B3    incb  
         cmpb  #$BF
         bhi   L029C
         std   $03,s
         tfr   x,d
         incb  
L02BD    std   $01,s
         lbsr  L0351
         bcs   L029C
L02C4    bne   L02D2
         suba  #$01
         bcc   L02CD
         inca  
         bra   L02D6
L02CD    lbsr  L0351
         bcc   L02C4
L02D2    adda  #$01
         bcs   L029C
L02D6    cmpd  $03,s
         bhi   L029C
         bsr   L0351
         bcs   L029C
         bne   L02D2
         std   $05,s
         cmpd  $01,s
         bcc   L02FB
         ldd   $01,s
         decb  
         cmpd  $05,s
         beq   L02FB
         neg   <$4F,u
         ldx   $05,s
         lbsr  L03D3
         neg   <$4F,u
L02FB    ldd   $05,s
L02FD    std   $01,s
L02FF    bsr   L0351
         bcs   L030B
         bne   L030B
         bsr   L0384
         adda  #$01
         bcc   L02FF
L030B    deca  
         ldx   $01,s
         lbsr  L03D3
         std   $05,s
         adda  #$01
         bcs   L0326
L0317    cmpd  $03,s
         bcc   L0326
         adda  #$01
         bsr   L0351
         bcs   L0326
         bne   L0317
         bra   L02FD
L0326    inc   $03,s
         inc   $03,s
         ldd   $03,s
         cmpa  #$02
         lbcs  L029C
         ldd   $05,s
         cmpd  $03,s
         lbcs  L029C
         neg   <$4F,u
         ldx   $03,s
         lbsr  L03D3
         lbra  L029C
L0346    leas  $07,s
         clrb  
         ldb   <$41,u
         beq   L0350
L034E    orcc  #Carry
L0350    rts   
L0351    pshs  b,a
         cmpb  #$BF
         bhi   L0380
         tst   <$24,u
         bmi   L0360
         cmpa  #$7F
         bhi   L0380
L0360    jsr   [<$5D,u]
         tfr   a,b
         andb  ,x
L0367    bita  #$01
         bne   L0376
         lsra  
         lsrb  
         tst   <$24,u
         bmi   L0367
         lsra  
         lsrb  
         bra   L0367
L0376    stb   <$4C,u
         cmpb  <$4D,u
         andcc #^Carry
         puls  pc,b,a
L0380    orcc  #Carry
         puls  pc,b,a
L0384    pshs  b,a
         jsr   [<$5D,u]
         bita  #$80
         beq   L03A6
         ldb   <$4E,u
         cmpb  ,x
         bne   L03A6
         ldb   <$47,u
         stb   ,x
         puls  b,a
         tst   <$24,u
         bmi   L03A3
         adda  #$03
         rts   
L03A3    adda  #$07
         rts   
L03A6    lbsr  L0081
         puls  pc,b,a
L03AB    ldx   <$3F,u
         beq   L03B5
         stx   <$3D,u
L03B3    clrb  
         rts   
L03B5    pshs  u
         ldd   #$0200
         os9   F$SRqMem 
         bcc   L03C1
         puls  pc,u
L03C1    tfr   u,d
         puls  u
         std   <$3B,u
         addd  #$0200
         std   <$3F,u
         std   <$3D,u
         bra   L03B3
L03D3    pshs  b,a
         ldd   <$3D,u
         subd  #$0004
         cmpd  <$3B,u
         bcs   L03F2
         std   <$3D,u
         tfr   d,y
         lda   <$4F,u
         sta   ,y
         stx   $01,y
         puls  b,a
         sta   $03,y
         rts   
L03F2    ldb   #$F5
         stb   <$41,u
         puls  pc,b,a
L03F9    ldd   <$3D,u
         cmpd  <$3F,u
         lbcc  L034E
         tfr   d,y
         addd  #$0004
         std   <$3D,u
         lda   ,y
         sta   <$4F,u
         ldd   $01,y
         tfr   d,x
         lda   $03,y
         andcc #^Carry
         rts   

         emod
eom      equ   *
