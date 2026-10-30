; ---------------------------------------------------------------------------
; Any character for either player in 2P VS (FeatureKnuckles)
;
; Player 2 picks Tails, Sonic or Knuckles (VS_player2, Options screen). Sonic
; and Knuckles are Obj01 in the Sidekick slot. Obj01 keeps its state in
; "Sonic" RAM (Ctrl_1_Logical, Sonic_top_speed, Camera_Y_pos_bias, the camera
; bounds, Sonic_Dust...), so player 2's Obj01 runs with that RAM exchanged
; with player 2's ("Tails") RAM (VS_SwapPlayerContext) and exchanged back
; afterwards; Main_character then says who player 2 is. Everything Obj01 does
; for the player slot itself (rings, lives, star posts, position record,
; VRAM) checks a0 instead. P2_context_active is set while that happens.
;
; Player 1 plays Tails when the player select says MILES/TAILS ALONE. Tails
; (Obj02) keeps his state in the "Tails" RAM, so as player 1 he runs with the
; same exchange (player 1's RAM under Tails' names), his art goes to Sonic's
; VRAM and his tails (VS_Tails_Tails_P1) follow it.
; ---------------------------------------------------------------------------

; Obj01 in the Sidekick slot (a0 = Sidekick)
VS_Obj01Player2:
	move.w	(Tails_Max_Y_pos).w,(VS_Max_Y_pos_target).w	; see below
	bsr.s	VS_SwapPlayerContext
	st.b	(P2_context_active).w
	jsr	(Obj01_Normal).l	; (debug placement belongs to player 1)
	sf.b	(P2_context_active).w
	bra.s	VS_SwapPlayerContext	; exchange the RAM back

; Obj02 in the MainCharacter slot in 2P VS (a0 = MainCharacter)
VS_Obj02Player1:
	; Debug uses physical P1 input, camera and DPLC state, before any exchange.
	tst.w	(Debug_placement_mode).w
	beq.s	.notPlacing
	jmp	(DebugMode).l
.notPlacing:
	jsr	(Tails_TryEnterDebug).l
	tst.b	d0
	beq.s	.normal
	rts
.normal:
	move.w	(Camera_Max_Y_pos_target).w,(VS_Max_Y_pos_target).w	; (not his: keep it)
	bsr.s	VS_SwapPlayerContext
	st.b	(P2_context_active).w
	jsr	(Obj02_Normal).l
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
	bsr.w	VS_Player2Option
	tst.b	d0		; VSPlayer2_Tails?
	beq.s	.return
	lea	VS_Player2Characters(pc),a1
	move.b	(a1,d0.w),(Player2_character).w
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
	bsr.w	VS_Player1IsTails	; player 1's life icon (and Sonic 1-up icon) is Tails'
	beq.s	.player2
	moveq	#PLCID_MilesLife,d0
	tst.b	(Graphics_Flags).w
	bpl.s	.miles
	moveq	#PLCID_TailsLife,d0
.miles:
	jsr	(LoadPLC).l
.player2:
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
	jsr	(VS_SonicAgainstKnuckles).l
	beq.s	.done
	moveq	#PLCID_KnucklesLife2PSonic,d0	; against Sonic: his colours off Sonic's
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

; ---------------------------------------------------------------------------
; Level start (InitPlayers, 2P VS): Tails as player 1 for MILES/TAILS ALONE.
; ---------------------------------------------------------------------------
VS_InitPlayer1:
	bsr.s	VS_Player1IsTails
	beq.s	.return
	move.b	#ObjID_Tails,(MainCharacter+id).w
	move.b	#$F,(MainCharacter+y_radius).w
	addq.w	#4,(MainCharacter+y_pos).w
.return:
	rts

; Z=0 if player 1 plays Tails in this 2P VS game (not in demos)
VS_Player1IsTails:
	tst.w	(Two_player_mode).w
	beq.s	.no
	tst.w	(Demo_mode_flag).w
	bne.s	.no
	cmpi.w	#PlayerOption_TailsAlone,(Player_option).w
	bne.s	.no
	andi	#~4,ccr		; Z=0
	rts
.no:
	ori	#4,ccr		; Z=1
	rts

; Obj02_Init for player 1 in VS (RAM exchanged): Sonic's VRAM, player 1's star
; post, and his tails in VS_Tails_Tails_P1
VS_Obj02Player1Init:
	move.w	#make_art_tile(ArtTile_ArtUnc_Sonic,0,0),art_tile(a0)
	jsr	(Adjust2PArtPointer).l
	move.b	#$C,top_solid_bit(a0)
	move.b	#$D,lrb_solid_bit(a0)
	move.w	x_pos(a0),(Saved_x_pos).w
	move.w	y_pos(a0),(Saved_y_pos).w
	move.w	art_tile(a0),(Saved_art_tile).w
	move.w	top_solid_bit(a0),(Saved_Solid_bits).w
	move.b	#0,flips_remaining(a0)
	move.b	#4,flip_speed(a0)
	move.b	#30,air_left(a0)
	move.b	#ObjID_TailsTails,(VS_Tails_Tails_P1+id).w
	move.w	a0,(VS_Tails_Tails_P1+parent).w
	st.b	(VS_TailsTails_P1_DPLC).w
	jmp	(Obj02_Control).l

; LoadTailsTailsDynPLC for player 1's tails (a0 = VS_Tails_Tails_P1)
VS_LoadTailsTailsP1DynPLC:
	move.b	mapping_frame(a0),d0
	cmp.b	(VS_TailsTails_P1_DPLC).w,d0
	beq.s	.return
	move.b	d0,(VS_TailsTails_P1_DPLC).w
	lea	(MapRUnc_Tails).l,a2
	move.w	#tiles_to_bytes(ArtTile_ArtUnc_Sonic+$10),d4
	move.l	#ArtUnc_Tails,d6
	jmp	(LoadDynPLC).l
.return:
	rts

; Obj02 death as player 1 in VS: player 1's lives, time over, star post and
; rings. Scroll_lock_P2 and the camera are player 1's here.
VS_Obj02Player1GameOver:
	addq.b	#1,(Update_HUD_lives).w
	subq.b	#1,(Life_count).w
	bne.s	.reset
	move.w	#0,restart_countdown(a0)
	move.b	#ObjID_GameOver,(GameOver_GameText+id).w ; load Obj39
	move.b	#ObjID_GameOver,(GameOver_OverText+id).w ; load Obj39
	move.b	#1,(GameOver_OverText+mapping_frame).w
	move.w	a0,(GameOver_GameText+parent).w
	clr.b	(Time_Over_flag).w
.finished:
	clr.b	(Update_HUD_timer).w
	clr.b	(Update_HUD_timer_2P).w
	move.b	#8,routine(a0)	; => Obj02_Gone
	move.w	#MusID_GameOver,d0
	jsr	(PlayMusic).l
	moveq	#PLCID_GameOver,d0
	jmp	(LoadPLC).l
.reset:
	tst.b	(Time_Over_flag_2P).w
	beq.s	.player1TimeOver
	tst.b	(Time_Over_flag).w
	beq.s	.respawn
	move.w	#0,restart_countdown(a0)
	clr.b	(Update_HUD_timer).w
	clr.b	(Update_HUD_timer_2P).w
	move.b	#8,routine(a0)
	rts
.player1TimeOver:
	tst.b	(Time_Over_flag).w
	beq.s	.respawn
	move.w	#0,restart_countdown(a0)
	move.b	#ObjID_TimeOver,(TimeOver_TimeText+id).w ; load Obj39
	move.b	#ObjID_TimeOver,(TimeOver_OverText+id).w ; load Obj39
	move.b	#2,(TimeOver_TimeText+mapping_frame).w
	move.b	#3,(TimeOver_OverText+mapping_frame).w
	move.w	a0,(TimeOver_TimeText+parent).w
	bra.s	.finished
.respawn:
	move.b	#0,(Scroll_lock_P2).w	; player 1's while his Tails runs
	move.b	#$A,routine(a0)	; => Obj02_Respawning
	move.w	(Saved_x_pos).w,x_pos(a0)
	move.w	(Saved_y_pos).w,y_pos(a0)
	move.w	(Saved_art_tile).w,art_tile(a0)
	move.w	(Saved_Solid_bits).w,top_solid_bit(a0)
	clr.w	(Ring_count).w
	clr.b	(Extra_life_flags).w
	move.b	#0,obj_control(a0)
	move.b	#5,anim(a0)
	move.w	#0,x_vel(a0)
	move.w	#0,y_vel(a0)
	move.w	#0,inertia(a0)
	move.b	#1<<status.player.in_air,status(a0)
	move.w	#0,move_lock(a0)
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
ArtNem_VSFaceKnucklesSonic:	BINCLUDE	"art/nemesis/VS face Knuckles Sonic.nem"	; against Sonic
	even
