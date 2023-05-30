; if you want to read keyboard the TOS way, use CONIN (GEMDOS$01/GEMDOS$07/GEMDOS$08), RAWCONIO (GEMDOS$06),
; READLINE (GEMDOS$0A), CONSTAT (GEMDOS$0B), bconstat (BIOS$01), conin (BIOS$02), kbshift (BIOS$0B), iorec (XBIOS$0E)
  ;
  ; this is mainly for unsing in demos where OS is not available
  ; KEYBOARD ROUTINE using a table. max jump size +/-:32k i.e. put the routines near the table
  ; this does not account for layouts, scancodes are the key positions.
  ; table is 256 entries (512 bytes)
  ; more constant cpu time
  ; usage:
;  bsr keymanager    ; register safe
;keyroutines:    
;  anyrts   ; required. scancodes start at 1, so this is executed for undefined keys (table entry is zero)
;  ds.w 1-($1-$38)   ; nothing for 1-38
;  dc.w back-keyroutines ; $39 (space)
;  ds.w 1-($3a-$47)  ; nothing for 58-71
;  dc.w do_cursor_up-keyroutines ; $48
;  ds.w 1-($49-$4a)  ; nothing for $49-$4a
;  dc.w do_cursor_left-keyroutines ; $4b
;  ds.w 1-($4c-$4c)  ; nothing for $4c-4c i.e. 1
;  dc.w do_cursor_right-keyroutines ; $4d
;  ds.w 1-($4e-$4f)  ; nothing for $4e-$4f
;  dc.w do_cursor_down-keyroutines ; $50
;  ds.w 1-($51-$ff)  ; nothing else


keymanager:   
  move.l #.ret,-(sp)   ; rts from key routine uses this to jump back to .ret via rts
  clr.l -(sp)   ; placeholder for keyboard routine address
  movem.l d0/a0,-(sp)
  moveq #0,d0
  move.b $fffffc02.w,d0 ; read keyboard scancode
  ble .released    ; this was bmi, but also if 0 we should not jump, else jumpint to table+rts
  cmp.w prevkey,d0
  beq .no_repeat      ; don't repeat. Next code read is the release code, which resets the flag
  move.w d0,prevkey
  add.w d0,d0         ; word access
  lea keyroutines,a0  ; the offset table 
  ; ;below code can be put in a single instruction... watch this
  ; add.w d0,a0         ;4 add the key offset
  ; move.w (a0),d0      ;8 get the offset
  ; lea keyroutines,a0  ;8 offsets are calculated from here
  ; add.w d0,a0         ;8 W or L??? add routine offset to get the jump address
  add.w 0(a0,d0),a0   ;18 this does all of the above in one single instruciton. 68000 magic
;  move.l #.ret,12(sp)  ; return address from the indivisual keyboard routine
  move.l a0,8(sp)     ; jump address to the keyboard routine
  movem.l (sp)+,d0/a0  ; restore all registers (8 bytes)
  rts                 ; jump to the keyboard routine, which will end with rts and jump to .ret
;  jsr (a0)            ; if offset = 0, key not defined, so we jump to the table, that's why 1st entry has to be rts
.ret:
  rts    ; yes we could just jump direct to calling program, but this will make this even more unreadable
.no_repeat:
  movem.l (sp)+,d0/a0
  addq #8,sp   ; pop the unused placeholders
  rts
.released:
  move.b d0,prevkey
  bra.s .no_repeat
prevkey:
  dc.w 0
  even
