; ---------------------------------------------------------------------------
; Subroutine to check if Tails should start flying
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

Tails_CheckFlying:
	if FeatureTailsFlight=0
	rts					; Tails flight disabled
	endif
	tst.b	flying(a0)			; is Tails already flying?
	bne.w	Tails_NoFlight			; if yes, branch
	tst.w	(Demo_mode_flag).w		; is a title demo playing?
	beq.s	.notdemo			; if not, branch
	jsr	(Demo_TailsAssistIndex).l	; only the Tails Flight Assist demos use flight
	bcs.w	Tails_NoFlight			; the original demo scripts predate it

.notdemo:
	move.b	(Ctrl_2_Press_Logical).w,d0	; get Tails' controller input
	andi.b	#button_A_mask|button_B_mask|button_C_mask,d0	; has been any jump button pressed?
	beq.w	Tails_NoFlight			; if not, branch
	tst.w	(Two_player_mode).w		; is this 2P versus mode?
	bne.s	Tails_StartFlight			; if yes, make Tails fly
	cmpa.w	#Sidekick,a0			; is Tails the sidekick?
	bne.s	Tails_StartFlight			; if not, make him fly?
	tst.w	(Tails_control_counter).w	; is Tails currently AI controlled?
	beq.s	Tails_NoFlight			; if yes, branch

Tails_StartFlight:
	bclr	#status.player.rolling,status(a0)	; unset Tails' rolling flag
	move.b	#$F,y_radius(a0)		; restore regular height...
	move.b	#9,x_radius(a0)			; ...and width
	addq.w	#1,y_pos(a0)			; adjust Y-position a bit
	move.b	#1,flying(a0)			; set flying mode flag
	move.b	#(8*60)/2,flying_timer(a0)	; set flying timer to 8 seconds (divided by 2)
	bsr.w	Tails_FlyingAnimation

Tails_NoFlight:
	rts

; End of subroutine Tails_CheckFlying

; ---------------------------------------------------------------------------
; Subroutine controlling Tails' flying (and swimming)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

Tails_Flying:
	move.b	(Level_frame_counter+1).w,d0	; get the universal timer value
	andi.b	#1,d0				; is it odd?
	beq.s	.nodecrement			; if yes, branch
	tst.b	flying_timer(a0)		; is Tails tired?
	beq.s	.nodecrement			; if yes, branch
	subq.b	#1,flying_timer(a0)		; subtract from the timer

.nodecrement:
	cmpi.b	#1,flying(a0)			; is the flying flag exactly 1?
	beq.s	.checkflying			; if yes, branch
	cmpi.w	#-$100,y_vel(a0)		; is Tails moving upwards fast enough?
	blt.s	.resetflag			; if yes, branch
	subi.w	#$20,y_vel(a0)			; move Tails upwards
	addq.b	#1,flying(a0)			; increase the flying flag like a timer
	cmpi.b	#$20,flying(a0)			; has enough time passed?
	bne.s	.noreset			; if not, branch

.resetflag:
	move.b	#1,flying(a0)			; set flying flag to 1

.noreset:
	bra.s	.checkupperboundary		; check for upper boundary
; ---------------------------------------------------------------------------

.checkflying:
	move.b	(Ctrl_2_Press_Logical).w,d0	; get Tails' controller input
	andi.b	#button_A_mask|button_B_mask|button_C_mask,d0	; has been any jump button pressed?
	beq.s	.applygravity			; if not, branch
	cmpi.w	#-$100,y_vel(a0)		; is Tails moving upwards fast enough?
	blt.s	.applygravity			; if yes, branch
	tst.b	flying_timer(a0)		; is Tails tired?
	beq.s	.applygravity			; if yes, branch
	tst.w	(Player_mode).w			; is it a Tails-only game?
	bne.s	.allowflightt			; if yes, branch
	btst	#status.player.underwater,status(a0)	; is Tails underwater?
	beq.s	.allowflightt			; if not, branch
	btst	#status_secondary.carry,(MainCharacter+status_secondary).w	; is Tails carrying Sonic?
	bne.s	.applygravity			; if yes, branch

.allowflightt:
	move.b	#2,flying(a0)			; set flying flag to 2 (and thus run delay code on next frame)

.applygravity:
	addi.w	#8,y_vel(a0)			; apply weak gravity

.checkupperboundary:
	move.w	(Camera_Min_Y_pos).w,d0
		; get upper boundary value
	addi.w	#$10,d0				; add $10 to it
	cmp.w	y_pos(a0),d0			; is Tails close enough to the top boundary?
	blt.s	.setanim			; if not, branch
	tst.w	y_vel(a0)			; is Tails moving upwards?
	bpl.s	.setanim			; if not, branch
	move.w	#0,y_vel(a0)			; clear Tails' Y velocity
.setanim:
	bra.w	Tails_FlyingAnimation
; End of subroutine Tails_Flying

; ---------------------------------------------------------------------------
; Subroutine to pick a correct animation for Tails when flying or swimming
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Tails_FlyingAnimation:
	if FeatureTailsFlight=0
	move.b	#AniIDTailsAni_Fly,anim(a0)	; the AI's respawn flight only
	rts
	endif
	move.w #SndID_TailsFly,d1
	moveq	#0,d0				; clear d0
	tst.w	y_vel(a0)			; is Tails moving upwards?
	bpl.s	.movingdown			; if not, branch
	addq.b	#1,d0				; use upwards sprites

.movingdown:
	tst.w	(Two_player_mode).w
	bne.s	.nocarry
	cmpa.w	#Sidekick,a0
	bne.s	.nocarry
	tst.w	(Player_mode).w			; is this a Sonic & Tails game?
	bne.s	.nocarry			; if not, branch
	cmpi.w	#4,(Tails_CPU_routine).w	; is Tails respawning?
	beq.s	.nottired			; if yes, check for water only
	btst	#status_secondary.carry,(MainCharacter+status_secondary).w	; is Tails currently carrying Sonic?
	beq.s	.nocarry			; if not, branch
	addq.b	#2,d0				; use carrying sprites

.nocarry:
	tst.b	flying_timer(a0)		; is Tails tired?
	bne.s	.nottired			; if not, branch
	move.w #SndID_TailsTired,d1
	addq.b	#4,d0				; use tired sprites

.nottired:
	btst	#status.player.underwater,status(a0)	; is Tails underwater?
	beq.s	.display			; if not, branch
	moveq #0,d1
	addq.b	#8,d0				; use swimming sprites

.display:
	move.b	.animationtable(pc,d0.w),anim(a0)	; get correct animation ID
	tst.b d1
	beq.s .nosound
	move.b (Level_frame_counter+1).w,d0
	addq.b #8,d0
	andi.b #$F,d0
	bne.s .nosound
	move.w d1,d0
	jmp (PlaySoundLocal).l
.nosound:
	rts

; ---------------------------------------------------------------------------
; A lookup table for Tails' flying/swimming animation
;	dc.b	moving downwards, moving upwards, carrying Sonic downwards, carrying Sonic upwards

.animationtable:
	dc.b	      AniIDTailsAni_Fly,     AniIDTailsAni_FlyUp,      AniIDTailsAni_Carry, AniIDTailsAni_CarryUp	; normal
	dc.b	    AniIDTailsAni_Tired,     AniIDTailsAni_Tired, AniIDTailsAni_CarryTired, AniIDTailsAni_CarryTired	; tired
	dc.b	     AniIDTailsAni_Swim,    AniIDTailsAni_SwimUp,  AniIDTailsAni_SwimCarry, AniIDTailsAni_SwimCarry	; swimming
	dc.b	AniIDTailsAni_SwimTired, AniIDTailsAni_SwimTired,  AniIDTailsAni_SwimCarry, AniIDTailsAni_SwimCarry	; swimming tired
	even
; End of subroutine Tails_FlyingAnimation

; ---------------------------------------------------------------------------
; Subroutine to control Sonic being carried by Tails during flight
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

Tails_CarrySonic:
	tst.w	(Two_player_mode).w			; is this a multiplayer game?
	bne.w	Tails_CarryNoGrab			; if yes, branch
	tst.w	(Player_mode).w				; is this a Sonic & Tails game?
	bne.w	Tails_CarryNoGrab			; if not, branch
	lea	(MainCharacter).w,a1			; load Sonic's RAM address to a1
	move.w	(Ctrl_1_Logical).w,d0				; load player's inputs to d0

	btst	#status_secondary.carry,status_secondary(a1)	; is Sonic being carried now?
	beq.w	Tails_CheckCarry			; if not, check if he can be
	cmpi.b	#4,routine(a1)				; is Sonic well and alive?
	bhs.w	.exitgrab				; if not, branch
	tst.b	obj_control(a1)				; is Sonic's collision restricted?
	bmi.w	.exitgrab				; if yes, branch
	btst	#status.player.in_air,status(a1)	; is Sonic airbone?
	beq.w	.bumpandexitgrab			; if not, branch
	move.w	(Sidekick_Y_vel_copy).w,d1		; get Tails' Y speed from previous frame
	cmp.w	y_vel(a1),d1				; is Sonic's current Y speed equal to it?
	bne.s	.exitgrab				; if not, branch
	move.w	(Sidekick_X_vel_copy).w,d1		; get Tails' X speed from previous frame
	cmp.w	x_vel(a1),d1				; is Sonic's current X speed equal to it?
	bne.w	.bumpandexitgrab			; if not, branch
	andi.b	#button_A_mask|button_B_mask|button_C_mask,d0	; has been any jump button pressed?
	beq.w	Tails_CarryUpdatePosition		; if not, keep flying

; leaving Tails on demand
	bclr	#status_secondary.carry,status_secondary(a1)	; if yes, let go of Tails
	move.b	#18,carry_delay(a0)			; set a delay before another carrying
	andi.w	#(button_left_mask|button_right_mask)<<8,d0	; has left/right direction button been pressed?
	beq.w	.notright				; if not, branch
	move.b	#60,carry_delay(a0)			; make the delay a bit longer

.nodirection:
	btst	#(button_left+8),d0			; is left button being held?
	beq.s	.notleft				; if not, branch
	move.w	#-$200,x_vel(a1)			; set X-velocity

.notleft:
	btst	#(button_right+8),d0			; is right button being held?
	beq.s	.notright				; if not, branch
	move.w	#$200,x_vel(a1)				; set X-velocity

.notright:
	move.w	#6,(Tails_CPU_routine).w
	move.w	#-$380,y_vel(a1)			; set Y-velocity
	bset	#status.player.in_air,status(a1)	; set "in-air" mode
	move.b	#1,jumping(a1)				; set jumping flag
	move.b	#$E,y_radius(a1)			; set jumping height
	move.b	#7,x_radius(a1)				; set jumping width (/2)
	move.b	#AniIDSonAni_Roll,anim(a1)		; set rolling animation
	bset	#status.player.rolling,status(a1)	; set "rolling" mode
	rts
; ---------------------------------------------------------------------------
; leaving Tails by outside means
.bumpandexitgrab:
	move.w	#-$100,y_vel(a1)		; make a slight upwards push

.exitgrab:
	move.w	#6,(Tails_CPU_routine).w
	bclr	#status_secondary.carry,status_secondary(a1)	; clear "being carried" flag
	move.b	#60,carry_delay(a0)		; set a delay before another carrying
	rts
; End of subroutine Tails_CarrySonic

; ---------------------------------------------------------------------------
; Subroutine to check for Tails to start carrying Sonic
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

Tails_CheckCarry:
	tst.b	carry_delay(a0)			; is the delay timer running?
	beq.s	.notimer			; if 0, branch
	subq.b	#1,carry_delay(a0)		; subtract from the timer
	bne.w	Tails_CarryNoGrab		; if non-0, branch

.notimer:
	tst.b	obj_control(a1)			; is Sonic controlled by other object?
	bne.w	Tails_CarryNoGrab		; if not, branch
	cmpi.b	#4,routine(a1)			; is Sonic well and alive?
	bhs.w	Tails_CarryNoGrab		; if not, branch
	tst.w	(Debug_placement_mode).w	; is the player in object placement mode?
	bne.w	Tails_CarryNoGrab		; if yes, branch
	tst.b	spindash_flag(a1)		; is Sonic reloading a Spin Dash?
	bne.w	Tails_CarryNoGrab		; if yes, branch

	move.w	x_pos(a1),d0			; get Sonic's X-position
	sub.w	x_pos(a0),d0			; subtract Tails' X-position
	addi.w	#$10,d0				; add $10
	cmpi.w	#$20,d0				; is Sonic in range to be caught?
	bhs.w	Tails_CarryNoGrab		; if not, branch
	move.w	y_pos(a1),d1			; get Sonic's Y-position
	sub.w	y_pos(a0),d1			; subtract Tails' Y-position
	subi.w	#$20,d1				; subtract $20
	cmpi.w	#$10,d1				; is Sonic in range to be caught?
	bhs.w	Tails_CarryNoGrab		; if not, branch

	tst.w	(Tails_control_counter).w
	bne.s	.manual
	move.w	#$C,(Tails_CPU_routine).w
	clr.w	(Ctrl_2_Logical).w
	tst.w	y_vel(a0)
	bmi.s	.manual
	clr.w	y_vel(a0)
.manual:
	clr.l	x_vel(a1)			; clear X and Y velocities
	clr.w	inertia(a1)			; clear ground velocity
	clr.w	angle(a1)			; clear angle
	move.b	#$13,y_radius(a1)
	move.b	#9,x_radius(a1)
	bclr	#status.player.rolling,status(a1)
	clr.b	jumping(a1)			; clear jumping flag
	bset	#status_secondary.carry,status_secondary(a1)	; set being carried flag
	bset	#status.player.in_air,status(a1); set "in-air" status
	move.w	#AniIDSonAni_Hang2<<8,anim(a1)	; set and force hanging animation
	move.w #SndID_TailsGrab,d0
	jsr (PlaySound).l

; End of subroutine Tails_CheckCarry
	; continue straight to Tails_CarryUpdatePosition

; ---------------------------------------------------------------------------
; Subroutine to update Sonic's position and collision when he's being carried
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

Tails_CarryUpdatePosition:
	move.w	x_pos(a0),x_pos(a1)		; align Sonic and Tails on X-axis
	move.w	y_pos(a0),y_pos(a1)		; align Sonic and Tails on Y-axis
	addi.w	#$1D,y_pos(a1)			; move Sonic a bit lower
	andi.b	#~(1<<render_flags.x_flip),render_flags(a1)	; clear horizontal flip flag in object render
	andi.b	#~(1<<status.player.x_flip),status(a1)	; clear horizontal flip flag in object status
	move.b	status(a0),d0			; get Tails' object status
	andi.b	#1<<status.player.x_flip,d0	; leave only the horizontal flip bit
	or.b	d0,render_flags(a1)		; update Sonic's horizontal flip flag in object render
	or.b	d0,status(a1)			; update Sonic's horizontal flip flag in object status
	move.l	x_vel(a0),x_vel(a1)		; align Sonic's and Tails' velocities
	move.l	x_vel(a0),(Sidekick_X_vel_copy).w ; backup Tails' velocities
	move.l	a0,-(sp)			; backup Tails' RAM address
	lea	(MainCharacter).w,a0		; load Sonic's RAM address to a0
	jsr	(Sonic_DoLevelCollision).l		; perform collision checks for Sonic
	move.l	(sp)+,a0			; restore Tails' RAM address

Tails_CarryNoGrab:
	rts
; End of subroutine Tails_CarryUpdatePosition

; Up + a fresh jump while airborne requests Tails; Super button combos remain unchanged.
Sonic_RequestTailsAssist:
	if FeatureTailsFlight=0
	rts					; Tails assist disabled
	endif
	tst.w (Two_player_mode).w
	bne.s .return
	tst.w (Demo_mode_flag).w		; is a title demo playing?
	beq.s .notdemo
	jsr (Demo_TailsAssistIndex).l	; only the Tails Flight Assist demos call Tails
	bcs.s .return
.notdemo:
	tst.w (Player_mode).w
	bne.s .return
	tst.b (Control_Locked).w
	bne.s .return
	tst.b obj_control(a0)
	bne.s .return
	btst #button_up,(Ctrl_1_Held_Logical).w
	beq.s .return
	move.b (Ctrl_1_Press_Logical).w,d0
	andi.b #button_A_mask|button_B_mask|button_C_mask,d0
	beq.s .return
	cmpi.w #6,(Tails_CPU_routine).w
	blo.s .return
	cmpi.w #$A,(Tails_CPU_routine).w
	bhs.s .return
	cmpi.b #ObjID_Tails,(Sidekick+id).w
	bne.s .return
	cmpi.b #4,(Sidekick+routine).w
	bhs.s .return
	move.w #$A,(Tails_CPU_routine).w
.return:
	rts

TailsCPU_Assist:
	tst.w (Tails_control_counter).w
	bne.s .cancel
	cmpi.b #4,(MainCharacter+routine).w
	bhs.s .cancel
	tst.b obj_control(a0)
	bne.s .cancel
	clr.w (Ctrl_2_Logical).w
	move.w (MainCharacter+x_pos).w,d0
	sub.w x_pos(a0),d0
	cmpi.w #8,d0
	ble.s .left
	move.w #button_right_mask<<8,(Ctrl_2_Logical).w
	bra.s .height
.left:
	cmpi.w #-8,d0
	bge.s .height
	move.w #button_left_mask<<8,(Ctrl_2_Logical).w
.height:
	tst.b flying(a0)
	bne.s .flap
	btst #status.player.in_air,status(a0)
	bne.s .start
	ori.w #button_C_mask<<8|button_C_mask,(Ctrl_2_Logical).w
	rts
.start:
	; Start flying no faster than a released jump, as Tails_JumpHeight
	; requires for the player; otherwise the AI keeps its full jump speed
	; under the weak flight gravity and shoots far above Sonic.
	move.w #-$400,d0
	btst #status.player.underwater,status(a0)
	beq.s +
	move.w #-$200,d0
+
	cmp.w y_vel(a0),d0
	ble.s +
	move.w d0,y_vel(a0)
+
	bsr.w Tails_StartFlight
.flap:
	move.w y_pos(a0),d0
	addi.w #$20,d0
	cmp.w (MainCharacter+y_pos).w,d0
	ble.s .return
	ori.w #button_C_mask<<8|button_C_mask,(Ctrl_2_Logical).w
.return:
	rts
.cancel:
	move.w #6,(Tails_CPU_routine).w
	rts

; When AI carries Sonic, left/right steer, repeated Up flaps and jump releases.
TailsCPU_Carry:
	tst.w (Tails_control_counter).w
	bne.s .return
	move.w (Ctrl_1_Logical).w,d0
	andi.w #((button_left_mask|button_right_mask)<<8)|button_left_mask|button_right_mask,d0
	move.w d0,(Ctrl_2_Logical).w
	btst #button_up,(Ctrl_1_Press_Logical).w
	beq.s .return
	ori.w #button_C_mask<<8|button_C_mask,(Ctrl_2_Logical).w
.return:
	rts

; The leader is drowning. Swim toward the surface with the ordinary ceiling
; collision, then wait there instead of replaying the leader's descent.
TailsCPU_EscapeDrowning:
	tst.w	(Tails_control_counter).w
	bne.w	.release
	cmpi.b	#AniIDSonAni_Drown,anim(a1)
	beq.s	.escape
	cmpi.b	#6,routine(a1)
	blo.w	.release
.escape:
	clr.w	(Ctrl_2_Logical).w
	btst	#status.player.underwater,status(a0)
	beq.s	.dry
	clr.w	x_vel(a0)
	clr.w	inertia(a0)
	bclr	#status.player.rolling,status(a0)
	bset	#status.player.in_air,status(a0)
	move.b	#$F,y_radius(a0)
	move.b	#9,x_radius(a0)
	move.b	#$81,obj_control(a0)
	move.w	#-$180,y_vel(a0)
	move.b	#AniIDTailsAni_SwimUp,anim(a0)
	bra.s	.move
.dry:
	tst.b	obj_control(a0)
	bpl.s	.return
	move.w	y_pos(a0),d0
	sub.w	(Camera_Y_pos).w,d0
	cmpi.w	#-$20,d0			; keep flying until the sprite clears the screen
	ble.s	.offscreen
	move.w	#-$200,y_vel(a0)
	move.b	#AniIDTailsAni_FlyUp,anim(a0)
.move:
	jsr	(ObjectMove).l
	jmp	(Tails_DoLevelCollision).l
.offscreen:
	clr.w	y_vel(a0)
.return:
	rts
.release:
	jmp	(TailsCPU_Init).l
