; ---------------------------------------------------------------------------
; Any character for player 2 in 2P VS (FeatureKnuckles)
;
; Player 2 picks Tails, Sonic or Knuckles (VS_player2, Options screen). Sonic
; and Knuckles are Obj01 in the Sidekick slot. Obj01 keeps its state in
; "Sonic" RAM (Ctrl_1_Logical, Sonic_top_speed, Camera_Y_pos_bias, the camera
; bounds, Sonic_Dust...), so player 2's Obj01 runs with that RAM exchanged
; with player 2's ("Tails") RAM (VS_SwapPlayerContext) and exchanged back
; afterwards; Main_character then says who player 2 is. Everything Obj01 does
; for the player slot itself (rings, lives, star posts, position record,
; VRAM) checks a0 instead. P2_context_active is set while that happens.
; ---------------------------------------------------------------------------

; Obj01 in the Sidekick slot (a0 = Sidekick)
VS_Obj01Player2:
	move.w	(Tails_Max_Y_pos).w,(VS_Max_Y_pos_target).w	; see below
	bsr.s	VS_SwapPlayerContext
	st.b	(P2_context_active).w
	jsr	(Obj01_Normal).l	; (debug placement belongs to player 1)
	sf.b	(P2_context_active).w
	; fall through: exchange the RAM back

; Exchanges player 1's Obj01 RAM with player 2's. Keeps every register.
VS_SwapPlayerContext:
	movem.l	d0-d1/a1-a3,-(sp)
	lea	VS_SwapWords(pc),a3
.wordPair:
	movea.w	(a3)+,a1
	cmpa.w	#0,a1
	beq.s	.bytes
	movea.w	(a3)+,a2
	move.w	(a3)+,d1
.word:
	move.w	(a1),d0
	move.w	(a2),(a1)+
	move.w	d0,(a2)+
	dbf	d1,.word
	bra.s	.wordPair
.bytes:
	movea.w	(a3)+,a1
	cmpa.w	#0,a1
	beq.s	.done
	movea.w	(a3)+,a2
	move.b	(a1),d0
	move.b	(a2),(a1)
	move.b	d0,(a2)
	bra.s	.bytes
.done:
	; Obj01's bottom boundary also looks at the lowering target, which
	; player 2's camera does not have: use his boundary for both
	move.w	(VS_Max_Y_pos_target).w,d0
	move.w	(Camera_Max_Y_pos_target).w,(VS_Max_Y_pos_target).w
	move.w	d0,(Camera_Max_Y_pos_target).w
	movem.l	(sp)+,d0-d1/a1-a3
	rts

swapw macro ram1,ram2,size
	dc.w	ram1&$FFFF, ram2&$FFFF, (size)/2-1
	endm
swapb macro ram1,ram2
	dc.w	ram1&$FFFF, ram2&$FFFF
	endm

VS_SwapWords:
	swapw	Ctrl_1_Logical, Ctrl_2_Logical, 2
	swapw	Sonic_top_speed, Tails_top_speed, 6	; and acceleration, deceleration
	swapw	Camera_Y_pos_bias, Camera_Y_pos_bias_P2, 2
	swapw	Sonic_Look_delay_counter, Tails_Look_delay_counter, 2
	swapw	Camera_Min_X_pos, Tails_Min_X_pos, 8	; and Max X, Min Y, Max Y
	swapw	Camera_X_pos_diff, Camera_X_pos_diff_P2, 2
	swapw	Camera_Y_pos_diff, Camera_Y_pos_diff_P2, 2
	swapw	Horiz_scroll_delay_val, Horiz_scroll_delay_val_P2, 2
	swapw	Camera_pan, VS_Camera_pan_P2, 2
	swapw	Sonic_Dust, Tails_Dust, object_size
	swapw	Sonic_BreathingBubbles, Tails_BreathingBubbles, object_size
	swapw	LightDash_RAM, VS_LightDash_RAM_P2, LightDash_RAM_End-LightDash_RAM
	dc.w	0
VS_SwapBytes:
	swapb	Control_Locked, Control_Locked_P2
	swapb	Scroll_lock, Scroll_lock_P2
	swapb	Sonic_LastLoadedDPLC, Tails_LastLoadedDPLC
	swapb	Main_character, Player2_character
	swapb	Super_Sonic_flag, VS_Super_flag_P2	; player 2 never turns Super
	dc.w	0

	if (LightDash_RAM_End-LightDash_RAM)&1
		fatal "VS_SwapPlayerContext exchanges LightDash_RAM in words"
	endif

; ---------------------------------------------------------------------------
; Level start (InitPlayers, 2P VS): Sonic or Knuckles as player 2.
; Returns Z=1 if player 2 is Tails (InitPlayers then loads him as usual).
; ---------------------------------------------------------------------------
VS_InitPlayer2:
	bsr.s	VS_Player2Option
	tst.b	d0		; VSPlayer2_Tails?
	beq.s	.return
	move.b	VS_Player2Characters(pc,d0.w),(Player2_character).w
	move.b	#ObjID_Sonic,(Sidekick+id).w	; Obj01 as player 2
	move.b	#$13,(Sidekick+y_radius).w
	move.w	(MainCharacter+x_pos).w,(Sidekick+x_pos).w
	move.w	(MainCharacter+y_pos).w,(Sidekick+y_pos).w
	subi.w	#$20,(Sidekick+x_pos).w
	move.b	#ObjID_SpindashDust,(Tails_Dust+id).w	; his dust (Obj08 follows the Sidekick)
	; player 2's Obj01 RAM starts like player 1's
	lea	(VS_LightDash_RAM_P2).w,a1
	moveq	#bytesToWcnt(LightDash_RAM_End-LightDash_RAM),d1
-	clr.w	(a1)+
	dbf	d1,-
	clr.w	(VS_Camera_pan_P2).w
	clr.b	(VS_Super_flag_P2).w
	moveq	#1,d0		; Z=0
.return:
	rts

; d0 = the level's life icon PLC -> player 2's in 2P VS
VS_Player2LifePLC:
	tst.w	(Two_player_mode).w
	beq.s	.return
	movem.l	d0-d1,-(sp)
	bsr.s	VS_Player2Option
	move.w	d0,d1
	movem.l	(sp)+,d0
	cmpi.b	#VSPlayer2_Sonic,d1
	bne.s	.notSonic
	moveq	#PLCID_SonicLife2P,d0
.notSonic:
	cmpi.b	#VSPlayer2_Knuckles,d1
	bne.s	.done
	moveq	#PLCID_KnucklesLife2P,d0
.done:
	movem.l	(sp)+,d1
.return:
	rts

; d0.w = player 2's VSPlayer2_* (Tails in demos, whose inputs are his)
VS_Player2Option:
	moveq	#VSPlayer2_Tails,d0
	tst.w	(Demo_mode_flag).w
	bne.s	.return
	move.b	(VS_player2).w,d0
	cmpi.b	#VSPlayer2_Count,d0
	blo.s	.return
	moveq	#VSPlayer2_Tails,d0
.return:
	rts

VS_Player2Characters:
	dc.b	CharID_Sonic	; VSPlayer2_Tails (not used)
	dc.b	CharID_Sonic	; VSPlayer2_Sonic
	dc.b	CharID_Knuckles	; VSPlayer2_Knuckles
	even

; ---------------------------------------------------------------------------
; Z=0 if a1 is Knuckles, in either player slot (Obj01 with CharID_Knuckles).
; ---------------------------------------------------------------------------
Player_IsKnuckles:
	cmpi.b	#ObjID_Sonic,id(a1)
	bne.s	.no
	cmpa.w	#MainCharacter,a1
	beq.s	.player1
	cmpa.w	#Sidekick,a1
	bne.s	.no
	tst.b	(P2_context_active).w	; player 2's Obj01 running: his is in Main_character
	bne.s	.current
	tst.b	(Player2_character).w
	rts
.player1:
	tst.b	(P2_context_active).w
	bne.s	.other
.current:
	tst.b	(Main_character).w
	rts
.other:
	tst.b	(Player2_character).w
	rts
.no:
	ori	#4,ccr		; Z=1
	rts

; ---------------------------------------------------------------------------
; Obj01 death in the Sidekick slot: player 2's lives, time over, star post and
; rings (Obj02_CheckGameOver_2Pmode for Obj01). Scroll_lock and the camera
; are already player 2's here.
; ---------------------------------------------------------------------------
VS_Obj01Player2GameOver:
	addq.b	#1,(Update_HUD_lives_2P).w
	subq.b	#1,(Life_count_2P).w
	bne.s	.reset
	move.w	#0,restart_countdown(a0)
	move.b	#ObjID_GameOver,(GameOver_GameText+id).w ; load Obj39
	move.b	#ObjID_GameOver,(GameOver_OverText+id).w ; load Obj39
	move.b	#1,(GameOver_OverText+mapping_frame).w
	move.w	a0,(GameOver_GameText+parent).w
	clr.b	(Time_Over_flag_2P).w
.finished:
	clr.b	(Update_HUD_timer).w
	clr.b	(Update_HUD_timer_2P).w
	move.b	#8,routine(a0)	; => Obj01_Gone
	move.w	#MusID_GameOver,d0
	jsr	(PlayMusic).l
	moveq	#PLCID_GameOver,d0
	jmp	(LoadPLC).l
.reset:
	tst.b	(Time_Over_flag).w
	beq.s	.player2TimeOver
	tst.b	(Time_Over_flag_2P).w
	beq.s	.respawn
	move.w	#0,restart_countdown(a0)
	clr.b	(Update_HUD_timer).w
	clr.b	(Update_HUD_timer_2P).w
	rts
.player2TimeOver:
	tst.b	(Time_Over_flag_2P).w
	beq.s	.respawn
	move.w	#0,restart_countdown(a0)
	move.b	#ObjID_TimeOver,(TimeOver_TimeText+id).w ; load Obj39
	move.b	#ObjID_TimeOver,(TimeOver_OverText+id).w ; load Obj39
	move.b	#2,(TimeOver_TimeText+mapping_frame).w
	move.b	#3,(TimeOver_OverText+mapping_frame).w
	move.w	a0,(TimeOver_TimeText+parent).w
	bra.s	.finished
.respawn:
	move.b	#0,(Scroll_lock).w	; player 2's while his Obj01 runs
	move.b	#$A,routine(a0)	; => Obj01_Respawning
	move.w	(Saved_x_pos_2P).w,x_pos(a0)
	move.w	(Saved_y_pos_2P).w,y_pos(a0)
	move.w	(Saved_art_tile_2P).w,art_tile(a0)
	move.w	(Saved_Solid_bits_2P).w,top_solid_bit(a0)
	clr.w	(Ring_count_2P).w
	clr.b	(Extra_life_flags_2P).w
	move.b	#0,obj_control(a0)
	move.b	#5,anim(a0)
	move.w	#0,x_vel(a0)
	move.w	#0,y_vel(a0)
	move.w	#0,inertia(a0)
	move.b	#1<<status.player.in_air,status(a0)
	move.w	#0,move_lock(a0)
	move.w	#0,restart_countdown(a0)
	rts

; ---------------------------------------------------------------------------
; 2P signpost (Obj0D, a0): player 2 passed it first. Sonic or Knuckles shows
; the face frame instead of Tails'.
; ---------------------------------------------------------------------------
VS_SignpostPlayer2Face:
	cmpi.b	#ObjID_Sonic,(Sidekick+id).w
	bne.s	.return
	move.b	#3,obj0D_finalanim(a0)
	move.b	(Player2_character).w,d0
	ori.b	#$80,d0
	move.b	d0,obj0D_player2face(a0)
.return:
	rts

; Z=0 if the signpost's face is Knuckles' (player 2's if he won, else player 1's)
VS_SignpostKnucklesFace:
	tst.b	obj0D_player2face(a0)
	bmi.s	.player2
	tst.b	(Main_character).w
	rts
.player2:
	btst	#0,obj0D_player2face(a0)
	rts

; Faces for player 2's HUD and 1-up monitors (tools/vs_faces.py)
ArtNem_VSFaceSonic:	BINCLUDE	"art/nemesis/VS face Sonic.nem"
	even
ArtNem_VSFaceKnuckles:	BINCLUDE	"art/nemesis/VS face Knuckles.nem"
	even
