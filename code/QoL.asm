; ---------------------------------------------------------------------------
; Small quality-of-life features, each behind its Feature* switch.
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------
; FeatureExtraLives: a life for every 100 rings. Extra_life_flags(_2P) then
; counts the hundreds already rewarded; losing the rings clears it, so the
; next 100 rings give another life, as in s1_improvements.
; Returns Z=0 when a life is due (and counts it). No registers change.
; ---------------------------------------------------------------------------
ExtraLives_Check1P:
	movem.l	d0/a2/a4,-(sp)
	lea	(Ring_count).w,a2
	lea	(Extra_life_flags).w,a4
	bra.s	ExtraLives_Count

ExtraLives_Check2P:
	movem.l	d0/a2/a4,-(sp)
	lea	(Ring_count_2P).w,a2
	lea	(Extra_life_flags_2P).w,a4
	bra.s	ExtraLives_Count

; a2 = ring count, a4 = lives rewarded for rings
ExtraLives_Check:
	movem.l	d0/a2/a4,-(sp)
ExtraLives_Count:
	moveq	#0,d0
	move.w	(a2),d0
	divu.w	#100,d0
	cmp.b	(a4),d0				; more hundreds than lives given?
	bls.s	.none
	addq.b	#1,(a4)
	andi	#~4,ccr				; Z=0: give a life
	movem.l	(sp)+,d0/a2/a4			; (movem does not change the flags)
	rts
.none:
	ori	#4,ccr				; Z=1
	movem.l	(sp)+,d0/a2/a4
	rts

; ---------------------------------------------------------------------------
; FeatureInvincibilityFlash: the invincibility stars (Obj35) blink during the
; last two seconds, as in s1_improvements. d0 = display priority list.
; ---------------------------------------------------------------------------
InvStars_Display:
	movea.w	parent(a0),a1			; a1 = character
	cmpi.w	#2*60,invincibility_time(a1)
	bhi.s	.show
	btst	#2,(Level_frame_counter+1).w	; every star blinks together
	bne.s	.hide
.show:
	jmp	(DisplaySprite3).l
.hide:
	rts

; ---------------------------------------------------------------------------
; FeatureSpecialStageSelect: Left/Right on the SPECIAL STAGE item of the Level
; Select choose the stage (Current_Special_Stage, shown as 1-7 after the
; name). Called by LevSelControls_SwitchSide with a2 = the page; returns Z=0
; when the choice changed, so the column switch is skipped.
; ---------------------------------------------------------------------------
levsel_ss_number = planeLoc(40,36,$F)	; after "SPECIAL STAGE" on the stock page

LevelSelect_SpecialStageLR:
	movea.l	levselpage_order(a2),a0
	move.w	(Level_select_zone).w,d0
	add.w	d0,d0
	cmpi.w	#LevSelEntry_SpecialStage,(a0,d0.w)
	bne.s	.none
	move.b	(Ctrl_1_Press).w,d1
	andi.b	#button_left_mask|button_right_mask,d1
	beq.s	.none
	moveq	#0,d0
	move.b	(Current_Special_Stage).w,d0
	cmpi.b	#7,d0
	blo.s	+
	moveq	#0,d0
+
	btst	#button_left,d1
	beq.s	+
	subq.w	#1,d0
	bpl.s	+
	moveq	#7-1,d0
+
	btst	#button_right,d1
	beq.s	+
	addq.w	#1,d0
	cmpi.w	#7,d0
	blo.s	+
	moveq	#0,d0
+
	move.b	d0,(Current_Special_Stage).w
	bsr.s	LevelSelect_SpecialStageNumber
	andi	#~4,ccr				; Z=0
	rts
.none:
	ori	#4,ccr				; Z=1
	rts

; Writes the stage number into the page mappings in Chunk_Table; the item's
; highlight redraws it from there.
LevelSelect_SpecialStageNumber:
	moveq	#0,d0
	move.b	(Current_Special_Stage).w,d0
	cmpi.b	#7,d0
	blo.s	+
	moveq	#0,d0
+
	addi.w	#$10+1,d0			; menu font digits start at $10; stages count from 1
	move.w	d0,(Chunk_Table+levsel_ss_number).l
	rts

; ---------------------------------------------------------------------------
; FeatureCentiseconds: hundredths of a second after the 1P clock, after Selbi's
; "Add Centiseconds HUD" guide (as in s1_improvements). BuildHUD calls this
; every frame from the main loop; the two digits are DMA-queued from Art_Hud to
; the four free tiles after the horizontal scroll table (ArtTile_HUD_Centiseconds),
; which costs V-Int far less than writing them there (ARZ's demo lagged).
; ---------------------------------------------------------------------------
Hud_Centiseconds:
	moveq	#0,d0
	move.b	(Timer_frame).w,d0
	beq.s	.update				; always at 0, e.g. right after a restart
	cmp.b	(Hud_centiseconds_frame).w,d0
	beq.s	.return				; unchanged (paused or stopped)
.update:
	move.b	d0,(Hud_centiseconds_frame).w
	movem.l	d1-d4/a1,-(sp)
	add.w	d0,d0
	move.w	Hud_CentisecondsDigits(pc,d0.w),d4	; tens in the high byte, ones in the low byte
	moveq	#0,d1
	move.b	d4,d1				; ones digit art offset / 64
	lsr.w	#8,d4				; tens digit
	move.w	d1,-(sp)
	move.w	#tiles_to_bytes(ArtTile_HUD_Centiseconds),d2
	bsr.s	.digit
	move.w	(sp)+,d4
	move.w	#tiles_to_bytes(ArtTile_HUD_Centiseconds+2),d2
	bsr.s	.digit
	movem.l	(sp)+,d1-d4/a1
.return:
	rts
.digit:
	moveq	#0,d1
	move.w	d4,d1
	lsl.w	#6,d1				; two tiles per digit
	addi.l	#Art_Hud,d1
	move.w	#tiles_to_bytes(2)/2,d3		; length in words
	jmp	(QueueDMATransfer).l

; Tens and ones of the hundredths for each frame of a second (no division at run time)
Hud_CentisecondsDigits:
.frame := 0
	rept 60
.c := .frame*100/60
	dc.b	.c/10, .c-.c/10*10
.frame := .frame+1
	endm

; ---------------------------------------------------------------------------
; FeatureInfiniteLives: Z=0 when lives are infinite (1P games only; 2P VS
; games keep their lives). Only the flags change.
; ---------------------------------------------------------------------------
InfiniteLives_Active:
	if FeatureInfiniteLives
	tst.w	(Two_player_mode).w
	bne.s	.off
	andi	#~4,ccr				; Z=0
	rts
.off:
	endif
	ori	#4,ccr				; Z=1
	rts
