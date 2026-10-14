; ---------------------------------------------------------------------------
; Light Dash (FeatureLightDash), ported from s1_improvements' "sub Light Dash.asm".
; In the air, A next to a chain of at least three uncollected rings dashes the
; main character (Sonic, or Tails in a Tails Alone game) from ring to ring.
; Without a chain, A does the normal air move (Homing Attack / Jump Dash, air
; roll, flight). The targets are the rings manager's Ring_Positions entries
; (status word, X, Y; sorted by X, ending with X = $FFFF); no ring objects.
; ---------------------------------------------------------------------------
LightDash_StartRadius = 64
LightDash_MaxGap = 72
LightDash_Speed = $C00
LightDash_WaterSpeed = $600
LightDash_ExitSpeed = LightDash_Speed
LightDash_WaterExitSpeed = LightDash_WaterSpeed
LightDash_Substeps = 8
LightDash_MaxFrames = 384
LightDash_StallFrames = 3

; ---------------------------------------------------------------------------
; Called first in the airborne modes. A failed search leaves the press for the
; normal air move; success skips the rest of the calling mode.
; ---------------------------------------------------------------------------
Player_LightDashStart:
	if FeatureLightDash=0
	rts					; Light Dash disabled
	endif
	tst.b	(LightDash_active).w
	bne.w	.return
	btst	#button_A,(Ctrl_1_Press_Logical).w
	beq.w	.return
	move.b	(Ctrl_1_Press_Logical).w,d0
	andi.b	#button_B_mask|button_C_mask,d0	; B or C with A: a Super combo or a jump button
	bne.w	.return
	btst	#status.player.in_air,status(a0)	; on the ground, A always jumps
	beq.w	.return
	bsr.w	LightDash_Allowed
	beq.w	.return
	cmpi.w	#90,invulnerable_time(a0)
	bhs.w	.return
	clr.l	(LightDash_exclude_first).w	; and LightDash_exclude_second
	clr.b	(LightDash_near_ground).w
	clr.b	(LightDash_have_last_ring).w
	clr.l	(LightDash_exit_x).w		; and LightDash_exit_y
	move.b	#1,(LightDash_initial_search).w
	move.w	x_pos(a0),(LightDash_probe_x).w
	move.w	y_pos(a0),(LightDash_probe_y).w
	move.w	#LightDash_StartRadius,d6
	bsr.w	LightDash_FindTarget
	clr.b	(LightDash_initial_search).w
	tst.w	d0
	beq.w	.return
	bsr.w	LightDash_SetTarget
	; Require three reachable, uncollected rings before taking A: preview the
	; next two links without collecting them.
	move.w	a2,(LightDash_exclude_first).w
	move.w	2(a2),(LightDash_probe_x).w
	move.w	4(a2),(LightDash_probe_y).w
	move.w	#LightDash_MaxGap,d6
	bsr.w	LightDash_FindTarget
	tst.w	d0
	beq.w	.noChain
	move.w	a2,(LightDash_exclude_second).w
	move.w	2(a2),(LightDash_probe_x).w
	move.w	4(a2),(LightDash_probe_y).w
	bsr.w	LightDash_FindTarget
	tst.w	d0
	beq.w	.noChain
	clr.l	(LightDash_exclude_first).w
	cmpi.b	#ObjID_Tails,id(a0)
	bne.s	+
	clr.b	flying(a0)			; the dash replaces flight
+
	move.b	#1,(LightDash_active).w
	move.w	(Current_ZoneAndAct).w,(LightDash_act).w
	move.w	#LightDash_MaxFrames,(LightDash_timer).w
	bset	#status.player.in_air,status(a0)
	bclr	#status.player.on_object,status(a0)
	bclr	#status.player.pushing,status(a0)
	bsr.w	LightDash_SetAnim
	clr.l	(LightDash_full_x).w		; and LightDash_full_y
	bclr	#button_A,(Ctrl_1_Press_Logical).w
	bsr.w	Player_LightDashUpdate
	addq.l	#4,sp				; skip the rest of the air mode
	rts
.noChain:
	clr.l	(LightDash_exclude_first).w
	clr.w	(LightDash_target).w
.return:
	rts

; ---------------------------------------------------------------------------
; Called every frame of the dash before the modes. Returns d0 = 1 if the frame
; was handled, 0 if normal physics may run instead.
; ---------------------------------------------------------------------------
Player_LightDashUpdate:
	movem.l	d1-d7/a1-a4,-(sp)
	bsr.w	LightDash_Allowed
	beq.w	.cancelBeforeMove
	move.w	(Current_ZoneAndAct).w,d0
	cmp.w	(LightDash_act).w,d0
	bne.w	.cancelBeforeMove
	btst	#status.player.pushing,status(a0)
	bne.w	.cancelBeforeMove
	; Solid objects run after the player: a cancelled velocity stops the next
	; dash frame (water's halving still allows it).
	move.w	(LightDash_full_x).w,d0
	bpl.s	+
	neg.w	d0
+
	cmpi.w	#$100,d0
	blo.s	.checkY
	tst.w	x_vel(a0)
	beq.w	.cancelBeforeMove
.checkY:
	btst	#status.player.in_air,status(a0)
	beq.s	.timer				; landing may have stopped the vertical speed
	move.w	(LightDash_full_y).w,d0
	bpl.s	+
	neg.w	d0
+
	cmpi.w	#$100,d0
	blo.s	.timer
	tst.w	y_vel(a0)
	beq.w	.cancelBeforeMove
.timer:
	subq.w	#1,(LightDash_timer).w
	bmi.w	.cancelBeforeMove
	movea.w	(LightDash_target).w,a4
	tst.w	(a4)
	bne.w	.nextTarget			; already collected the normal way
	bsr.w	LightDash_TargetDelta
	move.w	d1,d3
	muls.w	d3,d3
	move.w	d2,d4
	muls.w	d4,d4
	add.l	d4,d3
	move.w	#LightDash_Speed/256,d5
	btst	#status.player.underwater,status(a0)
	beq.s	+
	move.w	#LightDash_WaterSpeed/256,d5
+
	move.w	d5,d4
	muls.w	d4,d4
	cmp.l	d4,d3
	bhi.s	.fullSpeed
	lsl.w	#8,d1				; reach a near target exactly over the substeps
	lsl.w	#8,d2
	move.w	d1,(LightDash_full_x).w
	move.w	d2,(LightDash_full_y).w
	bra.s	.substeps
.fullSpeed:
	jsr	(CalcAngle).l
	jsr	(CalcSine).l
	muls.w	d5,d1
	muls.w	d5,d0
	move.w	d1,(LightDash_full_x).w
	move.w	d0,(LightDash_full_y).w
.substeps:
	move.b	#1,(LightDash_hitframe).w
	move.w	(LightDash_full_x).w,d0
	asr.w	#3,d0
	move.w	d0,(LightDash_step_x).w
	move.w	(LightDash_full_y).w,d0
	asr.w	#3,d0
	move.w	d0,(LightDash_step_y).w
	moveq	#LightDash_Substeps-1,d7
.step:
	move.w	(LightDash_step_x).w,x_vel(a0)
	move.w	(LightDash_step_y).w,y_vel(a0)
	move.l	d7,-(sp)
	jsr	(ObjectMove).l
	btst	#status.player.in_air,status(a0)
	bne.s	.airCollision
	tst.w	(LightDash_step_y).w
	bmi.s	.takeOff			; follow a rising chain back into the air
	move.w	(LightDash_step_x).w,inertia(a0)
	jsr	(AnglePos).l			; follow the ground and its collisions
	bra.s	.collisionDone
.takeOff:
	bset	#status.player.in_air,status(a0)
.airCollision:
	bsr.w	LightDash_LevelCollision	; walls, floor and ceiling in the air
.collisionDone:
	bsr.w	LightDash_LevelBound
	move.l	(sp)+,d7
	tst.b	(LightDash_active).w		; a death or an event may have cancelled it
	beq.w	.handled
	cmpi.b	#2,routine(a0)
	bne.w	.cancelAfterMove
	btst	#status.player.in_air,status(a0)
	beq.s	.groundContact
	move.w	(LightDash_step_x).w,d0
	cmp.w	x_vel(a0),d0
	bne.w	.cancelAfterMove
	move.w	(LightDash_step_y).w,d0
	cmp.w	y_vel(a0),d0
	bne.w	.cancelAfterMove
	bra.s	.stepDone
.groundContact:
	tst.w	(LightDash_step_x).w
	beq.s	.stepDone
	tst.w	x_vel(a0)
	beq.w	.cancelAfterMove		; a wall stopped the grounded dash
.stepDone:
	dbf	d7,.step
	move.w	(LightDash_full_x).w,x_vel(a0)
	btst	#status.player.in_air,status(a0)
	bne.s	.stillAirborne
	clr.w	y_vel(a0)
	move.w	x_vel(a0),inertia(a0)
	bra.s	.movementReady
.stillAirborne:
	move.w	(LightDash_full_y).w,y_vel(a0)
.movementReady:
	bsr.w	LightDash_SetAnim
	bsr.w	LightDash_TargetDelta
	; Touch_Rings' hitbox: 8 pixels either side and (y_radius - 3) above and
	; below, against the ring's 6-pixel radius.
	tst.w	d1
	bpl.s	+
	neg.w	d1
+
	cmpi.w	#8+6,d1
	bhi.s	.checkProgress
	tst.w	d2
	bpl.s	+
	neg.w	d2
+
	moveq	#0,d3
	move.b	y_radius(a0),d3
	addq.w	#3,d3
	cmp.w	d3,d2
	bhi.s	.checkProgress
	bsr.w	LightDash_CollectRing
	bra.s	.nextTarget
.checkProgress:
	move.w	x_pos(a0),d1
	cmp.w	(LightDash_last_x).w,d1
	bne.s	.progressed
	move.w	y_pos(a0),d1
	cmp.w	(LightDash_last_y).w,d1
	bne.s	.progressed
	addq.b	#1,(LightDash_stall).w
	cmpi.b	#LightDash_StallFrames,(LightDash_stall).w
	bhs.s	.cancelAfterMove		; really stopped by the level or an object
	bra.s	.handled
.progressed:
	move.w	x_pos(a0),(LightDash_last_x).w
	move.w	y_pos(a0),(LightDash_last_y).w
	clr.b	(LightDash_stall).w
	bra.s	.handled
.nextTarget:
	movea.w	(LightDash_target).w,a1
	move.w	2(a1),(LightDash_probe_x).w
	move.w	4(a1),(LightDash_probe_y).w
	bsr.w	LightDash_RecordRing
	clr.b	(LightDash_near_ground).w
	btst	#status.player.in_air,status(a0)
	beq.s	.nearGround
	jsr	(Sonic_CheckFloor).l		; also covers flying just above the ground
	cmpi.w	#12,d1
	bgt.s	.findNext
	cmpi.w	#-8,d1
	blt.s	.findNext
.nearGround:
	move.b	#1,(LightDash_near_ground).w
.findNext:
	move.w	#LightDash_MaxGap,d6
	bsr.w	LightDash_FindTarget
	tst.w	d0
	beq.s	.finishChain
	bsr.w	LightDash_SetTarget
	bra.s	.handled
.finishChain:
	bsr.w	Player_FinishLightDash
.handled:
	movem.l	(sp)+,d1-d7/a1-a4
	moveq	#1,d0
	rts
.cancelAfterMove:
	bsr.w	Player_CancelLightDash
	bra.s	.handled
.cancelBeforeMove:
	bsr.w	Player_CancelLightDash
	movem.l	(sp)+,d1-d7/a1-a4
	moveq	#0,d0
	rts

; ---------------------------------------------------------------------------
; Guards shared by the start and the dash. Returns Z=0 if the dash may run.
; ---------------------------------------------------------------------------
LightDash_Allowed:
	cmpa.w	#MainCharacter,a0		; only the player-controlled character
	bne.s	.deny
	cmpi.b	#2,routine(a0)
	bne.s	.deny
	move.b	(Game_Mode).w,d0
	andi.b	#$7F,d0
	cmpi.b	#GameModeID_Level,d0
	bne.s	.deny
	tst.w	(Demo_mode_flag).w
	bne.s	.deny
	tst.w	(Two_player_mode).w
	bne.s	.deny
	tst.w	(Debug_placement_mode).w
	bne.s	.deny
	tst.b	(Control_Locked).w
	bne.s	.deny
	tst.b	obj_control(a0)
	bne.s	.deny
	btst	#status_secondary.carry,status_secondary(a0)	; held by Tails
	bne.s	.deny
	andi	#~4,ccr				; Z=0
	rts
.deny:
	ori	#4,ccr				; Z=1
	rts

; ---------------------------------------------------------------------------
; d6 = search radius around the probe (the previous ring, or the player when
; starting). Returns d0.w = a2 = the closest uncollected Ring_Positions entry,
; or 0. Rings are sorted by X, so the scan stops past the radius.
; ---------------------------------------------------------------------------
LightDash_FindTarget:
	movem.l	d1-d5/d7/a1,-(sp)
	suba.l	a2,a2
	lea	(Ring_Positions+6).w,a1		; the first entry is left blank
	move.w	d6,d5
	muls.w	d5,d5
	addq.l	#1,d5
	move.w	#(Ring_Positions_End-Ring_Positions)/6-2,d7
.scan:
	cmpi.w	#$FFFF,2(a1)			; end of the list
	beq.w	.done
	move.w	2(a1),d1
	sub.w	(LightDash_probe_x).w,d1
	cmp.w	d6,d1
	bgt.w	.done
	move.w	d6,d0
	neg.w	d0
	cmp.w	d0,d1
	blt.w	.next
	tst.w	(a1)				; already collected?
	bne.w	.next
	cmpa.w	(LightDash_exclude_first).w,a1
	beq.w	.next
	cmpa.w	(LightDash_exclude_second).w,a1
	beq.w	.next
	tst.b	(LightDash_initial_search).w
	beq.s	.directionReady
	btst	#status.player.x_flip,status(a0)	; the first ring must be ahead
	bne.s	.facingLeft
	tst.w	d1
	bmi.w	.next
	bra.s	.directionReady
.facingLeft:
	tst.w	d1
	bgt.w	.next
.directionReady:
	move.w	4(a1),d2
	sub.w	(LightDash_probe_y).w,d2
	bsr.w	LightDash_WrapDeltaY
	cmp.w	d6,d2
	bgt.s	.next
	cmp.w	d0,d2
	blt.s	.next
	; Near the floor, do not turn back along the same row for a missed ring.
	tst.b	(LightDash_near_ground).w
	beq.s	.candidateReady
	move.w	d2,d4
	bpl.s	+
	neg.w	d4
+
	cmpi.w	#16,d4
	bhs.s	.candidateReady
	move.w	2(a1),d4
	btst	#status.player.x_flip,status(a0)
	bne.s	.candidateLeft
	cmp.w	x_pos(a0),d4
	blt.s	.next
	bra.s	.candidateReady
.candidateLeft:
	cmp.w	x_pos(a0),d4
	bgt.s	.next
.candidateReady:
	move.w	d1,d3
	muls.w	d3,d3
	move.w	d2,d4
	muls.w	d4,d4
	add.l	d4,d3
	cmp.l	d5,d3
	bhs.s	.next
	move.l	d3,d5
	movea.l	a1,a2
.next:
	addq.w	#6,a1
	dbf	d7,.scan
.done:
	move.w	a2,d0
	movem.l	(sp)+,d1-d5/d7/a1
	rts

LightDash_SetTarget:
	move.w	a2,(LightDash_target).w
	move.w	x_pos(a0),(LightDash_last_x).w
	move.w	y_pos(a0),(LightDash_last_y).w
	clr.b	(LightDash_stall).w
	rts

; Keep the latest ring-to-ring direction for a natural exit.
LightDash_RecordRing:
	tst.b	(LightDash_have_last_ring).w
	beq.s	.store
	move.w	(LightDash_probe_x).w,d1
	sub.w	(LightDash_last_ring_x).w,d1
	move.w	(LightDash_probe_y).w,d2
	sub.w	(LightDash_last_ring_y).w,d2
	bsr.w	LightDash_WrapDeltaY
	move.w	d1,d3
	or.w	d2,d3
	beq.s	.store				; coincident rings keep the last real direction
	jsr	(CalcAngle).l
	jsr	(CalcSine).l
	move.w	#LightDash_ExitSpeed/256,d5
	btst	#status.player.underwater,status(a0)
	beq.s	+
	move.w	#LightDash_WaterExitSpeed/256,d5
+
	muls.w	d5,d1
	muls.w	d5,d0
	move.w	d1,(LightDash_exit_x).w
	move.w	d0,(LightDash_exit_y).w
.store:
	move.w	(LightDash_probe_x).w,(LightDash_last_ring_x).w
	move.w	(LightDash_probe_y).w,(LightDash_last_ring_y).w
	move.b	#1,(LightDash_have_last_ring).w
	rts

; Collects the target ring the way Touch_Rings does (sparkle, count, lives, sound).
LightDash_CollectRing:
	movem.l	d0-d7/a1-a3,-(sp)
	movea.w	(LightDash_target).w,a1
	move.w	#$604,(a1)			; sparkle frame and timer
	jsr	(Touch_ConsumeRing).l
	lea	(Ring_consumption_table+2).w,a3
-	tst.w	(a3)+
	bne.s	-
	move.w	a1,-(a3)
	addq.w	#1,(Ring_consumption_table).w
	movem.l	(sp)+,d0-d7/a1-a3
	rts

; Natural end: hand the momentum to the normal ground or air physics.
Player_FinishLightDash:
	bsr.w	Player_CancelLightDash
	cmpi.b	#2,routine(a0)
	bne.s	.return
	tst.b	obj_control(a0)
	bne.s	.return
	move.w	(LightDash_exit_x).w,x_vel(a0)
	move.w	(LightDash_exit_y).w,y_vel(a0)
	btst	#status.player.in_air,status(a0)
	bne.s	.return				; in the air both components stay
	tst.w	y_vel(a0)
	bpl.s	.grounded
	bset	#status.player.in_air,status(a0)	; a rising last link lifts off
	bra.s	.return
.grounded:
	clr.w	y_vel(a0)
	move.w	x_vel(a0),inertia(a0)
.return:
	rts

; Returns d1/d2 = target - player (Y wrapped on vertically wrapping levels).
LightDash_TargetDelta:
	movea.w	(LightDash_target).w,a1
	move.w	2(a1),d1
	sub.w	x_pos(a0),d1
	move.w	4(a1),d2
	sub.w	y_pos(a0),d2
LightDash_WrapDeltaY:
	cmpi.w	#-$100,(Camera_Min_Y_pos).w	; vertical wrapping?
	bne.s	.return
	andi.w	#$7FF,d2
	cmpi.w	#$400,d2
	blo.s	.return
	subi.w	#$800,d2
.return:
	rts

; Character-specific helpers
LightDash_LevelCollision:
	cmpi.b	#ObjID_Tails,id(a0)
	beq.s	+
	jmp	(Sonic_DoLevelCollision).l
+	jmp	(Tails_DoLevelCollision).l

; The level bound routines drop their caller's return address and jump to
; KillCharacter at a bottomless pit. The extra bsr gives them one to drop, so
; both ways return to our caller.
LightDash_LevelBound:
	bsr.s	.call
	rts
.call:
	cmpi.b	#ObjID_Tails,id(a0)
	beq.s	+
	jmp	(Sonic_LevelBound).l
+	jmp	(Tails_LevelBound).l

LightDash_SetAnim:
	move.b	#AniIDSonAni_Float,anim(a0)	; Sonic: the floating pose, turned by Player_LightDashPose
	cmpi.b	#ObjID_Tails,id(a0)
	bne.s	+
	move.b	#AniIDTailsAni_Fly,anim(a0)	; Tails flies along the chain
+
	rts

; ---------------------------------------------------------------------------
; Display-only eight-way pose for Sonic, after his animation ran. The angle
; never goes into angle(a0), which belongs to the floor collision.
; ---------------------------------------------------------------------------
Player_LightDashPose:
	tst.b	(LightDash_active).w
	beq.s	.return
	cmpa.w	#MainCharacter,a0
	bne.s	.return
	cmpi.b	#ObjID_Sonic,id(a0)
	bne.s	.return
	cmpi.b	#AniIDSonAni_Float,anim(a0)
	bne.s	.return
	move.w	x_vel(a0),d1
	move.w	y_vel(a0),d2
	move.w	d1,d0
	or.w	d2,d0
	beq.s	.return
	jsr	(CalcAngle).l
	addi.b	#$10,d0
	lsr.b	#5,d0
	andi.w	#7,d0				; right, down-right, down, ..., up-right
	andi.b	#~(1<<render_flags.x_flip|1<<render_flags.y_flip),render_flags(a0)
	move.b	.flips(pc,d0.w),d1
	or.b	d1,render_flags(a0)
	add.w	d0,d0
	moveq	#1,d1
	and.b	anim_frame(a0),d1		; the floating pose's two-frame cadence
	add.w	d1,d0
	lea	.normalFrames(pc),a1
	tst.b	(Super_Sonic_flag).w
	beq.s	+
	lea	.superFrames(pc),a1
+
	move.b	(a1,d0.w),mapping_frame(a0)
.return:
	rts
.flips:
	dc.b	0, 3, 3, 3, 1, 0, 0, 0
; Running frames turned by 0, 45, 90 and 135 degrees: $2D, $31, $35, $39
.normalFrames:
	dc.b	$54,$59, $39,$3A, $35,$36, $31,$32
	dc.b	$54,$59, $39,$3A, $35,$36, $31,$32
.superFrames:
	dc.b	$B5,$B9, $B8,$BC, $B7,$BB, $B6,$BA
	dc.b	$B5,$B9, $B8,$BC, $B7,$BB, $B6,$BA
	even

; ---------------------------------------------------------------------------
; Ends the dash. A finished dash loses its pose; in the air the player falls
; uncurled, on the ground he keeps running.
; ---------------------------------------------------------------------------
Player_CancelLightDash:
	tst.b	(LightDash_active).w
	beq.w	.return
	clr.b	(LightDash_active).w
	clr.w	(LightDash_timer).w
	clr.w	(LightDash_target).w
	cmpi.b	#2,routine(a0)
	bne.w	.return
	tst.b	obj_control(a0)
	bne.w	.return
	cmpi.b	#AniIDSonAni_Float,anim(a0)
	beq.s	.dashPose
	cmpi.b	#ObjID_Tails,id(a0)
	bne.w	.return
	cmpi.b	#AniIDTailsAni_Fly,anim(a0)
	bne.w	.return
.dashPose:
	clr.w	y_vel(a0)			; never carry the dash lift into the fall
	btst	#status.player.in_air,status(a0)
	beq.s	.grounded
	bclr	#status.player.rolling,status(a0)
	beq.s	.restoreAnim
	cmpi.b	#$E,y_radius(a0)
	bne.s	.restoreSize
	subq.w	#5,y_pos(a0)
	cmpi.b	#ObjID_Tails,id(a0)
	bne.s	.restoreSize
	addq.w	#4,y_pos(a0)			; Tails is only 1 pixel taller standing
.restoreSize:
	move.b	#$13,y_radius(a0)
	move.b	#9,x_radius(a0)
	cmpi.b	#ObjID_Tails,id(a0)
	bne.s	.restoreAnim
	move.b	#$F,y_radius(a0)
	bra.s	.restoreAnim
.grounded:
	move.w	x_vel(a0),inertia(a0)		; keep running when the chain ends on land
.restoreAnim:
	move.b	#AniIDSonAni_Walk,anim(a0)
.return:
	rts

; ---------------------------------------------------------------------------
; Hooks for the rest of the game
; ---------------------------------------------------------------------------

; HurtCharacter/KillCharacter: a hit or a death ends the dash.
LightDash_PlayerHit:
	cmpa.w	#MainCharacter,a0
	bne.s	+
	clr.b	(LightDash_active).w
	clr.b	(LightDash_hitframe).w
+
	rts

; Touch_Enemy: Z=0 while the dash moved the main character this frame, so he
; attacks badniks (and is vulnerable again once it ends, unless curled).
LightDash_Attacking:
	cmpa.w	#MainCharacter,a0
	bne.s	.no
	tst.b	(LightDash_hitframe).w
	rts
.no:
	ori	#4,ccr				; Z=1
	rts
