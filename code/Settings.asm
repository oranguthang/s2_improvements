; ---------------------------------------------------------------------------
; Settings SRAM (format 2), modelled on s1_improvements' "Settings SRAM.asm".
; Logical byte N sits at the odd address $200001+2*N (odd-byte backup RAM).
; 00..03 "S2DV", 04 version, 05 payload length, then Settings_Fields
; bytes and an additive big-endian checksum of all preceding bytes.
; Version 1 retains its fields and defaults SUPER MUSIC to ON.
; Only configuration is saved: emeralds, lives and progress are not.
; A write invalidates the signature first and commits its first byte last.
; ---------------------------------------------------------------------------
settings_sram_version = 2
settings_sram_payload = (Settings_Fields_End-Settings_Fields)/2
settings_sram_size = 6+settings_sram_payload+2

; ---------------------------------------------------------------------------
; Values used on a cold boot without a valid record
; ---------------------------------------------------------------------------
Settings_Defaults:
	clr.w	(Level_select_flag).w		; and Slow_motion_flag
	clr.b	(Debug_options_flag).w
	clr.b	(Cheat_all_emeralds).w
	move.b	#50,(Cheat_super_rings).w
	move.b	#1,(Cheat_ring_drain).w
	clr.b	(Cheat_god_mode).w
	move.b	#1,(Cheat_super_music).w
	clr.b	(Cheats_menu_row).w
	clr.w	(Player_option).w
	clr.w	(Two_player_items).w
	clr.w	(VS_countdown_option).w
	if FeatureKnuckles
	clr.b	(VS_player2).w
	endif
	rts

; ---------------------------------------------------------------------------
; Clamp each setting, then resolve the zero rings / drain constraint
; ---------------------------------------------------------------------------
Settings_Normalize:
	movem.l	d0-d1/a0-a1,-(sp)
	lea	Settings_BoolFields(pc),a0
	moveq	#(Settings_BoolFields_End-Settings_BoolFields)/2-1,d1
.bools:
	movea.w	(a0)+,a1
	cmpi.b	#1,(a1)
	bls.s	.nextbool
	clr.b	(a1)
.nextbool:
	dbf	d1,.bools
	move.b	(Level_select_flag).w,(Slow_motion_flag).w	; both come from the level select code
	cmpi.b	#1,(Cheat_ring_drain).w
	bls.s	.rings
	move.b	#1,(Cheat_ring_drain).w
.rings:
	move.b	(Cheat_super_rings).w,d0
	beq.s	.nodrain
	cmpi.b	#10,d0
	beq.s	.words
	cmpi.b	#50,d0
	beq.s	.words
	move.b	#50,(Cheat_super_rings).w
	bra.s	.words
.nodrain:
	clr.b	(Cheat_ring_drain).w		; nothing to drain without a ring cost
.words:
	clr.b	(Player_option).w		; the word options keep their value in the low byte
	clr.b	(Two_player_items).w
	clr.b	(VS_countdown_option).w
	cmpi.b	#PlayerOption_Count,(Player_option+1).w
	blo.s	+
	clr.b	(Player_option+1).w
+
	cmpi.b	#3,(Two_player_items+1).w	; all kinds, teleport only, normal, no items
	bls.s	+
	clr.b	(Two_player_items+1).w
+
	cmpi.b	#2,(VS_countdown_option+1).w
	bls.s	+
	clr.b	(VS_countdown_option+1).w
+
	if FeatureKnuckles
	cmpi.b	#VSPlayer2_Count,(VS_player2).w
	blo.s	+
	clr.b	(VS_player2).w
+
	endif
	movem.l	(sp)+,d0-d1/a0-a1
	rts

Settings_BoolFields:
	dc.w	Level_select_flag&$FFFF, Debug_options_flag&$FFFF
	dc.w	Cheat_all_emeralds&$FFFF, Cheat_god_mode&$FFFF, Cheat_super_music&$FFFF
Settings_BoolFields_End:

; RAM byte of each saved setting, in record order. Append new fields at the end
; and bump settings_sram_version; Settings_Load keeps older records' fields.
Settings_Fields:
	dc.w	Level_select_flag&$FFFF		; Level Select and CHEATS unlocked
	dc.w	Debug_options_flag&$FFFF	; DEBUG
	dc.w	Cheat_all_emeralds&$FFFF	; ALL EMERALDS
	dc.w	Cheat_super_rings&$FFFF		; SUPER RINGS
	dc.w	Cheat_ring_drain&$FFFF		; RING DRAIN
	dc.w	Cheat_god_mode&$FFFF		; GOD MODE
	dc.w	(Player_option+1)&$FFFF		; Options: player select
	dc.w	(Two_player_items+1)&$FFFF	; Options: VS items
	dc.w	(VS_countdown_option+1)&$FFFF	; Options: VS countdown
	if FeatureKnuckles
	dc.w	VS_player2&$FFFF		; Options: player 2's VS character
	endif
	dc.w	Cheat_super_music&$FFFF	; SUPER MUSIC
Settings_Fields_End:

; d0.w = sum of the bytes before the checksum at a0. Clobbers d1/a0.
Settings_Checksum:
	moveq	#0,d0
	moveq	#settings_sram_size-2-1,d1
Settings_ChecksumLength:
.loop:
	add.b	(a0)+,d0
	bcc.s	.next
	addi.w	#$100,d0			; carry from the low byte into the high byte
.next:
	dbf	d1,.loop
	rts

; ---------------------------------------------------------------------------
; Load the record into RAM, or the defaults if it is missing or invalid
; ---------------------------------------------------------------------------
Settings_Load:
	movem.l	d0-d2/a0-a2,-(sp)
	bsr.w	Settings_Defaults
	suba.w	#(settings_sram_size+1)&~1,sp
	lea	(SRAM_Start).l,a0
	movea.l	sp,a1
	moveq	#settings_sram_size-1,d1
	move.w	sr,-(sp)
	ori.w	#$700,sr			; no interrupts while the SRAM bank is selected
	move.b	#1,(HW_SRAM_Control).l
.read:
	move.b	(a0),(a1)+
	addq.l	#2,a0				; odd-byte SRAM bus
	dbf	d1,.read
	move.b	#0,(HW_SRAM_Control).l
	move.w	(sp)+,sr
	cmpi.l	#'S2DV',(sp)
	bne.s	.done
	moveq	#0,d2
	move.b	5(sp),d2
	cmpi.w	#(settings_sram_version<<8)|settings_sram_payload,4(sp)
	beq.s	.check
	cmpi.w	#(1<<8)|(settings_sram_payload-1),4(sp)
	bne.s	.done
.check:
	movea.l	sp,a0
	move.w	d2,d1
	addq.w	#5,d1
	moveq	#0,d0
	bsr.w	Settings_ChecksumLength
	lea	6(sp),a1
	adda.w	d2,a1
	cmp.b	1(a1),d0
	bne.s	.done
	lsr.w	#8,d0
	cmp.b	(a1),d0
	bne.s	.done
	lea	6(sp),a0
	lea	Settings_Fields(pc),a2
	move.w	d2,d1
	subq.w	#1,d1
.fields:
	movea.w	(a2)+,a1
	move.b	(a0)+,(a1)
	dbf	d1,.fields
.done:
	bsr.w	Settings_Normalize
	adda.w	#(settings_sram_size+1)&~1,sp
	movem.l	(sp)+,d0-d2/a0-a2
	rts

; ---------------------------------------------------------------------------
; Write the current settings to SRAM
; ---------------------------------------------------------------------------
Settings_Save:
	movem.l	d0-d2/a0-a2,-(sp)
	bsr.w	Settings_Normalize
	suba.w	#(settings_sram_size+1)&~1,sp
	move.l	#'S2DV',(sp)
	move.b	#settings_sram_version,4(sp)
	move.b	#settings_sram_payload,5(sp)
	lea	6(sp),a0
	lea	Settings_Fields(pc),a2
	moveq	#settings_sram_payload-1,d1
.fields:
	movea.w	(a2)+,a1
	move.b	(a1),(a0)+
	dbf	d1,.fields
	movea.l	sp,a0
	bsr.w	Settings_Checksum
	move.b	d0,settings_sram_size-1(sp)
	lsr.w	#8,d0
	move.b	d0,settings_sram_size-2(sp)
	lea	(SRAM_Start).l,a0
	movea.l	sp,a1
	moveq	#settings_sram_size-2,d1
	move.w	sr,-(sp)
	ori.w	#$700,sr
	move.b	#1,(HW_SRAM_Control).l
	clr.b	(a0)				; invalidate until every other byte is written
	addq.l	#1,a1
	addq.l	#2,a0
.write:
	move.b	(a1)+,(a0)
	addq.l	#2,a0
	dbf	d1,.write
	move.b	#'S',(SRAM_Start).l		; commit the record last
	move.b	#0,(HW_SRAM_Control).l
	move.w	(sp)+,sr
	adda.w	#(settings_sram_size+1)&~1,sp
	movem.l	(sp)+,d0-d2/a0-a2
	rts
Settings_End:
	if (Settings_End>=$200000)&(MOMPASS=1)
		fatal "The settings code must stay below the SRAM window at $200000."
	endif
