********************************************************************
* p[wx]d - Print work/execution directory
*
* $Id$
*
* Ed.    Comments                                       Who YY/MM/DD
* ------------------------------------------------------------------
*   1    From Tandy OS-9 Level One VR 02.00.00

         nam   p[wx]d
         ttl   Print work/execution directory

* Disassembled 98/09/10 23:50:10 by Disasm v1.6 (C) 1988 by RML

         ifp1
         use   defsfile
         use   rbfdefs
         endc

tylg     set   Prgrm+Objct   
atrv     set   ReEnt+rev
rev      set   $01
edition  set   1

         mod   eom,name,tylg,atrv,start,size

         org   0
fildes   rmb   1
bufptr   rmb   2
dotdotfd rmb   3
dotfd    rmb   3
ddcopy   rmb   5
dentry   rmb   160
buffer   rmb   1
sttbuf   rmb   282
size     equ   .

         IFNE   PXD
name     fcs   /pxd/
         ELSE
         IFNE  PWD
name     fcs   /pwd/
         ENDC
         ENDC
         fcb   edition

         IFNE   PXD
badnam   fcc   "pxd: bad name in path"
         ELSE
         IFNE  PWD
badnam   fcc   "pwd: bad name in path"
         ENDC
         ENDC
         fcb   C$CR
dotdot   fcc   "."
dot      fcc   "."
cr       fcb   C$CR
rdmsg    fcc   "read error"
         fcb   C$CR

start    leax  >buffer,u
         lda   #C$CR
         sta   ,x
         stx   <bufptr
         leax  >dot,pcr
         bsr   open
         sta   <fildes
         lbsr  rdtwo
         ldd   <dotdotfd
         std   <ddcopy
         lda   <dotdotfd+2
         sta   <ddcopy+2
L0052    bsr   L00C6
         beq   L0079
         leax  >dotdot,pcr
         bsr   chdir
         lda   <fildes
         os9   I$Close  
         bcs   L008D
         leax  >dot,pcr
         bsr   open
         bsr   rdtwo
         bsr   L00A8
         bsr   L00E2
         ldd   <dotdotfd
         std   <ddcopy
         lda   <dotdotfd+2
         sta   <ddcopy+2
         bra   L0052
L0079    lbsr  L00FB
         ldx   <bufptr
         ldy   #$0081
         lda   #$01
         os9   I$WritLn 
         lda   <fildes
         os9   I$Close  
         clrb  
L008D    os9   F$Exit   
         IFNE  PXD
chdir    lda   #DIR.+EXEC.+READ.
         ELSE
         IFNE  PWD
chdir    lda   #DIR.+READ.
         ENDC
         ENDC
         os9   I$ChgDir 
         rts   
         IFNE  PXD
open     lda   #DIR.+EXEC.+READ.
         ELSE
         IFNE  PWD
open     lda   #DIR.+READ.
         ENDC
         ENDC
         os9   I$Open   
         rts   

read32   lda   <fildes
         leax  dentry,u
         ldy   #DIR.SZ
         os9   I$Read   
         rts   

L00A8    lda   <fildes
         bsr   read32
         bcs   L010F
         leax  dentry,u
         leax  <DIR.FD,x
         leay  ddcopy,u
         bsr   attop
         bne   L00A8
         rts   

attop    ldd   ,x++
         cmpd  ,y++
         bne   L00C5
         lda   ,x
         cmpa  ,y
L00C5    rts   

L00C6    leax  dotdotfd,u
         leay  dotfd,u
         bsr   attop   * check if we're at the top
         rts   

rdtwo    bsr   read32  * read "." from directory
         ldd   <dentry+DIR.FD
         std   <dotfd
         lda   <dentry+DIR.FD+2
         sta   <dotfd+2
         bsr   read32  * read ".." from directory
         ldd   <dentry+DIR.FD
         std   <dotdotfd
         lda   <dentry+DIR.FD+2
         sta   <dotdotfd+2
         rts   

L00E2    leax  dentry,u
prsnam   os9   F$PrsNam 
         bcs   L0109
         ldx   <bufptr
L00EB    lda   ,-y
         anda  #$7F
         sta   ,-x
         decb  
         bne   L00EB
         lda   #PDELIM
         sta   ,-x
         stx   <bufptr
         rts   
L00FB    lda   <fildes
         ldb   #SS.DevNm
         leax  >sttbuf,u
         os9   I$GetStt 
         bsr   prsnam
         rts   
L0109    leax  >badnam,pcr
         bra   wrerr
L010F    leax  >rdmsg,pcr
         bra   wrerr
L0115    lda   #$02
         os9   I$Write  
         bcs   L0128
         rts   
         bsr   L0115
         leax  >cr,pcr
wrerr    lda   #$02
         os9   I$WritLn 
L0128    ldb   #$00
         os9   F$Exit   

         emod
eom      equ   *
         end

