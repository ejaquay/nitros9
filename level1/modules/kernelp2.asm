********************************************************************
* OS9p2 - OS-9 Level One V2 P2 module
*
* $Id$
*
* Ed.    Comments                                       Who YY/MM/DD
* ------------------------------------------------------------------
*  10    From Tandy OS-9 Level One VR 02.00.00

         nam   OS9p2
         ttl   OS-9 Level One V2 P2 module

         ifp1
         use   defsfile
         endc

tylg     set   Systm+Objct
atrv     set   ReEnt+rev
rev      set   $01
edition  set   10

         mod   eom,name,tylg,atrv,start,size

size     equ   .

name     fcs   /OS9p2/
         fcb   edition

SvcTbl   fcb   $7F
         fdb   IOCall-*-2

         fcb   F$Unlink
         fdb   FUnlink-*-2

         fcb   F$Wait
         fdb   FWait-*-2

         fcb   F$Exit
         fdb   FExit-*-2

         fcb   F$Mem
         fdb   FMem-*-2

         fcb   F$Send
         fdb   FSend-*-2

         fcb   F$Sleep
         fdb   FSleep-*-2

         fcb   F$Icpt
         fdb   FIcpt-*-2

         fcb   F$ID
         fdb   FID-*-2

         fcb   F$SPrior
         fdb   FSPrior-*-2

         fcb   F$SSwi
         fdb   FSSwi-*-2

         fcb   F$STime
         fdb   FSTime-*-2

         fcb   F$Find64+$80
         fdb   FFind64-*-2

         fcb   F$All64+$80
         fdb   FAll64-*-2

         fcb   F$Ret64+$80
         fdb   FRet64-*-2

         fcb   $80

start    equ   *
* install system calls
         leay  SvcTbl,pcr
         os9   F$SSvc
         ldx   <D.PrcDBT
         os9   F$All64
         bcs   L0081
         stx   <D.PrcDBT
         sty   <D.Proc
         tfr   s,d
         deca
         ldb   #$01
         std   P$ADDR,y
         lda   #SysState
         sta   P$State,y
         ldu   <D.Init
         bsr   ChdDir
         bcc   L006A
         lbsr  JmpBoot
         bsr   ChdDir
L006A    bsr   OpenCons
         bcc   L0073
         lbsr  JmpBoot
         bsr   OpenCons
L0073    ldd   InitStr,u
         leax  d,u
         lda   #$01
         clrb
         ldy   #$0000
         os9   F$Chain
L0081    jmp   [<$FFFE]

*
* U = address of init module
ChdDir   clrb
         ldd   <SysStr,u		get system device
         beq   ChdDir10			branch if none
         leax  d,u
         lda   #READ.+EXEC.
         os9   I$ChgDir			else change directory to it
ChdDir10 rts

* open console device
* U = address of init module
OpenCons clrb
         ldd   <StdStr,u
         leax  d,u
         lda   #UPDAT.
         os9   I$Open
         bcs   OpenCn10
         ldx   <D.Proc			get process descriptor
         sta   P$Path+0,x		save path to console to stdin...
         os9   I$Dup
         sta   P$Path+1,x		...stdout
         os9   I$Dup
         sta   P$Path+2,x		...and stderr
OpenCn10 rts

FUnlink  ldd   R$U,u			D = ptr to module to unlink
         beq   L00F9
         ldx   <D.ModDir		X = ptr to 1st module dir entry
L00B8    cmpd  MD$MPtr,x	 	module match?
         beq   L00C5			branch if so
         leax  MD$ESize,x		go to next entry
         cmpx  <D.ModDir+2		is this end?
         bcs   L00B8			if not, go check next entry for match
         bra   L00F9			else exit
L00C5    lda   MD$Link,x		get link count
         beq   L00CE			branch if zero
         deca				else decrement by one
         sta   MD$Link,x		and save count
         bne   L00F9			branch if post-dec wasn't zero
* If here, deallocate module
L00CE    ldy   MD$MPtr,x		get module pointer
         cmpy  <D.BTLO			compare against boot lo mem
         bcc   L00F9
         ldb   M$Type,y			get type of module
         cmpb  #FlMgr			is it a file manager?
         bcs   L00E5			branch if not
         os9   F$IODel			determine if I/O module is in use
         bcc   L00E5			branch if not
         inc   MD$Link,x		else cancel out prior dec
         bra   L00FA			and exit call
L00E5    clra
         clrb
         std   MD$MPtr,x		clear out moddir entry's module address
         std   M$ID,y			and destroy module's first 2 bytes
         ldd   M$Size,y			get size of module in D
         lbsr  L0236
         exg   d,y
         exg   a,b
         ldx   <D.FMBM			get free mem bitmap ptr
         os9   F$DelBit			delete the corresponding bits
L00F9    clra
L00FA    rts

FWait    ldy   <D.Proc
         ldx   <D.PrcDBT
         lda   P$CID,y
         bne   L0108
         comb
         ldb   #E$NoChld
         rts
L0108    os9   F$Find64
         lda   P$State,y
         bita  #Dead                   dead?
         bne   L0124                   branch if so
         lda   P$SID,y                 siblings?
         bne   L0108                   branch if so
         clr   R$A,u
         ldx   <D.Proc
         orcc  #FIRQMask+IRQMask
         ldd   <D.WProcQ
         std   P$Queue,x
         stx   <D.WProcQ
         lbra  L034D
L0124    ldx   <D.Proc
L0126    lda   P$ID,y
         ldb   <P$Signal,y
         std   R$A,u
         pshs  u,y,x,a
         leay  P$PID,x
         ldx   <D.PrcDBT
         bra   L0138
L0135    os9   F$Find64
L0138    lda   P$SID,y
         cmpa  ,s
         bne   L0135
         ldu   $03,s
         ldb   $02,u
         stb   $02,y
         os9   F$Ret64
         puls  pc,u,y,x,a

FExit    ldx   <D.Proc
         ldb   R$B,u
         stb   P$Signal,x
         ldb   #NumPaths
         leay  P$PATH,x
L0155    lda   ,y+
         beq   L0160
         pshs  b
         os9   I$Close
         puls  b
L0160    decb
         bne   L0155
         lda   P$ADDR,x
         tfr   d,u
         lda   P$PagCnt,x
         os9   F$SRtMem
         ldu   P$PModul,x
         os9   F$UnLink
         ldu   <D.Proc
         leay  P$PID,u
         ldx   <D.PrcDBT
         bra   L018C
L017A    clr   $02,y
         os9   F$Find64
         lda   P$State,y
         bita  #Dead                   dead?
         beq   L018A                   branch if not
         lda   ,y
         os9   F$Ret64
L018A    clr   P$PID,y
L018C    lda   P$SID,y
         bne   L017A
         ldx   #$0041
         lda   P$PID,u
         bne   L01A4
         ldx   <D.PrcDBT
         lda   P$ID,u
         os9   F$Ret64
         bra   L01C2
L01A0    cmpa  ,x
         beq   L01B2
L01A4    leay  ,x                      Y = proc desc ptr
         ldx   P$Queue,x
         bne   L01A0
         lda   P$State,u
         ora   #Dead
         sta   P$State,u
         bra   L01C2
L01B2    ldd   P$Queue,x
         std   P$Queue,y
         os9   F$AProc
         leay  ,u
         ldu   P$SP,x
         ldu   $01,u
         lbsr  L0126
L01C2    clra
         clrb
         std   <D.Proc
         rts

FMem     ldx   <D.Proc
         ldd   R$A,u
         beq   L0227
         bsr   L0236
         subb  P$PagCnt,x
         beq   L0227
         bcs   L0207
         tfr   d,y
         ldx   P$ADDR,x
         pshs  u,y,x
         ldb   ,s
         beq   L01E1
         addb  $01,s
L01E1    ldx   <D.FMBM
         ldu   <D.FMBM+2
         os9   F$SchBit
         bcs   L0231
         stb   $02,s
         ldb   ,s
         beq   L01F6
         addb  $01,s
         cmpb  $02,s
         bne   L0231
L01F6    ldb   $02,s
         os9   F$AllBit
         ldd   $02,s
         suba  $01,s
         addb  $01,s
         puls  u,y,x
         ldx   <D.Proc
         bra   L0225

L0207    negb
         tfr   d,y
         negb
         addb  $08,x
         addb  $07,x
         cmpb  $04,x
         bhi   L0217
         comb
         ldb   #E$DelSP
         rts

L0217    ldx   <D.FMBM
         os9   F$DelBit
         tfr   y,d
         negb
         ldx   <D.Proc
         addb  P$PagCnt,x
         lda   P$ADDR,x
L0225    std   P$ADDR,x
L0227    lda   P$PagCnt,x
         clrb
         std   $01,u
         adda  P$ADDR,x
         std   $06,u
         rts
L0231    comb
         ldb   #E$MemFul
         puls  pc,u,y,x

L0236    addd  #$00FF
         clrb
         exg   a,b
         rts

FSend    lda   R$A,u
         bne   L024F
         inca
L0242    ldx   <D.Proc
         cmpa  P$ID,x
         beq   L024A
         bsr   L024F
L024A    inca
         bne   L0242
         clrb
         rts

L024F    ldx   <D.PrcDBT
         os9   F$Find64
         bcc   L025E
         ldb   #E$IPrcID
         rts

L0259    comb
         ldb   #E$IPrcID
         puls  pc,y,a

L025E    pshs  y,a
         ldb   P$SID,u
         bne   L0275
         ldx   <D.Proc
         ldd   P$User,x
         beq   L026F
         cmpd  P$User,y
         bne   L0259
L026F    lda   P$State,y
         ora   #Condem
         sta   P$State,y
L0275    orcc  #FIRQMask+IRQMask
         lda   <P$Signal,y
         beq   L0284
         deca
         beq   L0284
         comb
         ldb   #E$USigP
         puls  pc,y,a

L0284    ldb   P$SID,u
         stb   <P$Signal,y
         ldx   #$0043
         bra   L02B4
L028E    cmpx  $01,s
         bne   L02B4
         lda   P$State,x
         bita  #$40
         beq   L02C7
         ldu   P$SP,x
         ldd   R$X,u
         beq   L02C7
         ldu   P$Queue,x
         beq   L02C7
         pshs  b,a
         lda   P$State,u
         bita  #$40
         puls  b,a
         beq   L02C7
         ldu   P$SP,u
         addd  P$SP,u
         std   P$SP,u
         bra   L02C7
L02B4    leay  ,x
         ldx   P$Queue,y
         bne   L028E
         ldx   #$0041
L02BD    leay  ,x
         ldx   P$Queue,y
         beq   L02D7
         cmpx  $01,s
         bne   L02BD
L02C7    ldd   P$Queue,x
         std   P$Queue,y
         lda   <P$Signal,x
         deca
         bne   L02D4
         sta   <P$Signal,x
L02D4    os9   F$AProc
L02D7    clrb
         puls  pc,y,a

* F$Sleep
FSleep   ldx   <D.Proc                 get pdesc
         orcc  #FIRQMask+IRQMask       mask ints
         lda   P$Signal,x              get proc signal
         beq   L02EE                   branch if none
         deca                          dec signal
         bne   L02E9                   branch if not S$Wake
         sta   P$Signal,x              clear signal
L02E9    os9   F$AProc                 insert into activeq
         bra   L034D
L02EE    ldd   R$X,u                   get timeout
         beq   L033A                   branch if forever
         subd  #$0001                  subtract 1
         std   R$X,u                   save back to caller
         beq   L02E9                   branch if give up tslice
         pshs  u,x
         ldx   #$0043
L02FE    leay  ,x
         ldx   P$Queue,x
         beq   L0316
         pshs  b,a
         lda   P$State,x
         bita  #TimSleep
         puls  b,a
         beq   L0316
         ldu   P$SP,x
         subd  $04,u
         bcc   L02FE
         addd  $04,u
L0316    puls  u,x
         std   R$X,u
         ldd   P$Queue,y
         stx   P$Queue,y
         std   P$Queue,x
         lda   P$State,x
         ora   #TimSleep
         sta   P$State,x
         ldx   P$Queue,x
         beq   L034D
         lda   P$State,x
         bita  #TimSleep
         beq   L034D
         ldx   P$SP,x
         ldd   P$SP,x
         subd  R$X,u
         std   P$SP,x
         bra   L034D
L033A    lda   P$State,x
         anda  #^TimSleep
         sta   P$State,x
         ldd   #$0043
L0343    tfr   d,y
         ldd   P$Queue,y
         bne   L0343
         stx   P$Queue,y
         std   P$Queue,x
L034D    leay  <L0361,pcr
         pshs  y
         ldy   <D.Proc
         ldd   P$SP,y
         ldx   R$X,u
         pshs  u,y,x,dp,b,a,cc
         sts   P$SP,y
         os9   F$NProc
L0361    std   P$SP,y
         stx   R$X,u
         clrb
         rts

* F$Icpt
FIcpt    ldx   <D.Proc                 get pdesc
         ldd   R$X,u                   get addr of icpt rtn
         std   <P$SigVec,x             store in pdesc
         ldd   R$U,u                   get data ptr
         std   <P$SigDat,x             store in pdesc
         clrb
         rts

* F$SPrior
FSPrior  lda   R$A,u                   get ID
         ldx   <D.PrcDBT               find pdesc
         os9   F$Find64
         bcs   FSPrEx                  branch if can't find
         ldx   <D.Proc                 get pdesc
         ldd   P$User,x                get user ID
         cmpd  P$User,y                same as dest pdesc
         bne   FSPrEx                  branch if not, must be owner
         lda   R$B,u                   else get prior
         sta   P$Prior,y               and store it in dest pdesc
         rts
FSPrEx   comb
         ldb   #E$IPrcID
         rts

* F$ID
FID      ldx   <D.Proc                 get proc desc
         lda   P$ID,x                  get id
         sta   R$A,u                   put in A
         ldd   P$User,x                get user ID
         std   R$Y,u                   store in Y
         clrb
         rts

* F$SSwi
FSSwi    ldx   <D.Proc
         leay  P$SWI,x
         ldb   R$A,u
         decb
         cmpb  #$03
         bcc   FSSwiEx
         lslb
         ldx   R$X,u
         stx   b,y
         rts
FSSwiEx  comb
         ldb   #E$ISWI
         rts

ClkName  fcs   /Clock/

* F$STime
FSTime   ldx   R$X,u
         ldd   ,x
         std   <D.Year
         ldd   2,x
         std   <D.Day
         ldd   4,x
         std   <D.Min
         lda   #Systm+Objct
         leax  <ClkName,pcr
         os9   F$Link
         bcs   L03D2
         jmp   ,y
         clrb
L03D2    rts

* F$Find64
FFind64  lda   R$A,u
         ldx   R$X,u
         bsr   L03DF
         bcs   L03DE
         sty   R$Y,u
L03DE    rts

L03DF    pshs  b,a
         tsta
         beq   L03F3
         clrb
         lsra
         rorb
         lsra
         rorb
         lda   a,x
         tfr   d,y
         beq   L03F3
         tst   ,y
         bne   L03F4
L03F3    coma
L03F4    puls  pc,b,a

* F$All64
FAll64   ldx   R$X,u
         bne   L0402
         bsr   L040C
         bcs   L040B
         stx   ,x
         stx   R$X,u
L0402    bsr   L0422
         bcs   L040B
         sta   R$A,u
         sty   R$Y,u
L040B    rts

L040C    pshs  u
         ldd   #$0100
         os9   F$SRqMem
         leax  ,u
         puls  u
         bcs   L0421
         clra
         clrb
L041C    sta   d,x
         incb
         bne   L041C
L0421    rts

L0422    pshs  u,x
         clra
L0425    pshs  a
         clrb
         lda   a,x
         beq   L0437
         tfr   d,y
         clra
L042F    tst   d,y
         beq   L0439
         addb  #$40
         bcc   L042F
L0437    orcc  #Carry
L0439    leay  d,y
         puls  a
         bcc   L0464
         inca
         cmpa  #$40
         bcs   L0425
         clra
L0445    tst   a,x
         beq   L0453
         inca
         cmpa  #$40
         bcs   L0445
         ldb   #E$PthFul
         coma
         bra   L0471
L0453    pshs  x,a
         bsr   L040C
         bcs   L0473
         leay  ,x
         tfr   x,d
         tfr   a,b
         puls  x,a
         stb   a,x
         clrb
L0464    lslb
         rola
         lslb
         rola
         ldb   #$3F
L046A    clr   b,y
         decb
         bne   L046A
         sta   ,y
L0471    puls  pc,u,x
L0473    leas  3,s
         puls  pc,u,x

* F$Ret64
FRet64   lda   R$A,u
         ldx   R$X,u
         pshs  u,y,x,b,a
         clrb
         lsra
         rorb
         lsra
         rorb
         pshs  a
         lda   a,x
         beq   L04A0
         tfr   d,y
         clr   ,y
         clrb
         tfr   d,u
         clra
Ret64Lp  tst   d,u
         bne   Ret64Ex
         addb  #64
         bne   Ret64Lp
         inca
         os9   F$SRtMem
         lda   ,s
         clr   a,x
L04A0
Ret64Ex  clr   ,s+
         puls  pc,u,y,x,b,a

IOMgr    fcs   /IOMAN/

IOCall   pshs  u,y,x,b,a
         ldu   <D.Init                 get ptr to init
         bsr   LinkIOM                 link to IOMan
         bcc   JmpIOM                  jump into him if ok
         bsr   JmpBoot                 try boot
         bcs   IOCallRt                problem booting... return w/ error
         bsr   LinkIOM                 ok, NOW link to IOMan
         bcs   IOCallRt                still a problem...
JmpIOM   jsr   ,y
         puls  u,y,x,b,a
         ldx   -2,y
         jmp   ,x
IOCAllRt puls  pc,u,y,x,b,a

LinkIOM  leax  IOMgr,pcr
         lda   #Systm+Objct
         os9   F$Link
         rts

*
* U = address of init module
JmpBoot  pshs  u
         comb
         tst   <D.Boot                 already booted?
         bne   JmpBtEr                 yep, return to caller...
         inc   <D.Boot                 else set boot flag
         ldd   <BootStr,u              get pointer to boot str
         beq   JmpBtEr                 if none, return to caller
         leax  d,u                     X = ptr to boot mod name
         lda   #Systm+Objct
         os9   F$Link                  link
         bcs   JmpBtEr                 return if error
         jsr   ,y                      ...else jsr into boot module
* D = size of bootfile
* X = address of bootfile
         bcs   JmpBtEr                 return if error
         stx   <D.MLIM
         stx   <D.BTLO
         leau  d,x
         stu   <D.BTHI
* search through bootfile and validate modules
ValBoot  ldd   ,x
         cmpd  #M$ID12
         bne   ValBoot1
         os9   F$VModul
         bcs   ValBoot1
         ldd   M$Size,x
         leax  d,x                     move X to next module
         bra   ValBoot2
ValBoot1 leax  1,x                     advance one byte
ValBoot2 cmpx  <D.BTHI
         bcs   ValBoot
JmpBtEr  puls  pc,u

         emod
eom      equ   *
