********************************************************************
* Boot - IDE Boot Module
*
* $Id$
*
* Edt/Rev  YYYY/MM/DD  Modified by
* Comment
* ------------------------------------------------------------------
*   ?      1994/06/25  Alan DeKok
* Diassembled.
*
*   6      1999/08/17  Paul T. Barton
* Redone for IDE.
*
*   7      2002/06/27  Boisy G. Pitre
* Added use of LSN bits 23-16.
*
*   7r1    2004/05/12  Boisy G. Pitre
* Optimized, made toG wait on !BUSY and DRDY, added slowdown POKE
* for Fujitsu 128MB CF (may be temporary)
*
*   8      2004/07/29  Boisy G. Pitre
* Now detects CHS/LBA mode to work with ALL IDE drives.
*
*   9      2005/10/13  Boisy G. Pitre
* Support for fragmented bootfiles added.

               NAM       Boot                
               TTL       IDE Boot Module     

               IFP1      
               USE       defsfile
               USE       ide.d
               ENDC      

tylg           SET       Systm+Objct
atrv           SET       ReEnt+rev
rev            SET       $00
edition        SET       9

* Disassembled 94/06/25 11:37:47 by Alan DeKok 
* ReDone by Paul T. Barton 99/08/17, for IDE 

               MOD       eom,name,tylg,atrv,start,size

* on-stack static storage
               ORG       0
cyls           RMB       2
sides          RMB       1
sects          RMB       2
mode           RMB       1
seglist        RMB       2                   pointer to segment list
blockloc       RMB       2                   pointer to memory requested
blockimg       RMB       2                   duplicate of the above
bootloc        RMB       3                   sector pointer; not byte pointer
bootsize       RMB       2                   size in bytes
LSN0Ptr        RMB       2                   LSN0 pointer (used by boot_common.asm)
size           EQU       .

name           FCS       /Boot/
               FCB       edition

* Common booter-required defines
LSN24BIT       EQU       1
FLOPPY         EQU       0

               USE       boot_common.asm

* HWInit - Initialize the device
*   Entry: Y = hardware address
*   Exit:  Carry Clear = OK, Set = Error
*          B = error (Carry Set)
HWInit         ldb       Address+2,pcr
               bne       slave@
               lda       #%10100000
               FCB       $8C
slave@         lda       #%10110000
               sta       mode,u
               stb       DevHead,y           select device
a@             tst       Status,y            wait for BSY to clear
               bmi       a@
               lda       #$EC
               sta       Command,y
b@             tst       Status,y
               bmi       b@
* Harvest C/H/S values.
               ldb       DataReg,y           ignore bytes 0-1
               ldb       DataReg,y           bytes 2-3 = no. of cylinders
               lda       Latch,y
               std       cyls,u              save cylinders in our private static area
               ldb       DataReg,y           ignore bytes 4-5
               ldb       DataReg,y           bytes 6-7 = no. of heads
               stb       sides,u             save sides on stack (B)
               ldb       DataReg,y           ignore bytes 8-9
               ldb       DataReg,y           ignore bytes 10-11
               ldb       DataReg,y           bytes 12-13 = no. of sectors/track
               lda       Latch,y
               std       sects,u             save sectors/track on stack (Y)
* Throw away the next 42 (48-7) words
               ldb       #43
l@             tst       DataReg,y
               lda       Latch,y
               decb      
               bne       l@
* A holds byte with LBA bit
               anda      #%00000010          LBA drive?
               beq       nope@
               ldb       mode,u
               orb       #%01000000
               stb       mode,u
nope@          ldb       #256-50
o@             tst       DataReg,y
               decb      
               bne       o@
HWTerm         clrb      
               rts       

* HWRead - Read a 256 byte sector from the device
*   Entry: Y = hardware address
*          B = bits 23-16 of LSN
*          X = bits 15-0  of LSN
*	   blockloc,u = ptr to 256 byte sector
*   Exit:  X = ptr to data (i.e. ptr in blockloc,u)
HWRead                   
               pshs      x,b
b@             tst       Status,y
               bmi       b@                  if =1 then loop 
               lda       mode,u
               sta       DevHead,y           0L0d/0hhh device=CHS 
r@             ldb       Status,y            is IDE ready for commands? 
               andb      #BusyBit+DrdyBit    ready ? 
               cmpb      #DrdyBit
               bne       r@                  loop until Drdy=1 and Busy=0
               ldb       #$01                only one at a time 
               stb       SectCnt,y           only one at a time 
               anda      #%01000000
               beq       chs@                branch if mode
               lda       ,s                  get bits 23-16
               sta       CylHigh,y
               ldd       1,s                 get bits 15-0
               stb       SectNum,y
               sta       CylLow,y
               bra       DoCmd
chs@                     
* Compute proper C:H:S value
               lda       sides,u             get device's head
               ldb       sects+1,u           and sector
               mul                           multiply H*S
* Note, there is a chance here that if the product is zero, we could loop forever
*         beq   ZeroProd
               pshs      d                   save product of H*S
               ldd       1+2,s               get bits 15-0 of LSN
               ldx       #-1                 start Y at -1
               inc       0+2,s               increment physical sector
* Here we are doing physLSN/(H*S) to get cylinder for physLSN
a@             leax      1,x                 increment count to compensate
               subd      ,s                  subtract (H*S) from physLSN
               bhs       a@                  if D>=0 then continue
               dec       0+2,s               decrement phys sector bits 23-16
               bne       a@                  if not zero, continue divide
               addd      ,s++                add in (H*S) to make non-negative
               pshs      d                   X now holds cylinder, save D on stack
               tfr       x,d
               exg       a,b                 swap
               std       CylLow,y            store computed cylinder in HW
               puls      d                   restore saved cylinder
* Now we will compute the sector/head value
               ldx       #-1
c@             leax      1,x
               subb      sects+1,u
               sbca      #0
               bcc       c@
               addb      sects+1,u
               incb                          add 1 to B, which is sector
               stb       SectNum,y           store computed sector in HW
               tfr       x,d
               orb       DevHead,y           OR in with value written earlier
               stb       DevHead,y
DoCmd          lda       #S$READ             read one sector 
               sta       Command,y           finish process 

Blk2           lda       Status,y            is IDE ready to send? 
               anda      #DrqBit             DRQ, data request 
               beq       Blk2                loop while DRQ =0 

               ldx       blockloc,u
               clr       ,s
BlkLp                    
               lda       DataReg,y           A <- IDE 
               ldb       Latch,y
               std       ,x++                into RAM 
               inc       ,s
               bpl       BlkLp               go get the rest 
b@             lda       DataReg,y           read remaining 256 bytes
               dec       ,s
               bne       b@

               leax      -256,x
               stx       1,s
               lda       Status,y            check for error-bit 
               clrb      
               puls      b,x,pc



* ------------------------------------------ 

*Init           
*         pshs  d,y
*         ldy   <Address,pcr
*         bsr   ChkBusy    could be spinning up... 
*         lda   #Diagnos   hits all drives 
*         sta   Command,y   ./ 
*         bsr   ChkBusy    wait 'til both done 
*         clrb             no errors 
*         puls  d,y,pc

* Entry: A = number to show
* Destroys D
*Num
* tfr a,b
* lsra
* lsra
* lsra
* lsra
* bsr  x@
* andb  #$0F
* tfr b,a
*x@
* adda  #'0
* cmpa  #'9
* ble   s@
* adda  #$7
*s@ jsr   <D.BtBug
* rts

               IFGT      Level-1
Pad            FILL      $39,$1D0-3-2-1-*
               ENDC      

Address        FDB       SDAddr
WhchDriv       FCB       0                   Drive to use (0 = master, 1 = slave)


               EMOD      
eom            EQU       *
               END       
