; ---------------------------------------------------------------------------
; Knuckles' moves (FeatureKnuckles): gliding, sliding on the ground, climbing
; walls and onto ledges. The routines from Knuckles_MdAirGliding on are Knuckles
; in Sonic 2's (s2disasm knuckles-in-sonic-2, which took them from Sonic &
; Knuckles), with its fields renamed (glide_mode, glide_property), calls to
; Sonic's routines made long, and its glide collision using CalcAirQuadrant.
; Knuckles in Sonic 2 has no Grab, GlideLand or GroundSlide sounds; neither
; has this port.
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------
; Sonic_JumpHeight jumps here for Knuckles once the jump height is handled:
; a jump button press when he no longer rises fast starts a glide.
; ---------------------------------------------------------------------------
Knuckles_JumpHeight:
	jsr	(Sonic_RequestTailsAssist).l	; Up + jump calls Tails (Knuckles and Tails)
	tst.w	(Demo_mode_flag).w	; the title demos were recorded with Sonic
	bne.s	.return
	tst.b	glide_mode(a0)
	bne.s	.return
	move.w	#-$400,d1
	btst	#status.player.underwater,status(a0)
	beq.s	+
	move.w	#-$200,d1
+
	cmp.w	y_vel(a0),d1	; still rising faster than that?
	bgt.s	.return		; if yes, no glide yet
	move.b	(Ctrl_1_Press_Logical).w,d0
	andi.b	#button_A_mask|button_B_mask|button_C_mask,d0
	beq.s	.return
	tst.w	(Player_mode).w	; Knuckles and Tails?
	bne.s	Knuckles_BeginGlide
	tst.w	(Two_player_mode).w
	bne.s	Knuckles_BeginGlide
	btst	#button_up,(Ctrl_1_Held_Logical).w	; Up + jump calls Tails instead
	beq.s	Knuckles_BeginGlide
.return:
	rts

Knuckles_BeginGlide:
	bclr	#status.player.rolling,status(a0)
	move.b	#10,y_radius(a0)
	move.b	#10,x_radius(a0)
	bclr	#4,status(a0)		; the roll-jump bit (or the Homing Attack flag)
	move.b	#1,glide_mode(a0)
	addi.w	#$200,y_vel(a0)
	bpl.s	+
	move.w	#0,y_vel(a0)
+
	moveq	#0,d1
	move.w	#$400,d0
	move.w	d0,inertia(a0)
	btst	#status.player.x_flip,status(a0)
	beq.s	+
	neg.w	d0
	moveq	#-$80,d1
+
	move.w	d0,x_vel(a0)
	move.b	d1,glide_property(a0)
	move.w	#0,angle(a0)
	move.b	#0,(Gliding_collision_flags).w
	bset	#status.player.in_air,(Gliding_collision_flags).w
	bra.w	Knuckles_DoGlidingAnimation

; ---------------------------------------------------------------------------
; Sonic_ResetOnFloor_Part2 for Knuckles (Knuckles in Sonic 2): back to the
; standing size from whatever size he had, gliding included.
; ---------------------------------------------------------------------------
Knuckles_ResetOnFloor_Part2:
	move.b	y_radius(a0),d0
	move.b	#19,y_radius(a0)
	move.b	#9,x_radius(a0)
	btst	#status.player.rolling,status(a0)
	beq.s	+
	bclr	#status.player.rolling,status(a0)
	move.b	#AniIDSonAni_Walk,anim(a0)
	subi.b	#19,d0
	ext.w	d0
	add.w	d0,y_pos(a0)
+
	jmp	(Sonic_ResetOnFloor_Part3).l

; ---------------------------------------------------------------------------
; Z=0 if a0 is Knuckles gliding or sliding: both attack (Touch_Enemy,
; Touch_Monitor), as in Knuckles in Sonic 2.
; ---------------------------------------------------------------------------
Knuckles_GlideAttacking:
	cmpa.w	#MainCharacter,a0
	bne.s	.no
	tst.b	(Main_character).w
	beq.s	.no
	cmpi.b	#1,glide_mode(a0)
	beq.s	.yes
	cmpi.b	#3,glide_mode(a0)
	beq.s	.yes
.no:
	ori	#4,ccr		; Z=1
	rts
.yes:
	andi	#~4,ccr		; Z=0
	rts

; ---------------------------------------------------------------------------
; Wing Fortress Zone's ending (ObjB2), changed for Knuckles as in Knuckles in
; Sonic 2. a1 = MainCharacter.
; ---------------------------------------------------------------------------
; While he falls in, lock his controls; Z=1 while he is still in the air.
Knuckles_WFZWaitLeader:
	tst.b	(Main_character).w
	beq.s	.go
	cmpi.w	#$540,y_pos(a1)
	blo.s	.go
	st.b	(Control_Locked).w
	clr.w	(Ctrl_1).w
	clr.w	(Ctrl_1_Logical).w
	cmpi.w	#$5EC,y_pos(a1)
	blo.s	.go
	btst	#status.player.in_air,status(a1)
	beq.s	.go
	ori	#4,ccr		; Z=1: wait
	rts
.go:
	andi	#~4,ccr		; Z=0
	rts

; The jump to the Death Egg: press A once, then hold it (no glide).
Knuckles_WFZJumpButtons:
	move.w	#(button_A_mask<<8)|button_A_mask,d0
	tst.b	(Main_character).w
	beq.s	.set
	btst	#button_A,(Ctrl_1_Held_Logical).w	; already holding A?
	beq.s	.set
	move.w	#button_A_mask<<8,d0
.set:
	move.w	d0,(Ctrl_1_Logical).w
	rts

; Standing on the Tornado: restart his waiting animation and keep him still.
Knuckles_WFZWaitPose:
	tst.b	(Main_character).w
	beq.s	.return
	move.w	#(AniIDSonAni_Wait<<8)|AniIDSonAni_Walk,anim(a1)	; prev_anim differs: restart
	clr.w	x_vel(a1)
	clr.w	y_vel(a1)
.return:
	rts

; ---------------------------------------------------------------------------
; Z=0 if a2 is Knuckles sliding on the ground after a glide (Obj08's dust).
; ---------------------------------------------------------------------------
Knuckles_SlidingA2:
	cmpa.w	#MainCharacter,a2
	bne.s	.no
	tst.b	(Main_character).w
	beq.s	.no
	cmpi.b	#3,glide_mode(a2)
	bne.s	.no
	andi	#~4,ccr		; Z=0
	rts
.no:
	ori	#4,ccr		; Z=1
	rts

; ---------------------------------------------------------------------------
; Gimmicks that take hold of the player (springs, fans, wind tunnels) end
; Knuckles' glide or climb: a1 = the player.
; ---------------------------------------------------------------------------
Knuckles_StopGlide:
	cmpa.w	#MainCharacter,a1
	bne.s	.return
	tst.b	(Main_character).w
	beq.s	.return
	tst.b	glide_mode(a1)
	beq.s	.return
	clr.b	glide_mode(a1)
	clr.b	jumping(a1)
	move.b	#19,y_radius(a1)
	move.b	#9,x_radius(a1)
.return:
	rts

; ---------------------------------------------------------------------------
; Hitting an enemy that takes several hits ends a glide (Touch_Enemy_Part2).
; ---------------------------------------------------------------------------
Knuckles_GlideBounce:
	bsr.w	Knuckles_GlideAttacking
	beq.s	.return
	cmpi.b	#1,glide_mode(a0)
	bne.s	.return
	move.b	#2,glide_mode(a0)
	move.b	#AniIDKnuxAni_FallAfterGlide,anim(a0)
	bclr	#status.player.x_flip,status(a0)
	tst.w	x_vel(a0)
	bmi.s	+
	bset	#status.player.x_flip,status(a0)
+
	move.b	#19,y_radius(a0)
	move.b	#9,x_radius(a0)
.return:
	rts

; ===========================================================================
; From Knuckles in Sonic 2
; ===========================================================================
Knuckles_MdAirGliding:	; Obj01_MdAir jumps here while glide_mode is set
	bsr.w	Knuckles_GlideSpeedControl
	jsr	(Sonic_LevelBound).l
	jsr	(ObjectMove).l
	bsr.w	Knuckles_GlideControl

return_3156B8:
	rts


; =============== S U B	R O U T	I N E =======================================


Knuckles_GlideControl:
	move.b	glide_mode(a0),d0
	beq.s	return_3156B8
	cmpi.b	#2,d0
	beq.w	Knuckles_FallingFromGlide
	cmpi.b	#3,d0
	beq.w	Knuckles_Sliding
	cmpi.b	#4,d0
	beq.w	Knuckles_Climbing_Wall
	cmpi.b	#5,d0
	beq.w	Knuckles_Climbing_Onto_Ledge

;Knuckles_NormalGlide:
	; These two lines are not here in S3K.
	move.b	#10,y_radius(a0)
	move.b	#10,x_radius(a0)

	; This function updates 'Gliding_collision_flags'.
	bsr.w	Knuckles_DoLevelCollision2

	btst	#status.player.pushing,(Gliding_collision_flags).w
	bne.w	Knuckles_BeginClimb

	; These two lines are not here in S3K.
	move.b	#19,y_radius(a0)
	move.b	#9,x_radius(a0)

	btst	#status.player.in_air,(Gliding_collision_flags).w
	beq.s	Knuckles_BeginSlide

	move.b	(Ctrl_1_Held_Logical).w,d0
	andi.b	#button_A_mask|button_B_mask|button_C_mask,d0
	bne.s	.continueGliding

	; The player has let go of the jump button, so exit the gliding state
	; and enter the falling state.
	move.b	#2,glide_mode(a0)
	move.b	#AniIDKnuxAni_FallAfterGlide,anim(a0)
	bclr	#status.player.x_flip,status(a0)
	tst.w	x_vel(a0)
	bpl.s	+
	bset	#status.player.x_flip,status(a0)
+
	; Divide Knuckles' X velocity by 4.
	asr.w	x_vel(a0)
	asr.w	x_vel(a0)

	move.b	#19,y_radius(a0)
	move.b	#9,x_radius(a0)

	rts
; ---------------------------------------------------------------------------

.continueGliding:
	bra.w	Knuckles_DoGlidingAnimation
; ---------------------------------------------------------------------------

Knuckles_BeginSlide:
	bclr	#status.player.x_flip,status(a0)
	tst.w	x_vel(a0)
	bpl.s	+
	bset	#status.player.x_flip,status(a0)
+
	move.b	angle(a0),d0
	addi.b	#$20,d0
	andi.b	#$C0,d0
	beq.s	loc_315780

	move.w	inertia(a0),x_vel(a0)
	move.w	#0,y_vel(a0)

	jmp	(Sonic_ResetOnFloor_Part2).l
; ---------------------------------------------------------------------------

loc_315780:
	move.b	#3,glide_mode(a0)
	move.b	#$CC,mapping_frame(a0)
	move.b	#$7F,anim_frame_duration(a0)
	move.b	#0,anim_frame(a0)

	; The drowning countdown uses the dust clouds' VRAM, so don't create
	; dust if Knuckles is drowning.
	cmpi.b	#12,air_left(a0)
	blo.s	+
	; Create dust clouds.
	move.b	#6,(Sonic_Dust+routine).w
	move.b	#$15,(Sonic_Dust+mapping_frame).w
+
	rts
; ---------------------------------------------------------------------------

Knuckles_BeginClimb:
	tst.b	(Disable_wall_grab).w
	bmi.w	.fail

	move.b	lrb_solid_bit(a0),d5
	move.b	glide_property(a0),d0
	addi.b	#$40,d0
	bpl.s	.right

;.left:
	bset	#status.player.x_flip,status(a0)

	jsr	(CheckLeftCeilingDist).l
	or.w	d0,d1
	bne.s	.checkFloorLeft

	addq.w	#1,x_pos(a0)
	bra.s	.success

.right:
	bclr	#status.player.x_flip,status(a0)

	jsr	(CheckRightCeilingDist).l
	or.w	d0,d1
	bne.w	.checkFloorRight
; loc_3157E8:
.success:
	; These two lines aren't here in S3K.
	move.b	#19,y_radius(a0)
	move.b	#9,x_radius(a0)

	; This sound does not exist in Sonic 2, so the code to play it was
	; removed.
	;moveq	#signextendB(sfx_Grab),d0

	; If Hyper Knuckles glides into a wall at a high-enough
	; speed, then make the screen shake and harm all enemies
	; on-screen.
	; This code is leftover and useless in KiS2.
	tst.b	(Super_Sonic_flag).w
	beq.s	.noQuake

	cmpi.w	#$480,inertia(a0)
	blo.s	.noQuake

	nop
	; This is the code that replaced the above 'nop' in S3K.
	;move.w	#$14,(Glide_screen_shake).w
	;bsr.w	HyperAttackTouchResponse
	;moveq	#signextendB(sfx_Thump),d0

.noQuake:
	;jsr	(PlaySound).l
	move.w	#0,inertia(a0)
	move.w	#0,x_vel(a0)
	move.w	#0,y_vel(a0)
	move.b	#4,glide_mode(a0)
	move.b	#$B7,mapping_frame(a0)
	move.b	#$7F,anim_frame_duration(a0)
	move.b	#0,anim_frame(a0)
	move.b	#3,glide_property(a0)
	; 'x_sub' holds the X coordinate that Knuckles was at when he first
	; latched onto the wall.
	move.w	x_pos(a0),x_sub(a0)
	rts
; ---------------------------------------------------------------------------

.checkFloorLeft:
	; This adds the Y radius to the X coordinate...
	; This appears to be a bug, but, luckily, the X and Y radius are both
	; 10, so this is harmless.
	move.w	x_pos(a0),d3
	move.b	y_radius(a0),d0
	ext.w	d0
	sub.w	d0,d3
	subq.w	#1,d3
; loc_31584A:
.checkFloorCommon:
	move.w	y_pos(a0),d2
	subi.w	#11,d2
	jsr	(ChkFloorEdge_Part3).l

	tst.w	d1
	bmi.s	.fail
	cmpi.w	#12,d1
	bhs.s	.fail
	add.w	d1,y_pos(a0)
	bra.w	.success
; ---------------------------------------------------------------------------
; loc_31586A:
.checkFloorRight:
	; This adds the Y radius to the X coordinate...
	; This appears to be a bug, but, luckily, the X and Y radius are both
	; 10, so this is harmless.
	move.w	x_pos(a0),d3
	move.b	y_radius(a0),d0
	ext.w	d0
	add.w	d0,d3
	addq.w	#1,d3
	bra.s	.checkFloorCommon
; ---------------------------------------------------------------------------
; loc_31587A:
.fail:
	move.b	#2,glide_mode(a0)
	move.b	#AniIDKnuxAni_FallAfterGlide,anim(a0)
	move.b	#19,y_radius(a0)
	move.b	#9,x_radius(a0)
	bset	#status.player.in_air,(Gliding_collision_flags).w
	rts
; ---------------------------------------------------------------------------

Knuckles_FallingFromGlide:
	jsr	(Sonic_ChgJumpDir).l

	; Apply gravity.
	addi.w	#$38,y_vel(a0)

	; Fall slower when underwater.
	btst	#status.player.underwater,status(a0)
	beq.s	+
	subi.w	#$28,y_vel(a0)
+
	; This function updates 'Gliding_collision_flags'.
	bsr.w	Knuckles_DoLevelCollision2

	btst	#status.player.in_air,(Gliding_collision_flags).w
	bne.s	.return

	; Knuckles has touched the ground.
	move.w	#0,inertia(a0)
	move.w	#0,x_vel(a0)
	move.w	#0,y_vel(a0)

	move.b	y_radius(a0),d0
	subi.b	#19,d0
	ext.w	d0
	add.w	d0,y_pos(a0)

	; This sound does not exist in Sonic 2, so the code to play it was
	; removed.
	;moveq	#signextendB(sfx_GlideLand),d0
	;jsr	(PlaySound).l

	move.b	angle(a0),d0
	addi.b	#$20,d0
	andi.b	#$C0,d0
	beq.s	+
	jmp	(Sonic_ResetOnFloor_Part2).l
+
	jsr	(Sonic_ResetOnFloor_Part2).l
	move.w	#$F,move_lock(a0)
	move.b	#AniIDKnuxAni_LandAfterGlide,anim(a0)
; return_315900:
.return:
	rts
; ---------------------------------------------------------------------------

Knuckles_Sliding:
	move.b	(Ctrl_1_Held_Logical).w,d0
	andi.b	#button_A_mask|button_B_mask|button_C_mask,d0
	beq.s	.getUp

	tst.w	x_vel(a0)
	bpl.s	.goingRight

;.goingLeft:
	addi.w	#$20,x_vel(a0)
	bmi.s	.continueSliding2

	bra.s	.getUp
; ---------------------------------------------------------------------------
; loc_31591C:
.continueSliding2:
	bra.s	.continueSliding
; ---------------------------------------------------------------------------
; loc_31591E:
.goingRight:
	subi.w	#$20,x_vel(a0)
	bpl.s	.continueSliding
; loc_315926:
.getUp:
	move.w	#0,inertia(a0)
	move.w	#0,x_vel(a0)
	move.w	#0,y_vel(a0)

	move.b	y_radius(a0),d0
	subi.b	#19,d0
	ext.w	d0
	add.w	d0,y_pos(a0)

	jsr	(Sonic_ResetOnFloor_Part2).l

	move.w	#$F,move_lock(a0)
	move.b	#AniIDKnuxAni_ClimbLedge,anim(a0)

	rts
; ---------------------------------------------------------------------------
; loc_315958:
.continueSliding:
	; These two lines aren't here in S3K.
	move.b	#10,y_radius(a0)
	move.b	#10,x_radius(a0)

	bsr.w	Knuckles_DoLevelCollision2

	; Get distance from floor in 'd1', and angle of floor in 'd3'.
	jsr	(Sonic_CheckFloor).l

	; If the distance from the floor is suddenly really high, then
	; Knuckles must have slid off a ledge, so make him enter his falling
	; state.
	cmpi.w	#14,d1
	bge.s	.fall

	add.w	d1,y_pos(a0)
	move.b	d3,angle(a0)

	move.b	#19,y_radius(a0)
	move.b	#9,x_radius(a0)

	; This sound does not exist in Sonic 2, so the code to play it was
	; removed.
	; Play the sliding sound every 8 frames.
;	move.b	(Vint_runcount+3).w,d0
;	andi.b	#7,d0
;	bne.s	+

;	moveq	#signextendB(sfx_GroundSlide),d0
;	jsr	(PlaySound).l
;+
	rts
; ---------------------------------------------------------------------------
; loc_315988:
.fall:
	move.b	#2,glide_mode(a0)
	move.b	#AniIDKnuxAni_FallAfterGlide,anim(a0)

	move.b	#19,y_radius(a0)
	move.b	#9,x_radius(a0)

	bset	#status.player.in_air,(Gliding_collision_flags).w
	rts
; ---------------------------------------------------------------------------

Knuckles_Climbing_Wall:
	tst.b	(Disable_wall_grab).w
	bmi.w	Knuckles_LetGoOfWall

	; If Knuckles' X coordinate is no longer the same as when he first
	; latched onto the wall, then detach him from the wall. This is
	; probably intended to detach Knuckles from the wall if something
	; physically pushes him away from it.
	move.w	x_pos(a0),d0
	cmp.w	x_sub(a0),d0
	bne.w	Knuckles_LetGoOfWall

	; If an object is now carrying Knuckles, then detach him from the
	; wall.
	btst	#status.player.on_object,status(a0)
	bne.w	Knuckles_LetGoOfWall

	move.w	#0,inertia(a0)
	move.w	#0,x_vel(a0)
	move.w	#0,y_vel(a0)

	move.l	#Primary_Collision,(Collision_addr).w
	cmpi.b	#$D,lrb_solid_bit(a0)
	beq.s	+
	move.l	#Secondary_Collision,(Collision_addr).w
+
	move.b	lrb_solid_bit(a0),d5

	; These two lines aren't in S3K.
	move.b	#10,y_radius(a0)
	move.b	#10,x_radius(a0)

	moveq	#0,d1	; Climbing animation delta: make the animation pause.

	btst	#button_up,(Ctrl_1_Held_Logical).w
	beq.w	.notClimbingUp

;.climbingUp:
	; Get Knuckles' distance from the wall in 'd1'.
	move.w	y_pos(a0),d2
	subi.w	#11,d2
	bsr.w	GetDistanceFromWall

	; If the wall is far away from Knuckles, then we must have reached a
	; ledge, so make Knuckles climb up onto it.
	cmpi.w	#4,d1
	bge.w	Knuckles_ClimbUp

	; If Knuckles has encountered a small dip in the wall, then make him
	; stop.
	tst.w	d1
	bne.w	.notMoving

	; Get Knuckles' distance from the ceiling in 'd1'.
	move.b	lrb_solid_bit(a0),d5
	move.w	y_pos(a0),d2
	subq.w	#8,d2
	move.w	x_pos(a0),d3
	bsr.w	CheckCeilingDist_WithRadius

	; Check if Knuckles has room above him.
	tst.w	d1
	bpl.s	.moveUp

	; Knuckles is bumping into the ceiling, so push him out.
	sub.w	d1,y_pos(a0)

	moveq	#1,d1	; Climbing animation delta: make the animation play forwards.
	bra.w	.finishMoving
; ---------------------------------------------------------------------------
; loc_315A46:
.moveUp:
	subq.w	#1,y_pos(a0)

	; Super Knuckles and Hyper Knuckles climb walls faster.
	tst.b	(Super_Sonic_flag).w
	beq.s	+
	subq.w	#1,y_pos(a0)
+
	moveq	#1,d1	; Climbing animation delta: make the animation play forwards.

	; Don't let Knuckles climb through the level's upper boundary.
	move.w	(Camera_Min_Y_pos).w,d0

	; If the level wraps vertically, then don't bother with any of this.
	cmpi.w	#-$100,d0
	beq.w	.finishMoving

	; Check if Knuckles is over the level's top boundary.
	addi.w	#16,d0
	cmp.w	y_pos(a0),d0
	ble.w	.finishMoving

	; Knuckles is climbing over the level's top boundary: push him back
	; down.
	move.w	d0,y_pos(a0)
	bra.w	.finishMoving
; ---------------------------------------------------------------------------
; loc_315A76:
.notClimbingUp:
	btst	#button_down,(Ctrl_1_Held_Logical).w
	beq.w	.finishMoving

;.climbingDown:
	; ...I'm not sure what this code is for.
	cmpi.b	#$BD,mapping_frame(a0)
	bne.s	+
	move.b	#$B7,mapping_frame(a0)
	addq.w	#3,y_pos(a0)
	subq.w	#3,x_pos(a0)
	btst	#status.player.x_flip,status(a0)
	beq.s	+
	addq.w	#3*2,x_pos(a0)
+
	; Get Knuckles' distance from the wall in 'd1'.
	move.w	y_pos(a0),d2
	addi.w	#11,d2
	bsr.w	GetDistanceFromWall

	; If Knuckles is no longer against the wall (he has climbed off the
	; bottom of it) then make him let go.
	tst.w	d1
	bne.w	Knuckles_LetGoOfWall

	; Get Knuckles' distance from the floor in 'd1'.
	move.b	top_solid_bit(a0),d5
	move.w	y_pos(a0),d2
	addi.w	#9,d2
	move.w	x_pos(a0),d3
	bsr.w	CheckFloorDist_WithRadius

	; Check if Knuckles has room below him.
	tst.w	d1
	bpl.s	.moveDown

	; Knuckles has reached the floor.
	add.w	d1,y_pos(a0)
	move.b	(Primary_Angle).w,angle(a0)

	move.w	#0,inertia(a0)
	move.w	#0,x_vel(a0)
	move.w	#0,y_vel(a0)

	jsr	(Sonic_ResetOnFloor_Part2).l

	move.b	#AniIDSonAni_Wait,anim(a0)

	rts
; ---------------------------------------------------------------------------
; loc_315AF4:
.moveDown:
	addq.w	#1,y_pos(a0)

	; Super Knuckles and Hyper Knuckles climb walls faster.
	tst.b	(Super_Sonic_flag).w
	beq.s	+
	addq.w	#1,y_pos(a0)
+
	moveq	#-1,d1	; Climbing animation delta: make the animation play backwards.

; loc_315B04:
.finishMoving:
	; This block of code is in S3K, but not KiS2:
    if 0
	; This code detaches Knuckles from the wall if there is ground
	; directly below him. Note that this code specifically does not run
	; if the player is holding up or down: this is because similar code
	; already runs if either of those buttons are being held. Presumably,
	; this check was added so that Knuckles would properly detach from
	; the wall if a rising floor (think Marble Garden Zone Act 2) came up
	; from under him. With that said, KiS2 lacks this logic, and yet
	; Knuckles seems to detach from the wall in Hill Top Zone's rising
	; wall section just fine, so I'm not sure whether this code was ever
	; actually needed in the first place.
	move.b	(Ctrl_1_Held_Logical).w,d0
	andi.b	#button_up_mask|button_down_mask,d0
	bne.s	.isMovingUpOrDown

	; Get Knuckles' distance from the floor in 'd1'.
	move.b	top_solid_bit(a0),d5
	move.w	y_pos(a0),d2
	addi.w	#9,d2
	move.w	x_pos(a0),d3
	bsr.w	CheckFloorDist_WithRadius

	; Check if Knuckles has room below him.
	tst.w	d1
	bmi.w	.reachedFloor

	; Bug! 'd1' has been overwritten by 'CheckFloorDist_WithRadius', but
	; the code after this needs it for updating Knuckles' animation. This
	; bug is the reason why Knuckles resets to his first climbing frame
	; when the player is not holding up or down.
    endif

.isMovingUpOrDown:
	; If Knuckles has not moved, skip this.
	tst.w	d1
	beq.s	.notMoving

	; Only animate every 4 frames.
	subq.b	#1,glide_property(a0)
	bpl.s	.notMoving
	move.b	#3,glide_property(a0)

	; Add delta to animation frame.
	add.b	mapping_frame(a0),d1

	; Make the animation loop.
	cmpi.b	#$B7,d1
	bhs.s	+
	move.b	#$BC,d1
+
	cmpi.b	#$BC,d1
	bls.s	+
	move.b	#$B7,d1
+
	; Apply the frame.
	move.b	d1,mapping_frame(a0)
; loc_315B30:
.notMoving:
	move.b	#$20,anim_frame_duration(a0)
	move.b	#0,anim_frame(a0)

	; These two lines aren't in S3K.
	move.b	#19,y_radius(a0)
	move.b	#9,x_radius(a0)

	move.w	(Ctrl_1_Held_Logical).w,d0
	andi.w	#button_A_mask|button_B_mask|button_C_mask,d0
	beq.s	.hasNotJumped

	; Knuckles has jumped off the wall.
	move.w	#-$380,y_vel(a0)
	move.w	#$400,x_vel(a0)

	bchg	#status.player.x_flip,status(a0)
	bne.s	+
	neg.w	x_vel(a0)
+
	bset	#status.player.in_air,status(a0)
	move.b	#1,jumping(a0)

	move.b	#14,y_radius(a0)
	move.b	#7,x_radius(a0)

	move.b	#AniIDSonAni_Roll,anim(a0)
	bset	#status.player.rolling,status(a0)
	move.b	#0,glide_mode(a0)
; return_315B94:
.hasNotJumped:
	rts
; ---------------------------------------------------------------------------

Knuckles_ClimbUp:
	move.b	#5,glide_mode(a0)		  ; Climb up to	the floor above	you

	cmpi.b	#$BD,mapping_frame(a0)
	beq.s	+

	move.b	#0,glide_property(a0)
	bsr.s	Knuckles_DoLedgeClimbingAnimation
+
	rts
; ---------------------------------------------------------------------------
; loc_315BAE:
Knuckles_LetGoOfWall:
	move.b	#2,glide_mode(a0)

	move.w	#(AniIDKnuxAni_FallAfterGlide<<8)|AniIDKnuxAni_FallAfterGlide,anim(a0)
	move.b	#$CB,mapping_frame(a0)
	move.b	#7,anim_frame_duration(a0)
	move.b	#1,anim_frame(a0)

	move.b	#19,y_radius(a0)
	move.b	#9,x_radius(a0)

	rts
; End of function Knuckles_GlideControl


; =============== S U B	R O U T	I N E =======================================

; sub_315BDA:
Knuckles_DoLedgeClimbingAnimation:
	moveq	#0,d0
	move.b	glide_property(a0),d0
	lea	.frames(pc,d0.w),a1

	move.b	(a1)+,mapping_frame(a0)

	move.b	(a1)+,d0
	ext.w	d0
	btst	#status.player.x_flip,status(a0)
	beq.s	+
	neg.w	d0
+
	add.w	d0,x_pos(a0)

	move.b	(a1)+,d1
	ext.w	d1
	add.w	d1,y_pos(a0)

	move.b	(a1)+,anim_frame_duration(a0)

	addq.b	#4,glide_property(a0)
	move.b	#0,anim_frame(a0)
	rts
; End of function Knuckles_DoLedgeClimbingAnimation

; ---------------------------------------------------------------------------
; Strangely, the last frame uses frame $D2. It will never be seen, however,
; because it is immediately overwritten by Knuckles' waiting animation.

; word_315C12:
.frames:
	; mapping_frame, x_pos, y_pos, anim_frame_timer
	dc.b $BD,   3,  -3,   6
	dc.b $BE,   8, -10,   6
	dc.b $BF,  -8, -12,   6
	dc.b $D2,   8,  -5,   6
.framesEnd:

; =============== S U B	R O U T	I N E =======================================

; sub_315C22:
GetDistanceFromWall:
	move.b	lrb_solid_bit(a0),d5
	btst	#status.player.x_flip,status(a0)
	bne.s	.facingLeft

;.facingRight:
	move.w	x_pos(a0),d3
	bra.w	CheckRightWallDist_WithRadius
; ---------------------------------------------------------------------------
; loc_315C36:
.facingLeft:
	move.w	x_pos(a0),d3
	subq.w	#1,d3
	bra.w	CheckLeftWallDist_WithRadius
; End of function GetDistanceFromWall

; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR Knuckles_GlideControl
; Knuckles_Climbing_Up:
Knuckles_Climbing_Onto_Ledge:
	tst.b	anim_frame_duration(a0)
	bne.s	return_315C7A

	bsr.w	Knuckles_DoLedgeClimbingAnimation

	; Have we reached the end of the ledge-climbing animation?
	cmpi.b	#Knuckles_DoLedgeClimbingAnimation.framesEnd-Knuckles_DoLedgeClimbingAnimation.frames,glide_property(a0)
	bne.s	return_315C7A

	; Yes.
	move.w	#0,inertia(a0)
	move.w	#0,x_vel(a0)
	move.w	#0,y_vel(a0)

	btst	#status.player.x_flip,status(a0)
	beq.s	+
	subq.w	#1,x_pos(a0)
+
	jsr	(Sonic_ResetOnFloor_Part2).l
	move.b	#AniIDSonAni_Wait,anim(a0)

return_315C7A:
	rts
; END OF FUNCTION CHUNK	FOR Knuckles_GlideControl

; =============== S U B	R O U T	I N E =======================================

; sub_315C7C:
Knuckles_DoGlidingAnimation:
	move.b	#$20,anim_frame_duration(a0)
	move.b	#0,anim_frame(a0)
	move.w	#(AniIDKnuxAni_Glide<<8)|AniIDKnuxAni_Glide,anim(a0)
	bclr	#status.player.pushing,status(a0)
	bclr	#status.player.x_flip,status(a0)

	; Update Knuckles' frame, depending on where he's facing.
	moveq	#0,d0
	move.b	glide_property(a0),d0
	addi.b	#$10,d0
	lsr.w	#5,d0
	move.b	.frames(pc,d0.w),d1
	move.b	d1,mapping_frame(a0)
	cmpi.b	#$C4,d1
	bne.s	+
	bset	#status.player.x_flip,status(a0)
	move.b	#$C0,mapping_frame(a0)
+
	rts
; End of function Knuckles_DoGlidingAnimation

; ---------------------------------------------------------------------------
; byte_315CC2:
.frames:	dc.b $C0, $C1, $C2, $C3, $C4, $C3, $C2, $C1

; =============== S U B	R O U T	I N E =======================================


Knuckles_GlideSpeedControl:
	cmpi.b	#1,glide_mode(a0)
	bne.w	.doNotKillspeed

	move.w	inertia(a0),d0
	cmpi.w	#$400,d0
	bhs.s	.mediumSpeed

;.lowSpeed:
	; Increase Knuckles' speed.
	addq.w	#8,d0
	bra.s	.applySpeed
; ---------------------------------------------------------------------------
; loc_315CE2:
.mediumSpeed:
	; If Knuckles is at his speed limit, then don't increase his speed.
	cmpi.w	#$1800,d0
	bhs.s	.applySpeed

	; If Knuckles is turning, then don't increase his speed either.
	move.b	glide_property(a0),d1
	andi.b	#$7F,d1
	bne.s	.applySpeed

	; Increase Knuckles' speed.
	addq.w	#4,d0

	; Super Knuckles and Hyper Knuckles glide faster.
	tst.b	(Super_Sonic_flag).w
	beq.s	.applySpeed
	addq.w	#8,d0
; loc_315CFC:
.applySpeed:
	move.w	d0,inertia(a0)

	move.b	glide_property(a0),d0
	btst	#button_left,(Ctrl_1_Held_Logical).w
	beq.s	.notHoldingLeft

;.holdingLeft:
	; Playing is holding left.
	cmpi.b	#$80,d0
	beq.s	.notHoldingLeft
	tst.b	d0
	bpl.s	+
	neg.b	d0
+
	addq.b	#2,d0
	bra.s	.setNewTurningValue
; ---------------------------------------------------------------------------
; loc_315D1C:
.notHoldingLeft:
	btst	#button_right,(Ctrl_1_Held_Logical).w
	beq.s	.notHoldingRight

;.holdingRight:
	; Playing is holding right.
	tst.b	d0
	beq.s	.notHoldingRight
	bmi.s	+
	neg.b	d0
+
	addq.b	#2,d0
	bra.s	.setNewTurningValue
; ---------------------------------------------------------------------------
; loc_315D30:
.notHoldingRight:
	move.b	d0,d1
	andi.b	#$7F,d1
	beq.s	.setNewTurningValue
	addq.b	#2,d0
; loc_315D3A:
.setNewTurningValue:
	move.b	d0,glide_property(a0)

	move.b	glide_property(a0),d0
	jsr	(CalcSine).l
	muls.w	inertia(a0),d1
	asr.l	#8,d1
	move.w	d1,x_vel(a0)

	; Is Knuckles is falling at a high speed, then create a parachute
	; effect, where gliding makes Knuckles fall slower.
	cmpi.w	#$80,y_vel(a0)
	blt.s	.fallingSlow
	subi.w	#$20,y_vel(a0)
	bra.s	.fallingFast
; ---------------------------------------------------------------------------
; loc_315D62:
.fallingSlow:
	; Apply gravity.
	addi.w	#$20,y_vel(a0)
; loc_315D68:
.fallingFast:
	; If Knuckles is above the level's top boundary, then kill his
	; horizontal speed.
	move.w	(Camera_Min_Y_pos).w,d0
	cmpi.w	#-$100,d0
	beq.w	.doNotKillspeed

	addi.w	#$10,d0
	cmp.w	y_pos(a0),d0
	ble.w	.doNotKillspeed

	asr.w	x_vel(a0)
	asr.w	inertia(a0)
; loc_315D88:
.doNotKillspeed:
	cmpi.w	#$60,(Camera_Y_pos_bias).w
	beq.s	.doNotModifyBias
	bhs.s	+
	addq.w	#2*2,(Camera_Y_pos_bias).w
+
	subq.w	#2,(Camera_Y_pos_bias).w
; return_315D9A:
.doNotModifyBias:
	rts
; End of function Knuckles_GlideSpeedControl

Knuckles_DoLevelCollision2:
	move.l	#Primary_Collision,(Collision_addr).w
	cmpi.b	#$C,top_solid_bit(a0)
	beq.s	+
	move.l	#Secondary_Collision,(Collision_addr).w
+
	move.b	lrb_solid_bit(a0),d5
	move.w	x_vel(a0),d1
	move.w	y_vel(a0),d2
	jsr	(CalcAirQuadrant).l	; code/Math.asm
	cmpi.b	#$40,d0
	beq.w	Knuckles_GlideHitLeftWall
	cmpi.b	#$80,d0
	beq.w	Knuckles_GlideHitCeilingAndWalls
	cmpi.b	#$C0,d0
	beq.w	Knuckles_GlideHitRightWall
	jsr	(CheckLeftWallDist).l
	tst.w	d1
	bpl.s	+
	sub.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0) ; stop Sonic since he hit a wall
	bset	#status.player.pushing,(Gliding_collision_flags).w
+
	jsr	(CheckRightWallDist).l
	tst.w	d1
	bpl.s	+
	add.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0) ; stop Sonic since he hit a wall
	bset	#status.player.pushing,(Gliding_collision_flags).w
+
	jsr	(Sonic_CheckFloor).l
	tst.w	d1
	bpl.s	KGlide_return_1AF8A
	add.w	d1,y_pos(a0)
	move.b	d3,angle(a0)
	move.w	#0,y_vel(a0)
	bclr	#status.player.in_air,(Gliding_collision_flags).w

KGlide_return_1AF8A:
	rts
; ===========================================================================
; loc_1AF8C:
Knuckles_GlideHitLeftWall:
	jsr	(CheckLeftWallDist).l
	tst.w	d1
	bpl.s	Knuckles_GlideHitCeiling ; branch if distance is positive (not inside wall)
	sub.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0) ; stop Sonic since he hit a wall
	bset	#status.player.pushing,(Gliding_collision_flags).w

; loc_1AFA6:
Knuckles_GlideHitCeiling:
	jsr	(Sonic_CheckCeiling).l
	tst.w	d1
	bpl.s	Knuckles_GlideHitFloor ; branch if distance is positive (not inside ceiling)
	neg.w	d1
	cmpi.w	#20,d1
	bhs.s	loc_316A08
	add.w	d1,y_pos(a0)
	tst.w	y_vel(a0)
	bpl.s	KGlide_return_1AFBE
	move.w	#0,y_vel(a0) ; stop Sonic in y since he hit a ceiling

KGlide_return_1AFBE:
	rts

loc_316A08:
	jsr	(CheckRightWallDist).l
	tst.w	d1
	bpl.s	return_316A20
	add.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0)
	bset	#status.player.pushing,(Gliding_collision_flags).w

return_316A20:
	rts
; ===========================================================================
; loc_1AFC0:
Knuckles_GlideHitFloor:
	tst.w	y_vel(a0)
	bmi.s	KGlide_return_1AFE6
	jsr	(Sonic_CheckFloor).l
	tst.w	d1
	bpl.s	KGlide_return_1AFE6
	add.w	d1,y_pos(a0)
	move.b	d3,angle(a0)
	move.w	#0,y_vel(a0)
	bclr	#status.player.in_air,(Gliding_collision_flags).w

KGlide_return_1AFE6:
	rts
; ===========================================================================
; loc_1AFE8:
Knuckles_GlideHitCeilingAndWalls:
	jsr	(CheckLeftWallDist).l
	tst.w	d1
	bpl.s	+
	sub.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0)	; stop Sonic since he hit a wall
	bset	#status.player.pushing,(Gliding_collision_flags).w
+
	jsr	(CheckRightWallDist).l
	tst.w	d1
	bpl.s	+
	add.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0)	; stop Sonic since he hit a wall
	bset	#status.player.pushing,(Gliding_collision_flags).w
+
	jsr	(Sonic_CheckCeiling).l
	tst.w	d1
	bpl.s	KGlide_return_1B042
	sub.w	d1,y_pos(a0)
	move.w	#0,y_vel(a0) ; stop Sonic in y since he hit a ceiling

KGlide_return_1B042:
	rts
; ===========================================================================
; loc_1B044:
Knuckles_GlideHitRightWall:
	jsr	(CheckRightWallDist).l
	tst.w	d1
	bpl.s	Knuckles_GlideHitCeiling2
	add.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0) ; stop Sonic since he hit a wall
	bset	#status.player.pushing,(Gliding_collision_flags).w

; identical to Sonic_HitCeiling...
; loc_1B05E:
Knuckles_GlideHitCeiling2:
	jsr	(Sonic_CheckCeiling).l
	tst.w	d1
	bpl.s	Knuckles_GlideHitFloor2
	sub.w	d1,y_pos(a0)
	tst.w	y_vel(a0)
	bpl.s	KGlide_return_1B076
	move.w	#0,y_vel(a0) ; stop Sonic in y since he hit a ceiling

KGlide_return_1B076:
	rts
; ===========================================================================
; identical to Sonic_HitFloor...
; loc_1B078:
Knuckles_GlideHitFloor2:
	tst.w	y_vel(a0)
	bmi.s	KGlide_return_1B09E
	jsr	(Sonic_CheckFloor).l
	tst.w	d1
	bpl.s	KGlide_return_1B09E
	add.w	d1,y_pos(a0)
	move.b	d3,angle(a0)
	move.w	#0,y_vel(a0)
	bclr	#status.player.in_air,(Gliding_collision_flags).w

KGlide_return_1B09E:
	rts
; End of function Knuckles_DoLevelCollision2

CheckFloorDist_WithRadius:
	move.b	x_radius(a0),d0
	ext.w	d0
	add.w	d0,d2
	lea	(Primary_Angle).w,a4
	move.w	#16,a3
	move.w	#0,d6
	jsr	(FindFloor).l
	move.b	#0,d2
	jmp	(loc_1ECFE).l
; End of function CheckFloorDist_WithRadius

CheckRightWallDist_WithRadius:
	move.b	x_radius(a0),d0
	ext.w	d0
	add.w	d0,d3
	lea	(Primary_Angle).w,a4
	move.w	#16,a3
	move.w	#0,d6
	jsr	(FindWall).l
	move.b	#$C0,d2
	jmp	(loc_1ECFE).l
; End of function CheckRightWallDist_WithRadius

CheckCeilingDist_WithRadius:
	move.b	x_radius(a0),d0
	ext.w	d0
	sub.w	d0,d2
	eori.w	#$F,d2
	lea	(Primary_Angle).w,a4
	move.w	#-16,a3
	move.w	#$800,d6
	jsr	(FindFloor).l
	move.b	#$80,d2
	jmp	(loc_1ECFE).l
; End of function CheckCeilingDist_WithRadius

CheckLeftWallDist_WithRadius:
	move.b	x_radius(a0),d0
	ext.w	d0
	sub.w	d0,d3
	eori.w	#$F,d3
	lea	(Primary_Angle).w,a4
	move.w	#-16,a3
	move.w	#$400,d6
	jsr	(FindWall).l
	move.b	#$40,d2
	jmp	(loc_1ECFE).l
; End of function CheckLeftWallDist_WithRadius
