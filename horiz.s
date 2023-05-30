
DEBUGHERE: Macro
        move.l  #0,-(sp)
        move.w  #0,-(sp)
        move.w  #5,-(sp)
        move.w #11,-(sp)   ; call hatari debugger (XBIOS Dbmsg)
        trap #14 ; xbios
        add.l   #10,sp

        EndM


        pea     0
        move.w  #$20,-(sp)    ; super
        trap    #1            ; gemdos
        addq.w  #2,sp

        clr.b   $ffff8260.w
        move.l  #screen,d0
        lsr.l   #8,d0
        addq.l  #1,d0
        lea     $ffff8200.w,a0
        movep.w d0,1(a0)
        lsl.l   #8,d0
        move.l  d0,logbase
        ; tell TOS also the new address
        move.w  #0,-(sp)      ; low rez
        move.l  d0,-(sp)      ; physbase=logbase
        move.l  d0,-(sp)      ; logbase
        move.w  #5,-(sp)      ; setscreen
        trap    #14           ; xbios
        lea     $C(sp),sp     ; Correct stack

        bclr  #0,$484.w   ; No clicks

; line-a init
        movem.l   D0-D2/A0-A2,-(A7)  ; Save registers
        dc.w      $A000              ; Line-A opcode
        move.l    A0,pParamblk       ; Pointer parameter block LINEA
        move.l    A1,pFnthdr         ; Pointer system fonts
        move.l    a2,pFktadr         ; Pointer start addr. Line-A routines
        movem.l   (a7)+,d0-d2/a0-a2  ; Restore registers

        move.w #8,d5    ; x start
        move.w #20,d6  ; x end
        move.w #%1111,d4   ; color
   move.l #$deadbeef,-(sp)
   pea lineaspeed(pc)
   bsr bintohex
   addq #8,sp


resetmain:
        pea     .message      ; string address
        move.w  #9,-(sp)      ; Cconws
        trap    #1            ; GEMDOS
        addq.l  #6,sp         ; Correct stack
        bra aftermessage
.message:
        dc.b 27,"E","Horizontal lines               v ^   < >",13,10
        dc.b        "Use cursor keys to change line len & pos",13,10
        dc.b 27,"c2","Line A "
lineaspeed:
        dc.b "        ",13,10
        dc.b 27,"c3","quick and dirty "
h1speed:
        dc.b "        ",13,10
        dc.b 27,"c1","quick "
h2speed:
        dc.b "        ",13,10
        dc.b 27,"c0",0
        even
aftermessage:
main:
        move.w #60,d7    ; y
        and.w #$f,d4    ; colors are sent from coords, but we need to clean them
        move.w  #$25,-(sp)    ; vsync
        trap    #14           ; xbios
        addq.w  #2,sp
        move.w  #$2700,sr
        move.w  #$00,$ffff8240.w
        move.w #2000,d0
.waitl:
        dbf d0,.waitl
   bsr startmeasure
        move.w  #$0700,$ffff8240.w
        bsr linealine
        move.w  #$007,$ffff8240.w
   bsr stopmeasure
   move.l d0,-(sp)
   pea lineaspeed(pc)
   bsr bintohex

        addq #8,d7
   bsr startmeasure
        move.w  #$070,$ffff8240.w
        bsr horizline1
        move.w  #$007,$ffff8240.w
   bsr stopmeasure
   move.l d0,-(sp)
   pea h1speed(pc)
   bsr bintohex


        addq #8,d7
   bsr startmeasure
        move.w  #$077,$ffff8240.w
        bsr horizline2
        move.w  #$007,$ffff8240.w
   bsr stopmeasure
   move.l d0,-(sp)
   pea h2speed(pc)
   bsr bintohex

;  addq #1,d6

   addq #8,sp
        ; handle keyboard
        bsr keymanager    ; register safe
        ;cmpi.b  #$39,$fffffc02.w
; empty GEM's keyboard buffer, usually not needed in a demo.
.read_key:      movem.l d0-d7/a0-a6,-(sp)
                move.w  #11,-(sp)                       ; Cconis()
                trap    #1
                addq.l  #2,sp

                tst.w   d0
                beq.b   .empty

                move.w  #8,-(sp)                        ; Cnecin()
                trap    #1
                addq.l  #2,sp
           ;     bra.b   .read_key

.empty:         
                movem.l (sp)+,d0-d7/a0-a6
        bra main
        bne   main
back:
        move.w  #$ffff,$ffff8240.w
        move.w  #0,-(sp) ; pterm0
        trap    #1      ; gemdos

keyroutines:    
  rts   ; required. scancodes start at 1, so this is executed for undefined keys (table entry is zero)
  ds.w 1-($1-$38)   ; nothing for 1-38
  dc.w back-keyroutines ; $39 (space)
  ds.w 1-($3a-$47)  ; nothing for 58-71
  dc.w do_cursor_up-keyroutines ; $48
  ds.w 1-($49-$4a)  ; nothing for $49-$4a
  dc.w do_cursor_left-keyroutines ; $4b
  ds.w 1-($4c-$4c)  ; nothing for $4c-4c i.e. 1
  dc.w do_cursor_right-keyroutines ; $4d
  ds.w 1-($4e-$4f)  ; nothing for $4e-$4f
  dc.w do_cursor_down-keyroutines ; $50
  ds.w 1-($51-$ff)  ; nothing else

do_cursor_up:
        addq #1,d6
        move d6,d4
        add d5,d4
        addq #4,sp   ; because not returning with rts
        bra resetmain
  rts
do_cursor_left:
        subq #1,d5
        move d6,d4
        add d5,d4
        addq #4,sp   ; because not returning with rts
        bra resetmain
do_cursor_right:
        addq #1,d5
        addq #4,sp   ; because not returning with rts
        bra resetmain
do_cursor_down:
        subq #1,d6
        addq #4,sp   ; because not returning with rts
        bra resetmain
  rts

  include "keyboard-big.s"




bintohex:
  ; call with:
  ; move.l d0,-(sp)
  ; pea destination(pc)
  ; bsr bintohex
  ; addq #8,sp
  ; converts to 8 chars written to memory (can be on odd boundary)
  movem.l d0/d1/d2/a6,-(sp)
  move.l 4*4+4(sp),a6
  move.l 4*4+8(sp),d0
  moveq #7,d2
.nextchar:
  rol.l #4,d0        ; rotate topmost nibble at bottom
  move.b d0,d1  ; low byte
  and.b #$0f,d1   ; mask nibble
  add.b #$30,d1   ; convert to number 
  cmp.b #$3a,d1   ; compare with >9
  blt .isdigit
.ischar:
  add.b #7,d1     ; make into char
.isdigit:
  move.b d1,(a6)+
  dbf d2,.nextchar
  movem.l (sp)+,d0/d1/d2/a6
  rts

startmeasure:
  ; start timer to measure execution speed
  ; timer delay:
  ; $1 $2  $3  $4  $5  $6   $7
  ; 4, 10, 16, 50, 64, 100, 200
;DATA set 2457600/FREQ/DELAYVAL
  clr.b $fffffa19.w   ; timera::TCR=0 (Stop)
  move.b  #255,$fffffa1f.w ; timera data
;  move.l  #timerAroutine,$134.w  ; install new Timer-A Vector
  bclr.b #5,$fffffa07.w   ; disable interrupt A (we only read the timer value)
  move.b #1,$fffffa19.w   ; timera start
  ; this is a 614400hz timer. So 1 value is about 13 cpu cycles (or 3 nops)
  rts

stopmeasure:
  ; stop time and return value in d0
  moveq #0,d0
  move.b $fffffa1f.w,d0
  sub.w #256,d0
  neg.w d0
  mulu #3,d0    ; convert from timer ticks to nops
  clr.b $fffffa19.w   ; timera::TCR=0 (Stop)
  rts

; all line routines take pixel coords d4=color (0-15) d5=x1, d6=x2, d7=y
linealine:
        movem.l   D0-D2/A0-A2,-(A7)  ; Save registers
        move.l    pParamblk,A0       ; Pointer parameter block LINEA
        move.w    d5,(38,A0)         ; First X-coordinate in LINEA.x1
        move.w    d7,(40,A0)         ; First Y-coordinate in LINEA.y1
        move.w    d6,(42,A0)         ; Second X-coordinate in LINEA.x2
        ; no idea how line-A does colors. Seems not to work reall as thought it will
        btst #0,d4
        seq d0
        ext.w d0
        move.w    d0,(24,A0)    ; Bit for first plane in LINEA.fg_bp_1
        btst #1,d4
        seq d0
        ext.w d0
        move.w    d0,(26,A0)    ; Bit for first plane in LINEA.fg_bp_2
        btst #2,d4
        seq d0
        ext.w d0
        move.w    d0,(28,A0)    ; Bit for first plane in LINEA.fg_bp_3
        btst #3,d4
        seq d0
        ext.w d0
        move.w    d0,(30,A0)    ; Bit for first plane in LINEA.fg_bp_4
        move.w    #1,(30,A0)    ; Bit for first plane in LINEA.fg_bp_4
        move.w    #0,(36,A0)      ; Writing mode in LINEA.wrt_mode  (0=replace)
        move.l    #patptr,(46,A0)     ; Line pattern in LINEA.patptr
        move.w    #0,(50,A0)     ; Number patterns in LINEA.patmsk
        move.w    #1,(52,A0)      ; Writing mode in LINEA.multifill (1=all planes)
        dc.w      $A004              ; Line-A opcode
        movem.l   (A7)+,D0-D2/A0-A2  ; Restore registers
        rts
; d4=color (0-15) d5=x1, d6=x2, d7=y
horizline1:    ; done the quick and dirty way
        movem.l d0-d7/a0-a2,-(sp)
        ; just draw left to right
        ; d5 has starting x
        ; isolate bottom 4 (16 pixel boundary)
        move.w d5,d2
        and.w #$f,d2   ; where in the word to start
        and.w #$fff0,d5 ; pixel0 = byte0, pixel16=byte8
        lsr #1,d5     ; go from mult16 to mult8
        ; now for y coord. Multiply starting coord by 160
        mulu.w #160,d7   ; note that in fullscreen, this may overflow! 273*408*4/8=55692, put screen address in middle?
        move.l logbase,a0
        lea (a0,d7),a0     ; here we are at the left screen border where the line goes 
        lea (a0,d5),a0     ; jump to the start word in the line
        ; how far to draw?
        move.w d6,d3
        and.w #$f,d3   ; where in the word to stop
        and.w #$fff0,d6 ; pixel0 = byte0, pixel16=byte8
        lsr #1,d6     ; go from mult16 to mult8    
        move.l logbase,a1
        lea (a1,d7),a1     ; here we end drawing
        lea (a1,d6),a1     ; jump to the start word in the line
        ; start pattern?
        ; from d2: $0 = 111...111 $e=%11 $f=%1
        ; how many words to draw?
        move.l a1,d0
        sub.l a0,d0
        lsr #3,d0
        ; get start pattern
        lea startpattern,a2
        add.w d2,d2
        move.w (a2,d2),d2
        ; get end pattern
        lea endpattern,a2
        add.w d3,d3
        move.w (a2,d3),d3

        ; from here on we don't need d5-d7 anymore
        ; so we can create plane pattern in d5-d6 for writing
        ; crude convert 4 bit color info into 4 words for screen layout (=> optimize with table)
        btst #1,d4   ; plane 1
        sne d5
        ext.w d5
        swap d5
        btst #0,d4   ; plane 0
        sne d5
        ext.w d5     ; d5 now contains plane 0&1
        btst #3,d4   ; plane 3
        sne d6
        ext.w d6
        swap d6
        btst #2,d4   ; plane 2
        sne d6
        ext.w d6    ; d6 now contains plane 2&3
        
        subq #1,d0
        blo.s .singlewordline
        ; left part of line: read from mem, mask and write back (could be done with longs, but yeah... later)
        ; how to write colors planes?
        ; read from screen
        ; mask away screen contents where line graphs going to be
        ; mask palette color to only the bits to write
        ; TODO: or palette color to screen data
        ; write screen data to memory
        move.w d2,d4      ; data in d4
        swap d2
        move.w d4,d2
        move.l d2,d4      ; data mask in d4
        not.l d2          ; negativemask in d2

        move.l (a0),d1    ; read current screen data (plane 0 & 1)
        and.l d2,d1       ; mask away to make room for new data
        move.l d5,d7      ; get color (0&1)
        and.l d4,d7       ; mask only 
        or.l d7,d1        ; write new data
        move.l d1,(a0)+   ; write out 

        move.l (a0),d1    ; read plane 2&3
        and.l d2,d1
        move.l d6,d7      ; get color (2&3)
        and.l d4,d7       ; mask only 
        or.l d7,d1
        move.l d1,(a0)+
;        move.w (a0),d1
;        and d2,d1
;        or d4,d1
;        move.w d1,(a0)+
;        move.w (a0),d1
;        and d2,d1
;        or d4,d1
;        move.w d1,(a0)+
        subq #1,d0
        blo.s .dualwordline    ; blo, ble? which one to use? Well I just tried and so it's blo. Gunstick coding, it's perfect!
.draw16loop:
        move.l d5,(a0)+     ; here we go fast. Can also be a jump into routine.
        move.l d6,(a0)+     ; and 16 routines for the 16 colors
        dbf d0,.draw16loop
.dualwordline:
        ; right part of line: read from mem, mask and write back (could be done with longs, but yeah... later)
        move.w d3,d2
        swap d2
        move.w d3,d2
        move.l d2,d3 ; data mask in d3
        not.l d2     ; negative mask in d2

        move.l (a0),d1  ; read plane 0&1
        and.l d2,d1     ; mask away
        move.l d5,d7    ; get color (0&1)
        and.l d3,d7     ; mask only
        or.l d7,d1      ; write new data
        move.l d1,(a0)+
        move.l (a0),d1
        and.l d2,d1
        move.l d6,d7    ; get color (2&3)
        and.l d3,d7
        or.l d7,d1
        move.l d1,(a0)+

;        move.w (a0),d1
;        and d2,d1
;        or d3,d1
;        move.w d1,(a0)+
;        move.w (a0),d1
;        and d2,d1
;        or d3,d1
;        move.w d1,(a0)+
.endline:
        movem.l (sp)+,d0-d7/a0-a2
        rts
.singlewordline:
        ; if start and end of line are in the same word
        and.w d3,d2   ; generate new line pattern
        move.w d2,d4
        swap d4
        move.w d2,d4
        move.l d4,d2
        not.l d2    ; mask

        move.l (a0),d1 
        and.l d2,d1
        move.l d5,d7    ; get color (0&1)
        and.l d3,d7
        or.l d7,d1
        move.l d1,(a0)+
        move.l (a0),d1
        and.l d2,d1
        move.l d6,d7    ; get color (2&3)
        and.l d3,d7
        or.l d7,d1
        move.l d1,(a0)+

;        move.w (a0),d1
;        and d2,d1
;        or d4,d1
;        move.w d1,(a0)+
;        move.w (a0),d1
;        and d2,d1
;        or d4,d1
;        move.w d1,(a0)+
        subq #1,d0    ; is that needed?
        bra.s .endline


; d4=color (0-15) d5=x1, d6=x2, d7=y
horizline2:
        ; a more optimized version 
        movem.l d0-d7/a0-a3,-(sp)
        ; just draw left to right
        ; d5 has starting x
        ; isolate bottom 4 (16 pixel boundary)
        moveq #$f,d1    ; for ANDing
        move.w d5,d2
        and.w d1,d2   ; where in the word to start
        and.w #$fff0,d5 ; pixel0 = byte0, pixel16=byte8
        lsr #1,d5     ; go from mult16 to mult8
        ; now for y coord. Multiply starting coord by 160
        ;mulu.w #160,d7   ; note that in fullscreen, this may overflow! 273*408*4/8=55692, put screen address in middle?
        ; n*160 = n*%1010000 = n*(128+32) = n*128+n*32 = n<<7 + n<<5
        lsl #5,d7    ; n*32
        move.w d7,d0
        add d7,d7    ;  
        add d7,d7    ; n*128 =n<<(5+2) 
        add d0,d7    ; n*128+n*32 = n*160
        move.l logbase,a0
        lea (a0,d7),a0     ; here we are at the left screen border where the line goes 
        lea (a0,d5),a0     ; jump to the start word in the line
        ; how far to draw?
        move.w d6,d3
        and.w d1,d3   ; where in the word to stop
        and.w #$fff0,d6 ; pixel0 = byte0, pixel16=byte8
        lsr #1,d6     ; go from mult16 to mult8    
        move.l logbase,a1
        lea (a1,d7),a1     ; here we end drawing
        lea (a1,d6),a1     ; jump to the start word in the line
        ; start pattern?
        ; from d2: $0 = 111...111 $e=%11 $f=%1
        ; how many words to draw?
        move.l a1,d0
        sub.l a0,d0
        lsr #3,d0
        ; get start pattern
        lea startpattern,a2
        add.w d2,d2
        move.w (a2,d2),d2
        ; get end pattern
        lea endpattern,a2
        add.w d3,d3
        move.w (a2,d3),d3

        ; from here on we don't need d5-d7 anymore
        ; so we can create plane pattern in d5-d6 for writing
        ; crude convert 4 bit color info into 4 words for screen layout (=> optimize with table)
        ; d4 contains the color index  xxxx3210
        ; we have to set d6=33332222 d5=11110000
    ; DEBUGHERE
        move.w d4,d5
        lsl #3,d5    ; table has 8 bytes per entry
        movem.l .colorplanes(pc,d5.w),d5-d6
        bra .aftcolpla
.colorplanes:
        dc.l $00000000,$00000000
        dc.l $0000ffff,$00000000
        dc.l $ffff0000,$00000000
        dc.l $ffffffff,$00000000
        dc.l $00000000,$0000ffff
        dc.l $0000ffff,$0000ffff
        dc.l $ffff0000,$0000ffff
        dc.l $ffffffff,$0000ffff
        dc.l $00000000,$ffff0000
        dc.l $0000ffff,$ffff0000
        dc.l $ffff0000,$ffff0000
        dc.l $ffffffff,$ffff0000
        dc.l $00000000,$ffffffff
        dc.l $0000ffff,$ffffffff
        dc.l $ffff0000,$ffffffff
        dc.l $ffffffff,$ffffffff

.aftcolpla:        
        subq #1,d0
        blo.s .singlewordline
        ; left part of line: read from mem, mask and write back 
        ; how to write colors planes?
        ; read from screen
        ; mask away screen contents where line graphs going to be
        ; mask palette color to only the bits to write
        ; TODO: or palette color to screen data
        ; write screen data to memory
        move.w d2,d4      ; data in d4
        swap d2
        move.w d4,d2
        move.l d2,d4      ; data mask in d4
        not.l d2          ; negativemask in d2

        move.l (a0),d1    ; read current screen data (plane 0 & 1)
        and.l d2,d1       ; mask away to make room for new data
        move.l d5,d7      ; get color (0&1)
        and.l d4,d7       ; mask only 
        or.l d7,d1        ; write new data
        move.l d1,(a0)+   ; write out 

        move.l (a0),d1    ; read plane 2&3
        and.l d2,d1
        move.l d6,d7      ; get color (2&3)
        and.l d4,d7       ; mask only 
        or.l d7,d1
        move.l d1,(a0)+
;        move.w (a0),d1
;        and d2,d1
;        or d4,d1
;        move.w d1,(a0)+
;        move.w (a0),d1
;        and d2,d1
;        or d4,d1
;        move.w d1,(a0)+
        subq #1,d0
        blo.s .dualwordline    ; blo, ble? which one to use? Well I just tried and so it's blo. Gunstick coding, it's perfect!
.draw16loop:
        move.l d5,(a0)+     ; here we go fast. Can also be a jump into routine.
        move.l d6,(a0)+     ; and 16 routines for the 16 colors
        dbf d0,.draw16loop
.dualwordline:
        ; right part of line: read from mem, mask and write back (could be done with longs, but yeah... later)
        move.w d3,d2
        swap d2
        move.w d3,d2
        move.l d2,d3 ; data mask in d3
        not.l d2     ; negative mask in d2

        move.l (a0),d1  ; read plane 0&1
        and.l d2,d1     ; mask away
        move.l d5,d7    ; get color (0&1)
        and.l d3,d7     ; mask only
        or.l d7,d1      ; write new data
        move.l d1,(a0)+
        move.l (a0),d1
        and.l d2,d1
        move.l d6,d7    ; get color (2&3)
        and.l d3,d7
        or.l d7,d1
        move.l d1,(a0)+

;        move.w (a0),d1
;        and d2,d1
;        or d3,d1
;        move.w d1,(a0)+
;        move.w (a0),d1
;        and d2,d1
;        or d3,d1
;        move.w d1,(a0)+
.endline:
        movem.l (sp)+,d0-d7/a0-a3
        rts
.singlewordline:
        ; if start and end of line are in the same word
        and.w d3,d2   ; generate new line pattern
        move.w d2,d4
        swap d4
        move.w d2,d4
        move.l d4,d2
        not.l d2    ; mask

        move.l (a0),d1 
        and.l d2,d1
        move.l d5,d7    ; get color (0&1)
        and.l d3,d7
        or.l d7,d1
        move.l d1,(a0)+
        move.l (a0),d1
        and.l d2,d1
        move.l d6,d7    ; get color (2&3)
        and.l d3,d7
        or.l d7,d1
        move.l d1,(a0)+

;        move.w (a0),d1
;        and d2,d1
;        or d4,d1
;        move.w d1,(a0)+
;        move.w (a0),d1
;        and d2,d1
;        or d4,d1
;        move.w d1,(a0)+
        subq #1,d0    ; is that needed?
        bra.s .endline



        data
logbase:dc.l 0
startpattern:
  ; convert start pixel to bitpattern
  dc.w %1111111111111111
  dc.w %0111111111111111
  dc.w %0011111111111111
  dc.w %0001111111111111
  dc.w %0000111111111111
  dc.w %0000011111111111
  dc.w %0000001111111111
  dc.w %0000000111111111
  dc.w %0000000011111111
  dc.w %0000000001111111
  dc.w %0000000000111111
  dc.w %0000000000011111
  dc.w %0000000000001111
  dc.w %0000000000000111
  dc.w %0000000000000011
  dc.w %0000000000000001
endpattern:
  dc.w %1000000000000000
  dc.w %1100000000000000
  dc.w %1110000000000000
  dc.w %1111000000000000
  dc.w %1111100000000000
  dc.w %1111110000000000
  dc.w %1111111000000000
  dc.w %1111111100000000
  dc.w %1111111110000000
  dc.w %1111111111000000
  dc.w %1111111111100000
  dc.w %1111111111110000
  dc.w %1111111111111000
  dc.w %1111111111111100
  dc.w %1111111111111110
  dc.w %1111111111111111

patptr:
        dc.l -1,-1,-1,-1,-1,-1,-1,-1
        bss
pParamblk:       ; Pointer parameter block LINEA
        ds.l 1
pFnthdr:         ; Pointer system fonts
        ds.l 1
pFktadr:         ; Pointer start addr. Line-A routines
        ds.l 1

screen:
        ds.l 10000
        end
