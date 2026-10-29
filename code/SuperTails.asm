; ---------------------------------------------------------------------------
; Super Tails (FeatureSuperTails), as in s1_improvements and Sonic 3 & Knuckles:
; in a Tails Alone game, with seven emeralds (or ALL EMERALDS) and enough rings
; (SUPER RINGS), A+B, A+C or B+C during a jump turns Tails Super; the same
; combo turns him back, also in flight. He keeps his normal sprites, plays S3K's transformation pose,
; and his fur cycles through S3K's yellow ramp. Super movement uses S3K's values
; for Tails (ApplySpeedSettings). No stars and no Flickies. Rings drain as for
; Super Sonic (RING DRAIN). It shares Super Sonic's state: Super_Sonic_flag,
; Super_Sonic_palette, Palette_timer/frame and Super_Sonic_frame_count.
; ---------------------------------------------------------------------------

; Z=0 when a0 is Tails as the player of a 1P game (Tails Alone)
SuperTails_Player:
	cmpa.w	#MainCharacter,a0
	bne.s	.no
	cmpi.b	#ObjID_Tails,id(a0)
	bne.s	.no
	tst.w	(Two_player_mode).w
	bne.s	.no
	tst.w	(Demo_mode_flag).w
	bne.s	.no
	andi	#~4,ccr				; Z=0
	rts
.no:
	ori	#4,ccr				; Z=1
	rts

; ---------------------------------------------------------------------------
; Called from Tails_JumpHeight (and from his flight: a flight started by the
; first button of the combo is cancelled). Returns Z=0 if Tails transformed
; or reverted, so the caller skips the rest of the jump/flight handling.
; ---------------------------------------------------------------------------
Tails_ToggleSuper:
	if FeatureSuperTails=0
	ori	#4,ccr
	rts
	endif
	bsr.s	SuperTails_Player
	beq.w	.none
	tst.b	(Control_Locked).w		; cutscenes
	bne.w	.none
	; While the lock bit is set, wait until the jump buttons are released.
	btst	#7,(SuperTails_combo_buttons).w
	beq.s	.checkTimer
	move.b	(Ctrl_1_Held_Logical).w,d0
	andi.b	#button_A_mask|button_B_mask|button_C_mask,d0
	bne.w	.none
	clr.w	(SuperTails_combo_timer).w	; and SuperTails_combo_buttons
	bra.w	.none
.checkTimer:
	tst.b	(SuperTails_combo_timer).w
	beq.s	.checkPress
	subq.b	#1,(SuperTails_combo_timer).w
	bne.s	.checkPress
	clr.b	(SuperTails_combo_buttons).w	; window expired
.checkPress:
	move.b	(Ctrl_1_Press_Logical).w,d0
	andi.b	#button_A_mask|button_B_mask|button_C_mask,d0
	beq.w	.none
	tst.b	flying(a0)			; later in a flight a combo only
	beq.s	.accumulate			; turns Super Tails back
	tst.b	(Super_Sonic_flag).w
	bne.s	.accumulate
	tst.b	(SuperTails_combo_timer).w
	beq.w	.none
.accumulate:
	move.b	(SuperTails_combo_buttons).w,d1
	andi.b	#button_A_mask|button_B_mask|button_C_mask,d1
	or.b	d0,d1
	move.b	d1,(SuperTails_combo_buttons).w
	move.b	#super_combo_window,(SuperTails_combo_timer).w
	move.b	d1,d2
	andi.b	#button_A_mask|button_B_mask,d2
	cmpi.b	#button_A_mask|button_B_mask,d2
	beq.s	.combo
	move.b	d1,d2
	andi.b	#button_A_mask|button_C_mask,d2
	cmpi.b	#button_A_mask|button_C_mask,d2
	beq.s	.combo
	andi.b	#button_B_mask|button_C_mask,d1
	cmpi.b	#button_B_mask|button_C_mask,d1
	bne.w	.none
.combo:
	clr.b	(SuperTails_combo_timer).w
	move.b	#$80,(SuperTails_combo_buttons).w	; lock until released
	tst.b	(Super_Sonic_flag).w
	bne.w	Tails_RevertToNormal_Combo
	jsr	(HasAllEmeralds).l
	bne.w	.none
	moveq	#0,d0
	move.b	(Cheat_super_rings).w,d0
	cmp.w	(Ring_count).w,d0
	bhi.w	.none
	tst.b	(Update_HUD_timer).w		; the act is over
	beq.w	.none
	; Transform: the S3K pose holds him while the palette fades in.
	clr.b	flying(a0)			; the first button may have started a flight
	bclr	#status.player.rolling,status(a0)
	move.b	#$F,y_radius(a0)
	move.b	#9,x_radius(a0)
	move.b	#1,(Super_Sonic_palette).w
	move.b	#$F,(Palette_timer).w
	move.w	#0,(Palette_frame).w
	move.b	#1,(Super_Sonic_flag).w
	move.w	#60,(Super_Sonic_frame_count).w
	move.b	#$81,obj_control(a0)
	move.b	#AniIDTailsAni_Transform,anim(a0)
	move.w	#0,invincibility_time(a0)
	bset	#status_secondary.invincible,status_secondary(a0)
	lea	(Tails_top_speed).w,a2
	jsr	(ApplySpeedSettings).l
	move.w	#SndID_SuperTransform,d0
	jsr	(PlaySound).l
	move.w	#MusID_SuperSonic,d0
	jsr	(PlayMusic).l
.done:
	andi	#~4,ccr				; Z=0
	rts
.none:
	ori	#4,ccr				; Z=1
	rts

Tails_RevertToNormal_Combo:
	if FeatureSuperToggle=0
	ori	#4,ccr				; only the ring count ends it
	rts
	endif
	bsr.s	Tails_RevertToNormal
	andi	#~4,ccr				; Z=0
	rts

; ---------------------------------------------------------------------------
; Every frame for Tails (Obj02 control): ring drain and the end of the act.
; ---------------------------------------------------------------------------
Tails_Super:
	if FeatureSuperTails=0
	rts
	endif
	tst.b	(Super_Sonic_flag).w
	beq.s	.return
	bsr.w	SuperTails_Player
	beq.s	.return
	cmpi.b	#1,(Super_Sonic_palette).w	; still transforming?
	beq.s	.return
	tst.b	(Update_HUD_timer).w
	beq.s	Tails_RevertToNormal
	subq.w	#1,(Super_Sonic_frame_count).w
	bhi.s	.return
	move.w	#60,(Super_Sonic_frame_count).w
	tst.b	(Cheat_ring_drain).w
	beq.s	.return
	tst.w	(Ring_count).w
	beq.s	Tails_RevertToNormal
	ori.b	#1,(Update_HUD_rings).w
	cmpi.w	#1,(Ring_count).w
	beq.s	+
	cmpi.w	#10,(Ring_count).w
	beq.s	+
	cmpi.w	#100,(Ring_count).w
	bne.s	++
+
	ori.b	#$80,(Update_HUD_rings).w
+
	subq.w	#1,(Ring_count).w
	beq.s	Tails_RevertToNormal
.return:
	rts

Tails_RevertToNormal:
	move.b	#0,obj_control(a0)
	jsr	(Super_RevertMusic).l
	move.b	#2,(Super_Sonic_palette).w	; fade the fur back
	move.w	#$28,(Palette_frame).w
	move.b	#0,(Super_Sonic_flag).w
	move.b	#AniIDSonAni_Run,prev_anim(a0)	; restart the animation
	move.w	#1,invincibility_time(a0)	; Obj02 ends the invincibility and resumes the music
	lea	(Tails_top_speed).w,a2
	jmp	(ApplySpeedSettings).l

; ---------------------------------------------------------------------------
; Turning back from Super: in a boss fight the boss's music plays again (the
; end of the invincibility, a frame later, leaves the music alone there).
; Elsewhere that end of invincibility plays the level's song. Used by Sonic,
; Knuckles and Tails.
; ---------------------------------------------------------------------------
Super_RevertMusic:
	jsr	(BossFightActive).l
	beq.s	.return
	move.w	#MusID_Boss,d0
	jmp	(PlayMusic).l
.return:
	rts

; ---------------------------------------------------------------------------
; The end of WFZ: the Tornado's jumps are timed for Sonic and Super Sonic, so
; Super Tails and Super Knuckles turn back before the cutscene (Super Tails
; would fly over the plane). a1 = the player.
; ---------------------------------------------------------------------------
Super_RevertForCutscene:
	tst.b	(Super_Sonic_flag).w
	beq.s	.return
	move.l	a0,-(sp)
	movea.l	a1,a0
	bsr.w	SuperTails_Player
	beq.s	.notTails
	bsr.w	Tails_RevertToNormal
	bra.s	.done
.notTails:
	tst.b	(Main_character).w
	beq.s	.done				; Super Sonic stays, as in the original
	jsr	(Sonic_RevertToNormal).l
.done:
	movea.l	a0,a1
	movea.l	(sp)+,a0
.return:
	rts

; ---------------------------------------------------------------------------
; Palette: called by PalCycle_SuperSonic when Tails is the player. Same states
; as Super Sonic's (1 = fade in, -1 = cycle, 2 = fade out); Tails' fur is in
; colours 11, 15 and 14 of the first palette line.
; ---------------------------------------------------------------------------
PalCycle_SuperTails:
	move.b	(Super_Sonic_palette).w,d0
	beq.w	.return
	bmi.w	.normal
	subq.b	#1,d0
	bne.w	.revert
	; fade in (S3K keeps his colours during the pose)
	subq.b	#1,(Palette_timer).w
	bpl.w	.return
	move.b	#3,(Palette_timer).w
	move.w	(Palette_frame).w,d0
	addq.w	#8,(Palette_frame).w
	cmpi.w	#$30,(Palette_frame).w
	blo.s	.copy
	move.b	#-1,(Super_Sonic_palette).w	; done
	move.b	#0,(MainCharacter+obj_control).w	; give Tails back his controls
	bra.s	.copy
.revert:
	subq.b	#1,(Palette_timer).w
	bpl.w	.return
	move.b	#3,(Palette_timer).w
	move.w	(Palette_frame).w,d0
	subq.w	#8,(Palette_frame).w
	bcc.s	.copy
	move.w	#0,(Palette_frame).w
	move.b	#0,(Super_Sonic_palette).w
	bra.s	.copy
.normal:
	; S3K's Super Tails cycle: six frames of twelve game frames each
	subq.b	#1,(Palette_timer).w
	bpl.w	.return
	move.b	#11,(Palette_timer).w
	move.w	(Palette_frame).w,d0
	addq.w	#8,(Palette_frame).w
	cmpi.w	#$58,(Palette_frame).w
	bls.s	.copy
	move.w	#$30,(Palette_frame).w
.copy:
	lea	PalCycle_SuperTails_Colours(pc),a0
	lea	(Normal_palette).w,a1
	move.w	(a0,d0.w),11*2(a1)
	move.w	2(a0,d0.w),15*2(a1)
	move.w	4(a0,d0.w),14*2(a1)
	if FeatureSuperTails
	tst.b	(Water_flag).w
	beq.s	.return
	; below the water line: the zone's tinted colours (tools/super_water.py),
	; written every frame so going in or out of the water changes nothing
	lea	PalCycle_SuperTails_CPZ(pc),a0
	cmpi.b	#chemical_plant_zone,(Current_Zone).w
	beq.s	.water
	lea	PalCycle_SuperTails_HPZ(pc),a0
	cmpi.b	#hidden_palace_zone,(Current_Zone).w
	beq.s	.water
	lea	PalCycle_SuperTails_ARZ(pc),a0
.water:
	lea	(Underwater_palette).w,a1
	move.w	(a0,d0.w),11*2(a1)
	move.w	2(a0,d0.w),15*2(a1)
	move.w	4(a0,d0.w),14*2(a1)
	endif
.return:
	rts

; colours 11, 15, 14 (and a pad word) per frame, from S3K's Super Tails cycle
; (s1_improvements' palette/Cycle - Super Tails.bin): six frames of normal
; colours for the pose, then the six-frame yellow cycle
PalCycle_SuperTails_Colours:
	rept 6
	dc.w	$046A, $008E, $00AE, 0
	endm
	dc.w	$046A, $008E, $00AE, 0
	dc.w	$046A, $02AE, $04CE, 0
	dc.w	$046C, $04CE, $08CE, 0
	dc.w	$048E, $08CE, $0AEE, 0
	dc.w	$046C, $04CE, $08CE, 0
	dc.w	$046A, $02AE, $04CE, 0
	if FeatureSuperTails
; the same frames below the water line (tools/super_water.py)
PalCycle_SuperTails_CPZ:	BINCLUDE	"art/palettes/Super Tails CPZ underwater.bin"
PalCycle_SuperTails_ARZ:	BINCLUDE	"art/palettes/Super Tails ARZ underwater.bin"
PalCycle_SuperTails_HPZ:	BINCLUDE	"art/palettes/Super Tails HPZ underwater.bin"
	endif
