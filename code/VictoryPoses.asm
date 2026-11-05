; ---------------------------------------------------------------------------
; Victory poses (FeatureVictoryPoses), after AleDrawer2008's "Add Victory Poses
; In Sonic 1" as in s1_improvements: after opening the egg prison the
; player stays on screen, and once landed the controls lock, he stops and the
; act results start; Sonic then poses (SonAni_Victory, frames $DB-$DC from
; tools/import_victory_poses.py) whenever he stands still. 2P VS games keep
; the original ending.
; ---------------------------------------------------------------------------

victory_pose_capsule = 1
victory_pose_signpost = 2

; Returns Z=0 while the main character is still in the air (try again next
; frame); otherwise locks the controls, stops him and returns Z=1.
Victory_Start:
	movem.l	a1,-(sp)
	tst.w	(Two_player_mode).w
	bne.s	.go
	lea	(MainCharacter).w,a1
	tst.b	id(a1)
	beq.s	.go
	btst	#status.player.in_air,status(a1)
	bne.s	.wait
	move.b	#1,(Control_Locked).w
	clr.w	(Ctrl_1_Logical).w		; with no input held
	clr.w	x_vel(a1)
	clr.w	inertia(a1)
	clr.b	(LightDash_active).w
	cmpi.b	#ObjID_Sonic,id(a1)
	bne.s	.go
	clr.b	peelout_flag(a1)		; a held Peel-Out must not launch
.go:
	movem.l	(sp)+,a1
	ori	#4,ccr				; Z=1
	rts
.wait:
	movem.l	(sp)+,a1
	andi	#~4,ccr				; Z=0
	rts

; Called by the egg prison before results (1P games only).
Victory_Pose:
	tst.w	(Two_player_mode).w
	bne.s	+
	move.b	#victory_pose_capsule,(Victory_pose).w
+
	rts
