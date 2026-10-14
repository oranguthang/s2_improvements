; ---------------------------------------------------------------------------
; Super Peel-Out (FeaturePeelOut), after Selbi's guide as adapted in
; s1_improvements: standing still, hold Up and press A/B/C to charge; let go
; of Up to launch an upright run. The charge is kept in spindash_counter, apart
; from inertia, which solid objects may clear every frame.
; Sonic 2 has no figure-eight frames or Peel-Out sounds: the charge shows the
; normal run cycle at the charged speed and uses the Spin Dash sounds.
; ---------------------------------------------------------------------------
PeelOut_ChargeStep = 100
PeelOut_MinCharge = $600
PeelOut_MaxCharge = $1000

; Called first in Obj01_MdNormal. While charging (and on a cancelled release)
; it skips the rest of the mode.
Sonic_PeelOut:
	if FeaturePeelOut=0
	rts					; Super Peel-Out disabled
	endif
	tst.b	peelout_flag(a0)
	bne.s	.charge
	tst.w	(Demo_mode_flag).w		; the title demos were recorded without it
	bne.s	.return
	tst.b	spindash_flag(a0)
	bne.s	.return
	tst.w	move_lock(a0)
	bne.s	.return
	tst.w	inertia(a0)			; only from a standstill
	bne.s	.return
	move.b	(Ctrl_1_Held_Logical).w,d0
	andi.b	#button_up_mask|button_down_mask,d0
	cmpi.b	#button_up_mask,d0
	bne.s	.return
	moveq	#button_A_mask|button_B_mask|button_C_mask,d0
	and.b	(Ctrl_1_Press_Logical).w,d0
	beq.s	.return
	move.b	#1,peelout_flag(a0)
	clr.w	spindash_counter(a0)
	move.w	#SndID_SpindashRev,d0
	jsr	(PlaySound).l
	bra.s	.stationary
.return:
	rts

.charge:
	btst	#button_up,(Ctrl_1_Held_Logical).w
	beq.s	.release
	move.w	(Sonic_top_speed).w,d0
	add.w	d0,d0				; up to twice the top speed...
	cmpi.w	#PeelOut_MaxCharge,d0
	bls.s	+
	move.w	#PeelOut_MaxCharge,d0		; ...but no more than $1000
+
	addi.w	#PeelOut_ChargeStep,spindash_counter(a0)
	cmp.w	spindash_counter(a0),d0
	bhs.s	.stationary
	move.w	d0,spindash_counter(a0)
.stationary:
	clr.w	inertia(a0)
	clr.w	x_vel(a0)
	clr.w	y_vel(a0)
	move.b	#AniIDSonAni_Walk,anim(a0)
	bclr	#status.player.pushing,status(a0)
	jsr	(LightDash_LevelBound).l	; (safe from the pit exit's stack trick)
	jsr	(AnglePos).l
	; Run on the spot: the animation and the extended camera read inertia,
	; which the next frame clears again before anything moves.
	move.w	spindash_counter(a0),d0
	btst	#status.player.x_flip,status(a0)
	beq.s	+
	neg.w	d0
+
	move.w	d0,inertia(a0)
	addq.l	#4,sp				; skip the rest of Obj01_MdNormal
	rts

.release:
	move.w	spindash_counter(a0),d2
	clr.b	peelout_flag(a0)
	clr.w	spindash_counter(a0)
	cmpi.w	#PeelOut_MinCharge,d2
	blo.s	.cancel
	btst	#status.player.x_flip,status(a0)
	beq.s	+
	neg.w	d2
+
	move.w	d2,inertia(a0)			; Sonic_Move turns it into speed along the floor
	bclr	#status.player.pushing,status(a0)
	move.b	#AniIDSonAni_Walk,anim(a0)
	move.w	#SndID_SpindashRelease,d0
	jmp	(PlaySound).l
.cancel:
	clr.w	inertia(a0)
	move.b	#AniIDSonAni_Wait,anim(a0)
	addq.l	#4,sp				; a release cannot also jump
	rts

; Landing, a hit or a death stops a charge. a0 = player; only Sonic uses $23 for it.
Sonic_CancelPeelOut:
	cmpi.b	#ObjID_Sonic,id(a0)
	bne.s	+
	clr.b	peelout_flag(a0)
+
	rts
