********************************************************************
* CCDisk - WD1773 disk driver for Tandy/Radio Shack controller
*
* $Id$
*
* Edt/Rev  YYYY/MM/DD  Modified by
* Comment
* ------------------------------------------------------------------
*   4      1985/??/??
* From Tandy OS-9 Level One VR 02.00.00.
*
*   5      2002/07/14  Boisy G. Pitre
* Patched to handle 6ms step rate and ds drives from the "Kissable OS-9"
* column, Rainbow Magazine, October 1988.

         nam   CCDisk
         ttl   WD1773 disk driver for Tandy/Radio Shack controller

* Disassembled 98/08/23 17:21:46 by Disasm v1.6 (C) 1988 by RML

         ifp1
         use   defsfile
         use   rbfdefs
         endc

tylg     set   Drivr+Objct   
atrv     set   ReEnt+rev
rev      set   $00
edition  set   5

MaxDrv   set   4

L0000    mod   eom,name,tylg,atrv,start,size

         rmb   DRVBEG
u000F    rmb   38
u0035    rmb   8
u003D    rmb   18
u004F    rmb   27
u006A    rmb   5
u006F    rmb   56
CurDMem  rmb   2
DrivSel  rmb   1
u00AA    rmb   1
VfyBuf   rmb   2
u00AD    rmb   4
DevStRg  rmb   1
size     equ   .

         fcb   DIR.+SHARE.+PREAD.+PWRIT.+PEXEC.+READ.+WRITE.+EXEC.

name     fcs   /CCDisk/
         fcb   edition

start    lbra  Init
         lbra  Read
         lbra  Write
         lbra  GetStat
         lbra  SetStat
         lbra  Term

IRQPkt   fcb   $00,$01,$0a

* Init
*
* Entry:
*    Y  = address of device descriptor
*    U  = address of device memory area
*
* Exit:
*    CC = carry set on error
*    B  = error code
*
Init     clra
         sta   <D.DskTmr
         ldx   #DPort
         leax  $08,x
         lda   #$D0
         sta   ,x
         lbsr  L0294
         lda   ,x
         lda   #$FF
L003D    ldb   #MaxDrv
         leax  DRVBEG,u
L0041    sta   ,x
         sta   <V.TRAK,x
         leax  <DRVMEM,x
         decb  
         bne   L0041
         leax  >NMIRtn,pcr
         stx   >D.XNMI+1
         lda   #$7E
         sta   >D.XNMI
         pshs  y
         leay  >DevStRg,u
         tfr   y,d
         leay  >IRQRtn,pcr
         leax  >IRQPkt,pcr
         os9   F$IRQ    
         puls  y
         bcs   L0082
         ldd   #256
         pshs  u
         os9   F$SRqMem 
         tfr   u,x
         puls  u
         bcs   L0082
         stx   >VfyBuf,u

* GetStat
*
* Entry:
*    A  = function code
*    Y  = address of path descriptor
*    U  = address of device memory area
*
* Exit:
*    CC = carry set on error
*    B  = error code
*
GetStat

* Term
*
* Entry:
*    U  = address of device memory area
*
* Exit:
*    CC = carry set on error
*    B  = error code
*
Term     clrb
L0082    rts   

* Read
*
* Entry:
*    B  = MSB of the disk's LSN
*    X  = LSB of the disk's LSN
*    Y  = address of path descriptor
*    U  = address of device memory area
*
* Exit:
*    CC = carry set on error
*    B  = error code
*
Read     lda   #$91
         cmpx  #$0000		LSN0?
         bne   L00AD		branch if not
         bsr   L00AD		else branch subroutine
         bcs   L00A3
         ldx   PD.BUF,y		get pointer to buffer
         pshs  y,x
         ldy   >CurDMem,u
         ldb   #DD.SIZ-1	copy bytes from buffer to LSN0 buffer
L0099    lda   b,x
         sta   b,y
         decb  
         bpl   L0099
         clrb  
         puls  pc,y,x
L00A3    rts   
L00A4    bcc   L00AD
         pshs  x,b,a
         lbsr  L02D0
         puls  x,b,a

L00AD    pshs  x,b,a
         bsr   L00B8
         puls  x,b,a
         bcc   L00A3
         lsra  
         bne   L00A4
L00B8    lbsr  L019E
         bcs   L00A3
         ldx   PD.BUF,y
         pshs  y,cc
         ldb   #$80
         bsr   L00E6
L00C5    bita  >DPort+8
         bne   L00DC
         leay  -$01,y
         bne   L00C5
         lda   >DrivSel,u
         ora   #$08
         sta   >DPort
         puls  y,cc
         lbra  L026F
L00DC    lda   >DPort+$0B
         sta   ,x+
         stb   >DPort
         bra   L00DC
L00E6    orcc  #IntMasks
         stb   >DPort+8
         ldy   #$FFFF
         ldb   #$28
         orb   >DrivSel,u
         stb   >DPort
         ldb   #$A8
         orb   >DrivSel,u
         lbsr  L0294
         lda   #$02
         rts   

* Write
*
* Entry:
*    B  = MSB of the disk's LSN
*    X  = LSB of the disk's LSN
*    Y  = address of path descriptor
*    U  = address of device memory area
*
* Exit:
*    CC = carry set on error
*    B  = error code
*
Write    lda   #$91
L0106    pshs  x,b,a
         bsr   L0129
         puls  x,b,a
         bcs   L0119
         tst   <PD.VFY,y
         bne   L0117
         bsr   Verify
         bcs   L0119
L0117    clrb  
L0118    rts   
L0119    lsra  
         lbeq  L023E
         bcc   L0106
         pshs  x,b,a
         lbsr  L02D0
         puls  x,b,a
         bra   L0106
L0129    bsr   L019E
         bcs   L0118
         ldx   PD.BUF,y
         ldb   #$A0
L0131    pshs  y,cc
         bsr   L00E6
L0135    bita  >DPort+8
         bne   L014C
         leay  -$01,y
         bne   L0135
         lda   >DrivSel,u
         ora   #$08
         sta   >DPort
         puls  y,cc
         lbra  L023E
L014C    lda   ,x+
         sta   >DPort+$0B
         stb   >DPort
         bra   L014C

NMIRtn   leas  $0C,s
         puls  y,cc
         ldb   >DPort+8
         bitb  #$04
         lbne  L026F
         lbra  L0241

Verify   pshs  x,b,a
         ldx   PD.BUF,y
         pshs  x
         ldx   >VfyBuf,u
         stx   PD.BUF,y
         ldx   $04,s
         lbsr  L00B8
         puls  x
         stx   PD.BUF,y
         bcs   L019C
         lda   #$20
         pshs  u,y,a
         ldy   >VfyBuf,u
         tfr   x,u
L0188    ldx   ,u
         cmpx  ,y
         bne   L0198
         leau  $08,u
         leay  $08,y
         dec   ,s
         bne   L0188
         bra   L019A
L0198    orcc  #Carry
L019A    puls  u,y,a
L019C    puls  pc,x,b,a
L019E    clr   >u00AA,u
         bsr   L020D
         tstb  
         bne   L01B8
         tfr   x,d
         ldx   >CurDMem,u
         cmpd  #$0000
         beq   L01DD
         cmpd  $01,x
         bcs   L01BC
L01B8    comb  
         ldb   #E$Sect
         rts   
L01BC    clr   ,-s
         bra   L01C2
L01C0    inc   ,s
L01C2    subd  #18
         bcc   L01C0
         addb  #18
         lbra  L0350
         fcb   $15
L01CD    bls   L01DD
         pshs  a
         lda   >DrivSel,u
         ora   #$10
         sta   >DrivSel,u
         puls  a
L01DD    incb  
         stb   >DPort+$0A
L01E1    ldb   <$15,x
         stb   >DPort+9
         tst   >u00AA,u
         bne   L01F2
         cmpa  <$15,x
         beq   L0207
L01F2    sta   <$15,x
         sta   >DPort+$0B
         clrb
         lbsr  L0372
         pshs  x
*         ldx   #$222E
         ldx   #$082E
L0201    leax  -$01,x
         bne   L0201
         puls  x
L0207    clrb  
         rts   

DrvSel   fcb   $01,$02,$04,$40

L020D    lbsr  L02EB
         lda   <PD.DRV,y	$21,y
         cmpa  #MaxDrv
         bcs   L021B
         comb  
         ldb   #E$Unit
         rts   

L021B    pshs  x,b,a
         leax  >DrvSel,pcr
         ldb   a,x
         stb   >DrivSel,u
         leax  DRVBEG,u
         ldb   #DRVMEM
         mul   
         leax  d,x
         cmpx  >CurDMem,u
         beq   L023C
         stx   >CurDMem,u
         com   >u00AA,u
L023C    puls  pc,x,b,a
L023E    ldb   >DPort+8
L0241    bitb  #$F8
         beq   L0259
         bitb  #$80
         bne   L025B
         bitb  #$40
         bne   L025F
         bitb  #$20
         bne   L0263
         bitb  #$10
         bne   L0267
         bitb  #$08
         bne   L026B
L0259    clrb  
         rts   
L025B    comb  
         ldb   #E$NotRdy
         rts   
L025F    comb  
         ldb   #E$WP
         rts   
L0263    comb  
         ldb   #E$Write
         rts   
L0267    comb  
         ldb   #E$Seek
         rts   
L026B    comb  
         ldb   #E$CRC
         rts   
L026F    comb  
         ldb   #E$Read
         rts   
L0273    bsr   L0292
L0275    ldb   >DPort+8
         bitb  #$01
         beq   L029A
         ldd   #$00F0
         std   >u00AD,u
         bra   L0275
L0285    lda   #$08
         ora   >DrivSel,u
         sta   >DPort
         stb   >DPort+8
         rts   
L0292    bsr   L0285
L0294    lbsr  L0297
L0297    lbsr  L029A
L029A    rts   

* SetStat
*
* Entry:
*    A  = function code
*    Y  = address of path descriptor
*    U  = address of device memory area
*
* Exit:
*    CC = carry set on error
*    B  = error code
*
SetStat  ldx   PD.RGS,y
         ldb   R$B,x
         cmpb  #SS.Reset
         beq   L02D0
         cmpb  #SS.WTrk
         beq   L02AB
         comb  
         ldb   #E$UnkSvc
L02AA    rts   
L02AB    lbsr  L020D
         ldb  >DrivSel,u
         lbra  L0341
         nop
L02B6    bls   L02BA
         orb   #$10
L02BA    stb   >DrivSel,u
         ldx   >CurDMem,u
         lbsr  L01E1
         bcs   L02AA
         ldx   PD.RGS,y
         ldx   R$X,x
         ldb   #$F0
         lbra  L0131
L02D0    lbsr  L020D
         ldx   >CurDMem,u
         clr   <$15,x
         lda   #$05
L02DC    ldb   #$40
         nop
         nop
         nop
         lbsr  L0374
         deca  
         bne   L02DC
         clrb
         lbra  L036C
L02EB    pshs  y,x,b,a
         lda   <D.DskTmr
         bmi   L0301
         bne   L0309
         lda   #$08
         sta   >DPort
         ldx   #$A000
L02FB    nop   
         nop   
         leax  -$01,x
         bne   L02FB
L0301    bsr   L0312
         bcc   L0309
         ldb   #$80
         stb   <D.DskTmr
L0309    ldd   #$00F0
         std   >u00AD,u
         puls  pc,y,x,b,a

L0312    lda   #$01
         sta   <D.DskTmr
         ldx   #$0001
         leay  >u00AD,u
         clr   $04,y
         ldd   #$00F0
         os9   F$VIRQ   
         rts   

IRQRtn   pshs  a
         tst   <D.DMAReq
         beq   L0330
         bsr   L0312
         bra   L033F
L0330    clr   >DPort
         lda   >DevStRg,u
         anda  #$FE
         sta   >DevStRg,u
         clr   <D.DskTmr
L033F    puls  pc,a

L0341    lda   R$Y+1,x		get density byte
         bita  #DNS.MFM
         bne   L0349
         orb   #$40
L0349    lda   R$U+1,x		get track lo-byte
         cmpa  #$15
         lbra  L02B6

L0350    lda   <DD.FMT,x
         bita  #DNS.MFM
         beq   L0365
         lsr   ,s
         bcc   L0365
         lda   >DrivSel,u
         ora   #$40
         sta   >DrivSel,u
L0365    puls  a
         cmpa  #$15
         lbra  L01CD

L036C    orb   <PD.STP,y
         lbra  L0273
L0372    addb  #$10
L0374    orb   <PD.STP,y
         pshs  a
         lbsr  L0273
         puls  a
         rts

         emod
eom      equ   *
         end

