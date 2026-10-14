; ---------------------------------------------------------------------------
; Knuckles (FeatureKnuckles), ported from the Knuckles in Sonic 2 disassembly
; (s2disasm's knuckles-in-sonic-2 branch; resources from tools/import_kis2.py).
; As in that game, Knuckles is Obj01 with Knuckles' art, mappings, animations
; and moves, so every object treats him as Sonic. Main_character says who is
; in the Sonic slot; the player select entries (Player_option) map to it and
; to Player_mode, so "Knuckles and Tails" is a Sonic and Tails game for all
; the sidekick logic.
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------
; Set Player_mode and Main_character from Player_option
; ---------------------------------------------------------------------------
ApplyPlayerOption:
	moveq	#0,d0
	move.w	(Player_option).w,d0
	cmpi.w	#PlayerOption_Count,d0
	blo.s	+
	moveq	#0,d0
+
	add.w	d0,d0
	moveq	#0,d1
	move.b	PlayerOption_Modes(pc,d0.w),d1
	move.w	d1,(Player_mode).w
	move.b	PlayerOption_Modes+1(pc,d0.w),(Main_character).w
	rts

; Player_mode and Main_character of each PlayerOption_*
PlayerOption_Modes:
	dc.b	PlayerMode_SonicTails, CharID_Sonic	; PlayerOption_SonicTails
	dc.b	PlayerMode_SonicAlone, CharID_Sonic	; PlayerOption_SonicAlone
	dc.b	PlayerMode_TailsAlone, CharID_Sonic	; PlayerOption_TailsAlone
	if FeatureKnuckles
	dc.b	PlayerMode_SonicTails, CharID_Knuckles	; PlayerOption_KnucklesTails
	dc.b	PlayerMode_SonicAlone, CharID_Knuckles	; PlayerOption_KnucklesAlone
	endif
PlayerOption_Modes_End:
	if (PlayerOption_Modes_End-PlayerOption_Modes)<>(PlayerOption_Count*2)
		fatal "PlayerOption_Modes needs one entry per player option"
	endif

	if FeatureKnuckles
; ---------------------------------------------------------------------------
; Level and Special Stage palettes with Knuckles' colours:
; d0 = PalID_BGND or an underwater PalID -> d0 = the Knuckles version if
; Knuckles plays. Other registers are kept.
; ---------------------------------------------------------------------------
Knuckles_PalID:
	tst.b	(Main_character).w
	beq.s	.return
	cmpi.b	#PalID_BGND,d0
	bne.s	+
	moveq	#PalID_BGND_Knuckles,d0
	rts
+
	cmpi.b	#PalID_HPZ_U,d0
	bne.s	+
	moveq	#PalID_HPZ_U_Knuckles,d0
	rts
+
	cmpi.b	#PalID_CPZ_U,d0
	bne.s	+
	moveq	#PalID_CPZ_U_Knuckles,d0
	rts
+
	cmpi.b	#PalID_ARZ_U,d0
	bne.s	+
	moveq	#PalID_ARZ_U_Knuckles,d0
	rts
+
	cmpi.b	#PalID_SS,d0
	bne.s	.return
	moveq	#PalID_SS_Knuckles,d0
.return:
	rts

; ---------------------------------------------------------------------------
; Knuckles' mappings and DPLCs: in 2P VS the split screen draws 8x16 cells,
; so Knuckles uses tools/knuckles_vs.py's frames there.
; ---------------------------------------------------------------------------
Knuckles_Mappings:	; a0 = Obj01
	tst.b	(Main_character).w
	beq.s	.return
	move.l	#MapUnc_Knuckles,mappings(a0)
	tst.w	(Two_player_mode).w
	beq.s	.return
	move.l	#MapUnc_KnucklesVS,mappings(a0)
.return:
	rts

Knuckles_DPLC:		; -> a2 = DPLC table, d6 = art
	lea	(MapRUnc_Knuckles).l,a2
	move.l	#ArtUnc_Knuckles,d6
	tst.w	(Two_player_mode).w
	beq.s	.return
	lea	(MapRUnc_KnucklesVS).l,a2
	move.l	#ArtUnc_KnucklesVS,d6
.return:
	rts

; ---------------------------------------------------------------------------
; Level start (Level_ClrRam): Knuckles' life icon, and grey shield and
; invincibility monitors and stars, since Sonic's blue is his red and green.
; ---------------------------------------------------------------------------
Knuckles_LevelPLC:
	tst.b	(Main_character).w
	beq.s	.return
	moveq	#PLCID_KnucklesLife,d0
	jmp	(LoadPLC).l
.return:
	rts

; ---------------------------------------------------------------------------
; Act results (Obj3A): KNUCKLES GOT THROUGH needs a K. It goes over the M,
; which only MILES uses (as in Knuckles in Sonic 2).
; ---------------------------------------------------------------------------
Knuckles_ResultsLetterK:
	tst.b	(Main_character).w
	beq.s	.return
	move	sr,-(sp)
	move	#$2700,sr
	move.l	#vdpComm(tiles_to_bytes(ArtTile_ArtNem_ResultsText+$16),VRAM,WRITE),(VDP_control_port).l
	lea	(ArtUnc_ResultsLetterK).l,a1
	moveq	#bytesToLcnt(ArtUnc_ResultsLetterK_End-ArtUnc_ResultsLetterK),d0
-	move.l	(a1)+,(VDP_data_port).l
	dbf	d0,-
	move	(sp)+,sr
.return:
	rts

; ---------------------------------------------------------------------------
; Special Stage. Knuckles' frames (Knuckles in Sonic 2) are $37 tiles longer
; than Sonic's, so Sonic and Tails' frames are unpacked that much further on
; and Knuckles' over Sonic's: Tails' frames follow Knuckles' (LoadSSTailsDynPLC).
; ---------------------------------------------------------------------------
Knuckles_SSDecompressArt:
	lea	(ArtNem_SpecialSonicAndTails).l,a0
	lea	((SSRAM_ArtNem_SpecialSonicAndTails+tiles_to_bytes(SS_KnucklesExtraTiles)) & $FFFFFF).l,a4
	jsr	(NemDecToRAM).l
	lea	(ArtNem_SpecialKnuckles).l,a0
	lea	(SSRAM_ArtNem_SpecialSonicAndTails & $FFFFFF).l,a4
	jmp	(NemDecToRAM).l

; The Special Stage HUD (Obj5E): Knuckles in Sonic 2 drops the "SONIC" name.
; a2 + d2 = the sub-sprite just set up.
Knuckles_SSHUDFrame:
	tst.b	(Main_character).w
	beq.s	.return
	tst.b	sub2_mapframe-sub2_x_pos(a2,d2.w)	; Sonic's name and rings?
	bne.s	.return
	move.b	#4,sub2_mapframe-sub2_x_pos(a2,d2.w)	; the rings alone
.return:
	rts

; ---------------------------------------------------------------------------
; Continue screen: Z=0 in a Knuckles Alone game (no Tails, as in Knuckles in
; Sonic 2); Knuckles and Tails keep Tails.
; ---------------------------------------------------------------------------
Knuckles_ContinueAlone:
	tst.b	(Main_character).w
	beq.s	.no
	tst.w	(Player_mode).w
	beq.s	.no
	andi	#~4,ccr		; Z=0
	rts
.no:
	ori	#4,ccr		; Z=1
	rts

	if SuperKnucklesOn
; ---------------------------------------------------------------------------
; Super Knuckles' palette (PalCycle_SuperSonic jumps here when Knuckles
; plays), as in Knuckles in Sonic 2: colours 2, 3 and 5 cycle through his
; pinks, also under water; turning back restores his colours (KiS2 put the
; dry ones under water too; here the zone's underwater ones come back).
; Super_Sonic_palette: 1 = turning Super, -1 = cycling, 2 = turning back.
; ---------------------------------------------------------------------------
PalCycle_SuperKnuckles:
	move.b	(Super_Sonic_palette).w,d0
	beq.s	.return
	bmi.s	.cycle
	subq.b	#1,d0
	bne.s	.revert
	subq.b	#1,(Palette_timer).w	; the transformation pose plays meanwhile
	bpl.s	.return
	move.b	#-1,(Super_Sonic_palette).w
	move.w	#0,(Palette_frame).w
	move.b	#0,(MainCharacter+obj_control).w	; give Knuckles back his controls
.return:
	rts
.revert:
	moveq	#0,d0
	move.w	d0,(Palette_frame).w
	move.b	d0,(Super_Sonic_palette).w
	lea	(CyclingPal_SKRevert).l,a0
	lea	(Normal_palette+2*2).w,a1
	move.l	(a0),(a1)+
	move.w	4(a0),2(a1)
	tst.b	(Water_flag).w
	beq.s	.return
	lea	(Pal_HPZ_U_Knuckles).l,a0
	cmpi.b	#hidden_palace_zone,(Current_Zone).w
	beq.s	+
	lea	(Pal_CPZ_U_Knuckles).l,a0
	cmpi.b	#chemical_plant_zone,(Current_Zone).w
	beq.s	+
	lea	(Pal_ARZ_U_Knuckles).l,a0
+
	lea	(Underwater_palette+2*2).w,a1
	move.l	2*2(a0),(a1)+
	move.w	5*2(a0),2(a1)
	rts
.cycle:
	subq.b	#1,(Palette_timer).w
	bpl.s	.return
	move.b	#2,(Palette_timer).w
	lea	(CyclingPal_SKCycle).l,a0
	move.w	(Palette_frame).w,d0
	addq.w	#6,(Palette_frame).w
	cmpi.w	#CyclingPal_SKCycle_End-CyclingPal_SKCycle,(Palette_frame).w
	blo.s	+
	move.w	#0,(Palette_frame).w
	move.b	#14,(Palette_timer).w	; hold the last colours a little
+
	lea	(Normal_palette+2*2).w,a1
	move.l	(a0,d0.w),(a1)+
	move.w	4(a0,d0.w),2(a1)
	tst.b	(Water_flag).w
	beq.w	.return
	lea	(Underwater_palette+2*2).w,a1
	move.l	(a0,d0.w),(a1)+
	move.w	4(a0,d0.w),2(a1)
	rts

; colours 2, 3 and 5 per frame (Knuckles in Sonic 2)
CyclingPal_SKCycle:	BINCLUDE	"art/palettes/Super Knuckles cycle.bin"
CyclingPal_SKCycle_End:
CyclingPal_SKRevert:	BINCLUDE	"art/palettes/Super Knuckles revert.bin"
	even
	endif

; ---------------------------------------------------------------------------
; Balancing, as in Knuckles in Sonic 2: one balancing animation; facing away
; from the edge, Knuckles turns round and starts it further on.
; d1 = position on the object and d2 = its width - 2 (as in Obj01_NotRight)
; ---------------------------------------------------------------------------
Knuckles_BalanceOnObj:
	cmpi.w	#2,d1
	blt.s	Knuckles_BalanceLeftEdge
	cmp.w	d2,d1
	bge.s	Knuckles_BalanceRightEdge
	jmp	(Sonic_Lookup).l

; on the edge of the level
Knuckles_BalanceOnLevel:
	cmpi.b	#3,next_tilt(a0)
	beq.s	Knuckles_BalanceRightEdge
	cmpi.b	#3,tilt(a0)
	beq.s	Knuckles_BalanceLeftEdge
	jmp	(Sonic_Lookup).l

Knuckles_BalanceRightEdge:
	move.b	#AniIDSonAni_Balance,anim(a0)
	btst	#status.player.x_flip,status(a0)	; facing the edge?
	beq.s	+
	bclr	#status.player.x_flip,status(a0)
	bra.s	Knuckles_BalanceTurned
Knuckles_BalanceLeftEdge:
	move.b	#AniIDSonAni_Balance,anim(a0)
	btst	#status.player.x_flip,status(a0)	; facing the edge?
	bne.s	+
	bset	#status.player.x_flip,status(a0)
Knuckles_BalanceTurned:
	move.b	#0,anim_frame_duration(a0)
	move.b	#4,anim_frame(a0)
	move.w	#(AniIDSonAni_Balance<<8)|AniIDSonAni_Balance,anim(a0)
+
	jmp	(Obj01_ResetScr).l

; ---------------------------------------------------------------------------
; Knuckles' animation (Sonic_Animate jumps here): Sonic 2's routine with the
; changes of Knuckles in Sonic 2 (no Super graphics, other tumbling frames,
; faster pushing).
; ---------------------------------------------------------------------------
Knuckles_Animate:
	lea	(KnucklesAniData).l,a1
	moveq	#0,d0
	move.b	anim(a0),d0
	cmp.b	prev_anim(a0),d0	; has animation changed?
	beq.s	KAnim_Do		; if not, branch
	move.b	d0,prev_anim(a0)	; set previous animation
	move.b	#0,anim_frame(a0)	; reset animation frame
	move.b	#0,anim_frame_duration(a0)	; reset frame duration
	bclr	#status.player.pushing,status(a0)
KAnim_Do:
	add.w	d0,d0
	adda.w	(a1,d0.w),a1	; calculate address of appropriate animation script
	move.b	(a1),d0
	bmi.s	KAnim_WalkRun	; if animation is walk/run/roll/jump, branch
	move.b	status(a0),d1
	andi.b	#1<<status.player.x_flip,d1
	andi.b	#~(1<<render_flags.x_flip|1<<render_flags.y_flip),render_flags(a0)
	or.b	d1,render_flags(a0)
	subq.b	#1,anim_frame_duration(a0)	; subtract 1 from frame duration
	bpl.s	KAnim_Delay			; if time remains, branch
	move.b	d0,anim_frame_duration(a0)	; load frame duration
KAnim_Do2:
	moveq	#0,d1
	move.b	anim_frame(a0),d1	; load current frame number
	move.b	1(a1,d1.w),d0		; read sprite number from script
	cmpi.b	#$F0,d0
	bhs.s	KAnim_End_FF		; if animation is complete, branch
KAnim_Next:
	move.b	d0,mapping_frame(a0)	; load sprite number
	addq.b	#1,anim_frame(a0)	; go to next frame
KAnim_Delay:
	rts
; ===========================================================================
KAnim_End_FF:
	addq.b	#1,d0		; is the end flag = $FF?
	bne.s	KAnim_End_FE	; if not, branch
	move.b	#0,anim_frame(a0)	; restart the animation
	move.b	1(a1),d0	; read sprite number
	bra.s	KAnim_Next
; ===========================================================================
KAnim_End_FE:
	addq.b	#1,d0		; is the end flag = $FE?
	bne.s	KAnim_End_FD	; if not, branch
	move.b	2(a1,d1.w),d0	; read the next byte in the script
	sub.b	d0,anim_frame(a0)	; jump back d0 bytes in the script
	sub.b	d0,d1
	move.b	1(a1,d1.w),d0	; read sprite number
	bra.s	KAnim_Next
; ===========================================================================
KAnim_End_FD:
	addq.b	#1,d0			; is the end flag = $FD?
	bne.s	KAnim_End		; if not, branch
	move.b	2(a1,d1.w),anim(a0)	; read next byte, run that animation
KAnim_End:
	rts
; ===========================================================================
KAnim_WalkRun:
	addq.b	#1,d0		; is the start flag = $FF?
	bne.w	KAnim_Roll	; if not, branch
	moveq	#0,d0		; is animation walking/running?
	move.b	flip_angle(a0),d0	; if not, branch
	bne.w	KAnim_Tumble
	moveq	#0,d1
	move.b	angle(a0),d0	; get Knuckles' angle
	bmi.s	+
	beq.s	+
	subq.b	#1,d0
+
	move.b	status(a0),d2
	andi.b	#1<<status.player.x_flip,d2	; is Knuckles mirrored horizontally?
	bne.s	+				; if yes, branch
	not.b	d0				; reverse angle
+
	addi.b	#$10,d0		; add $10 to angle
	bpl.s	+		; if angle is $0-$7F, branch
	moveq	#1<<render_flags.x_flip|1<<render_flags.y_flip,d1
+
	andi.b	#~(1<<render_flags.x_flip|1<<render_flags.y_flip),render_flags(a0)
	eor.b	d1,d2
	or.b	d2,render_flags(a0)
	btst	#status.player.pushing,status(a0)
	bne.w	KAnim_Push
	lsr.b	#4,d0		; divide angle by 16
	andi.b	#6,d0		; angle must be 0, 2, 4 or 6
	mvabs.w	inertia(a0),d2	; get Knuckles' "speed" for animation purposes
	btst	#status_secondary.sliding,status_secondary(a0)
	beq.s	+
	add.w	d2,d2
+
	lea	(KnucklesAni_Run).l,a1	; use running animation
	cmpi.w	#$600,d2		; is Knuckles at running speed?
	bhs.s	+			; use running animation
	lea	(KnucklesAni_Walk).l,a1	; if yes, branch
	add.b	d0,d0
+
	add.b	d0,d0
	move.b	d0,d3
	moveq	#0,d1
	move.b	anim_frame(a0),d1
	move.b	1(a1,d1.w),d0
	cmpi.b	#-1,d0
	bne.s	+
	move.b	#0,anim_frame(a0)
	move.b	1(a1),d0
+
	move.b	d0,mapping_frame(a0)
	add.b	d3,mapping_frame(a0)
	subq.b	#1,anim_frame_duration(a0)
	bpl.s	.return
	neg.w	d2
	addi.w	#$800,d2
	bpl.s	+
	moveq	#0,d2
+
	lsr.w	#8,d2
	move.b	d2,anim_frame_duration(a0)	; modify frame duration
	addq.b	#1,anim_frame(a0)		; modify frame number
.return:
	rts
; ===========================================================================
KAnim_Tumble:
	move.b	flip_angle(a0),d0
	moveq	#0,d1
	move.b	status(a0),d2
	andi.b	#1<<status.player.x_flip,d2
	bne.s	KAnim_Tumble_Left

	andi.b	#~(1<<render_flags.x_flip|1<<render_flags.y_flip),render_flags(a0)
	addi.b	#$B,d0
	divu.w	#$16,d0
	addi.b	#$31,d0		; Knuckles' tumbling frames start at $31
	move.b	d0,mapping_frame(a0)
	move.b	#0,anim_frame_duration(a0)
	rts
; ===========================================================================
KAnim_Tumble_Left:
	andi.b	#~(1<<render_flags.x_flip|1<<render_flags.y_flip),render_flags(a0)
	tst.b	flip_turned(a0)
	beq.s	+
	ori.b	#1<<render_flags.x_flip,render_flags(a0)
	addi.b	#$B,d0
	bra.s	++
+
	ori.b	#1<<render_flags.x_flip|1<<render_flags.y_flip,render_flags(a0)
	neg.b	d0
	addi.b	#$8F,d0
+
	divu.w	#$16,d0
	addi.b	#$31,d0
	move.b	d0,mapping_frame(a0)
	move.b	#0,anim_frame_duration(a0)
	rts
; ===========================================================================
KAnim_Roll:
	subq.b	#1,anim_frame_duration(a0)	; subtract 1 from frame duration
	bpl.w	KAnim_Delay			; if time remains, branch
	addq.b	#1,d0		; is the start flag = $FE?
	bne.s	KAnim_Push	; if not, branch
	mvabs.w	inertia(a0),d2
	lea	(KnucklesAni_Roll2).l,a1
	cmpi.w	#$600,d2
	bhs.s	+
	lea	(KnucklesAni_Roll).l,a1
+
	neg.w	d2
	addi.w	#$400,d2
	bpl.s	+
	moveq	#0,d2
+
	lsr.w	#8,d2
	move.b	d2,anim_frame_duration(a0)
	move.b	status(a0),d1
	andi.b	#1<<status.player.x_flip,d1
	andi.b	#~(1<<render_flags.x_flip|1<<render_flags.y_flip),render_flags(a0)
	or.b	d1,render_flags(a0)
	bra.w	KAnim_Do2
; ===========================================================================
KAnim_Push:
	subq.b	#1,anim_frame_duration(a0)	; subtract 1 from frame duration
	bpl.w	KAnim_Delay			; if time remains, branch
	move.w	inertia(a0),d2
	bmi.s	+
	neg.w	d2
+
	addi.w	#$800,d2
	bpl.s	+
	moveq	#0,d2
+
	lsr.w	#8,d2		; Knuckles pushes faster than Sonic
	move.b	d2,anim_frame_duration(a0)
	lea	(KnucklesAni_Push).l,a1
	move.b	status(a0),d1
	andi.b	#1<<status.player.x_flip,d1
	andi.b	#~(1<<render_flags.x_flip|1<<render_flags.y_flip),render_flags(a0)
	or.b	d1,render_flags(a0)
	bra.w	KAnim_Do2

; ---------------------------------------------------------------------------
; Animation scripts - Knuckles (from Knuckles in Sonic 2, which took them from
; Sonic & Knuckles). The IDs are Sonic's (AniIDSonAni_*), then AniIDKnuxAni_*.
; ---------------------------------------------------------------------------
KnucklesAniData:		offsetTable
		offsetTableEntry.w KnucklesAni_Walk		;  0 ;   0
		offsetTableEntry.w KnucklesAni_Run		;  1 ;   1
		offsetTableEntry.w KnucklesAni_Roll		;  2 ;   2
		offsetTableEntry.w KnucklesAni_Roll2		;  3 ;   3
		offsetTableEntry.w KnucklesAni_Push		;  4 ;   4
		offsetTableEntry.w KnucklesAni_Wait		;  5 ;   5
		offsetTableEntry.w KnucklesAni_Balance		;  6 ;   6
		offsetTableEntry.w KnucklesAni_LookUp		;  7 ;   7
		offsetTableEntry.w KnucklesAni_Duck		;  8 ;   8
		offsetTableEntry.w KnucklesAni_Spindash		;  9 ;   9
		offsetTableEntry.w KnucklesAni_Wait		; 10 ;  $A ; Blink: Sonic only
		offsetTableEntry.w KnucklesAni_Pull		; 11 ;  $B
		offsetTableEntry.w KnucklesAni_Balance2		; 12 ;  $C
		offsetTableEntry.w KnucklesAni_Stop		; 13 ;  $D
		offsetTableEntry.w KnucklesAni_Float		; 14 ;  $E
		offsetTableEntry.w KnucklesAni_Float2		; 15 ;  $F
		offsetTableEntry.w KnucklesAni_Spring		; 16 ; $10
		offsetTableEntry.w KnucklesAni_Hang		; 17 ; $11
		offsetTableEntry.w KnucklesAni_Dash2		; 18 ; $12
		offsetTableEntry.w KnucklesAni_S3EndingPose	; 19 ; $13
		offsetTableEntry.w KnucklesAni_WFZHang		; 20 ; $14
		offsetTableEntry.w KnucklesAni_Bubble		; 21 ; $15
		offsetTableEntry.w KnucklesAni_DeathBW		; 22 ; $16
		offsetTableEntry.w KnucklesAni_Drown		; 23 ; $17
		offsetTableEntry.w KnucklesAni_Death		; 24 ; $18
		offsetTableEntry.w KnucklesAni_OilSlide		; 25 ; $19
		offsetTableEntry.w KnucklesAni_Hurt		; 26 ; $1A
		offsetTableEntry.w KnucklesAni_OilSlide		; 27 ; $1B
		offsetTableEntry.w KnucklesAni_Blank		; 28 ; $1C
		offsetTableEntry.w KnucklesAni_Balance		; 29 ; $1D ; Balance3: Sonic only
		offsetTableEntry.w KnucklesAni_Balance		; 30 ; $1E ; Balance4: Sonic only
		offsetTableEntry.w KnucklesAni_Transform	; 31 ; $1F
		offsetTableEntry.w KnucklesAni_Wait		; 32 ; $20 ; Lying: Sonic only
		offsetTableEntry.w KnucklesAni_Wait		; 33 ; $21 ; LieDown: Sonic only
		offsetTableEntry.w KnucklesAni_Victory		; 34 ; $22
KnuxAni_Glide_ptr:		offsetTableEntry.w KnucklesAni_Gliding		; 35 ; $23
KnuxAni_FallAfterGlide_ptr:	offsetTableEntry.w KnucklesAni_FallFromGlide	; 36 ; $24
KnuxAni_ClimbLedge_ptr:		offsetTableEntry.w KnucklesAni_GetUp		; 37 ; $25
KnuxAni_LandAfterGlide_ptr:	offsetTableEntry.w KnucklesAni_HardFall		; 38 ; $26
KnuxAni_ShadowBox_ptr:		offsetTableEntry.w KnucklesAni_Badass		; 39 ; $27

KnucklesAni_Walk:	dc.b $FF,  7,  8,  1,  2,  3,  4,  5,  6,$FF
	even
KnucklesAni_Run:	dc.b $FF,$21,$22,$23,$24,$FF,$FF,$FF,$FF,$FF
	even
KnucklesAni_Roll:	dc.b $FE,$9A,$96,$9A,$97,$9A,$98,$9A,$99,$FF
	even
KnucklesAni_Roll2:	dc.b $FE,$9A,$96,$9A,$97,$9A,$98,$9A,$99,$FF
	even
KnucklesAni_Push:	dc.b $FD,$CE,$CF,$D0,$D1,$FF,$FF,$FF,$FF,$FF
	even
KnucklesAni_Wait:
	dc.b   5,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56
	dc.b $56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56
	dc.b $56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56
	dc.b $56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$D2
	dc.b $D2,$D2,$D3,$D3,$D3,$D2,$D2,$D2,$D3,$D3,$D3,$D2,$D2
	dc.b $D2,$D3,$D3,$D3,$D2,$D2,$D2,$D3,$D3,$D3,$D2,$D2,$D2
	dc.b $D3,$D3,$D3,$D2,$D2,$D2,$D3,$D3,$D3,$D2,$D2,$D2,$D3
	dc.b $D3,$D3,$D2,$D2,$D2,$D3,$D3,$D3,$D2,$D2,$D2,$D3,$D3
	dc.b $D3,$D4,$D4,$D4,$D4,$D4,$D7,$D8,$D9,$DA,$DB,$D8,$D9
	dc.b $DA,$DB,$D8,$D9,$DA,$DB,$D8,$D9,$DA,$DB,$D8,$D9,$DA
	dc.b $DB,$D8,$D9,$DA,$DB,$D8,$D9,$DA,$DB,$D8,$D9,$DA,$DB
	dc.b $DC,$DD,$DC,$DD,$DE,$DE,$D8,$D7,$FF
	even
KnucklesAni_Balance:
	dc.b   3,$9F,$9F,$A0,$A0,$A1,$A1,$A2,$A2,$A3,$A3,$A4,$A4
	dc.b $A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5
	dc.b $A5,$A5,$A6,$A6,$A6,$A7,$A7,$A7,$A8,$A8,$A9,$A9,$AA
	dc.b $AA,$FE,  6
	even
KnucklesAni_LookUp:	dc.b   5,$D5,$D6,$FE,  1
	even
KnucklesAni_Duck:	dc.b   5,$9B,$9C,$FE,  1
	even
KnucklesAni_Spindash:	dc.b   0,$86,$87,$86,$88,$86,$89,$86,$8A,$86,$8B,$FF
	even
KnucklesAni_Pull:	dc.b  $F,$8F,$FF
	even
KnucklesAni_Balance2:
	dc.b   3,$A1,$A1,$A2,$A2,$A3,$A3,$A4,$A4,$A5,$A5,$A5,$A5
	dc.b $A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A6,$A6
	dc.b $A6,$A7,$A7,$A7,$A8,$A8,$A9,$A9,$AA,$AA,$FE
	dc.b   6
	even
KnucklesAni_Stop:	dc.b   3,$9D,$9E,$9F,$A0,$FD,	0
	even
KnucklesAni_Float:	dc.b   7,$C0,$FF
	even
KnucklesAni_Float2:	dc.b   5,$C0,$C1,$C2,$C3,$C4,$C5,$C6,$C7,$C8,$C9,$FF
	even
KnucklesAni_Spring:	dc.b $2F,$8E,$FD,  0
	even
KnucklesAni_Hang:	dc.b   1,$AE,$AF,$FF
	even
KnucklesAni_Dash2:	dc.b  $F,$43,$43,$43,$FE,  1
	even
KnucklesAni_S3EndingPose:
	dc.b   5,$B1,$B2,$B2,$B2,$B3,$B4,$FE,  1,  7,$B1,$B3,$B3
	dc.b $B3,$B3,$B3,$B3,$B2,$B3,$B4,$B3,$FE,  4
	even
KnucklesAni_WFZHang:	dc.b $13,$91,$FF
	even
KnucklesAni_Bubble:	dc.b  $B,$B0,$B0,  3,  4,$FD,  0
	even
KnucklesAni_DeathBW:	dc.b $20,$AC,$FF
	even
KnucklesAni_Drown:	dc.b $20,$AD,$FF
	even
KnucklesAni_Death:	dc.b $20,$AB,$FF
	even
KnucklesAni_OilSlide:	dc.b   9,$8C,$FF
	even
KnucklesAni_Hurt:	dc.b $40,$8D,$FF
	even
KnucklesAni_Blank:	dc.b $77,  0,$FF
	even
KnucklesAni_Transform:
	dc.b   2,$EB,$EB,$EC,$ED,$EC,$ED,$EC,$ED,$EC,$ED,$EC,$ED
	dc.b $FD,  0
	even
; Sonic & Knuckles' act clear pose (FeatureVictoryPoses), as in s1_improvements
KnucklesAni_Victory:	dc.b   5,$B1,$B2,$B2,$B2,$B3,$B4,$FE,  1
	even
KnucklesAni_Gliding:	dc.b $1F,$C0,$FF
	even
KnucklesAni_FallFromGlide:	dc.b   7,$CA,$CB,$FE,	 1
	even
KnucklesAni_GetUp:	dc.b  $F,$CD,$FD,  0
	even
KnucklesAni_HardFall:	dc.b  $F,$9C,$FD,  0
	even
KnucklesAni_Badass:
	dc.b   5,$D8,$D9,$DA,$DB,$D8,$D9,$DA,$DB,$D8,$D9,$DA,$DB
	dc.b $D8,$D9,$DA,$DB,$D8,$D9,$DA,$DB,$D8,$D9,$DA,$DB,$D8
	dc.b $D9,$DA,$DB,$D8,$D9,$DA,$DB,$DC,$DD,$DC,$DD,$DE,$DE
	dc.b $FF
	even

; ---------------------------------------------------------------------------
; Knuckles' art, mappings and DPLCs (tools/import_kis2.py). The art is just
; under 128 KiB and is aligned so no DPLC transfer crosses a 128 KiB boundary.
; ---------------------------------------------------------------------------
MapUnc_Knuckles:	include	"mappings/sprite/Knuckles.asm"
MapRUnc_Knuckles:	include	"mappings/spriteDPLC/Knuckles.asm"
	align	$20000
ArtUnc_Knuckles:	BINCLUDE	"art/uncompressed/Knuckles' art.bin"
ArtUnc_Knuckles_End:
	if (ArtUnc_Knuckles_End-ArtUnc_Knuckles)>$20000
		fatal "Knuckles' art must fit in one 128 KiB bank"
	endif
; 2P VS (tools/knuckles_vs.py), also in a bank of its own (right after the
; one above, so the alignment wastes nothing)
	align	$20000
ArtUnc_KnucklesVS:	BINCLUDE	"art/uncompressed/Knuckles VS.bin"
ArtUnc_KnucklesVS_End:
	include	"mappings/sprite/Knuckles VS.asm"	; MapUnc_KnucklesVS
	include	"mappings/spriteDPLC/Knuckles VS.asm"	; MapRUnc_KnucklesVS
ArtUnc_SignpostKnuckles:	BINCLUDE	"art/uncompressed/Signpost Knuckles.bin"	; 2P VS signpost

; ---------------------------------------------------------------------------
; Knuckles' HUD, monitor, signpost and slot machine art (tools/import_kis2.py)
; ---------------------------------------------------------------------------
ArtNem_KnucklesLife:		BINCLUDE	"art/nemesis/Knuckles lives counter.nem"
	even
ArtNem_MiniKnuckles:		BINCLUDE	"art/nemesis/Knuckles continue.nem"
	even
ArtNem_EndingKnuckles:		BINCLUDE	"art/nemesis/Final image of Knuckles.nem"
	even
ArtNem_SpecialKnuckles:		BINCLUDE	"art/nemesis/Knuckles animation frames in special stage.nem"
	even
ArtNem_PowerupsKnucklesPatch:	BINCLUDE	"art/nemesis/Monitor Knuckles patch.nem"
	even
ArtNem_Invincible_stars_Knuckles:	BINCLUDE	"art/nemesis/Invincibility stars Knuckles.nem"
	even
ArtNem_SignpostKnucklesPatch:	BINCLUDE	"art/nemesis/Signpost Knuckles patch.nem"
	even
ArtUnc_CNZSlotPicKnuckles:	BINCLUDE	"art/uncompressed/Slot picture Knuckles.bin"	; replaces Sonic's picture
ArtUnc_ResultsLetterK:		BINCLUDE	"art/uncompressed/Results letter K.bin"	; replaces the results' M
ArtUnc_ResultsLetterK_End:

; ---------------------------------------------------------------------------
; Object layouts for Knuckles (1P games): ObjectsManager_Init calls this with
; a0 = the act's layout and d0 = its offset in Off_Objects. The acts KiS2
; changed for Knuckles (invisible walls, path swappers, monitors and springs
; for his lower jump and his climbing; tools/import_kis2.py) get KiS2's
; layout; 0 keeps Sonic's.
; ---------------------------------------------------------------------------
Knuckles_ObjectLayout:
	tst.b	(Main_character).w
	beq.s	.return
	tst.w	(Two_player_mode).w
	bne.s	.return
	move.w	d0,d1
	add.w	d1,d1
	move.l	Knuckles_ObjectLayouts(pc,d1.w),d1
	beq.s	.return
	movea.l	d1,a0
.return:
	rts

Knuckles_ObjectLayouts: zoneOrderedTable 4,2
	; EHZ
	zoneTableEntry.l	Objects_Knuckles_EHZ_1	; Act 1
	zoneTableEntry.l	Objects_Knuckles_EHZ_2	; Act 2
	; Zone 1
	zoneTableEntry.l	0	; Act 1
	zoneTableEntry.l	0	; Act 2
	; WZ
	zoneTableEntry.l	0	; Act 1
	zoneTableEntry.l	0	; Act 2
	; Zone 3
	zoneTableEntry.l	0	; Act 1
	zoneTableEntry.l	0	; Act 2
	; MTZ
	zoneTableEntry.l	Objects_Knuckles_MTZ_1	; Act 1
	zoneTableEntry.l	Objects_Knuckles_MTZ_2	; Act 2
	; MTZ
	zoneTableEntry.l	Objects_Knuckles_MTZ_3	; Act 1
	zoneTableEntry.l	Objects_Knuckles_MTZ_3	; Act 2
	; WFZ
	zoneTableEntry.l	Objects_Knuckles_WFZ_1	; Act 1
	zoneTableEntry.l	0	; Act 2
	; HTZ
	zoneTableEntry.l	Objects_Knuckles_HTZ_1	; Act 1
	zoneTableEntry.l	Objects_Knuckles_HTZ_2	; Act 2
	; HPZ
	zoneTableEntry.l	0	; Act 1
	zoneTableEntry.l	0	; Act 2
	; Zone 9
	zoneTableEntry.l	0	; Act 1
	zoneTableEntry.l	0	; Act 2
	; OOZ
	zoneTableEntry.l	Objects_Knuckles_OOZ_1	; Act 1
	zoneTableEntry.l	Objects_Knuckles_OOZ_2	; Act 2
	; MCZ
	zoneTableEntry.l	Objects_Knuckles_MCZ_1	; Act 1
	zoneTableEntry.l	Objects_Knuckles_MCZ_2	; Act 2
	; CNZ
	zoneTableEntry.l	Objects_Knuckles_CNZ_1	; Act 1
	zoneTableEntry.l	Objects_Knuckles_CNZ_2	; Act 2
	; CPZ
	zoneTableEntry.l	Objects_Knuckles_CPZ_1	; Act 1
	zoneTableEntry.l	Objects_Knuckles_CPZ_2	; Act 2
	; DEZ
	zoneTableEntry.l	0	; Act 1
	zoneTableEntry.l	0	; Act 2
	; ARZ
	zoneTableEntry.l	Objects_Knuckles_ARZ_1	; Act 1
	zoneTableEntry.l	Objects_Knuckles_ARZ_2	; Act 2
	; SCZ
	zoneTableEntry.l	0	; Act 1
	zoneTableEntry.l	0	; Act 2
    zoneTableEnd

	ObjectLayoutBoundary
Objects_Knuckles_ARZ_1:	BINCLUDE	"level/objects/Knuckles/ARZ_1.bin"
	ObjectLayoutBoundary
Objects_Knuckles_ARZ_2:	BINCLUDE	"level/objects/Knuckles/ARZ_2.bin"
	ObjectLayoutBoundary
Objects_Knuckles_CNZ_1:	BINCLUDE	"level/objects/Knuckles/CNZ_1.bin"
	ObjectLayoutBoundary
Objects_Knuckles_CNZ_2:	BINCLUDE	"level/objects/Knuckles/CNZ_2.bin"
	ObjectLayoutBoundary
Objects_Knuckles_CPZ_1:	BINCLUDE	"level/objects/Knuckles/CPZ_1.bin"
	ObjectLayoutBoundary
Objects_Knuckles_CPZ_2:	BINCLUDE	"level/objects/Knuckles/CPZ_2.bin"
	ObjectLayoutBoundary
Objects_Knuckles_EHZ_1:	BINCLUDE	"level/objects/Knuckles/EHZ_1.bin"
	ObjectLayoutBoundary
Objects_Knuckles_EHZ_2:	BINCLUDE	"level/objects/Knuckles/EHZ_2.bin"
	ObjectLayoutBoundary
Objects_Knuckles_HTZ_1:	BINCLUDE	"level/objects/Knuckles/HTZ_1.bin"
	ObjectLayoutBoundary
Objects_Knuckles_HTZ_2:	BINCLUDE	"level/objects/Knuckles/HTZ_2.bin"
	ObjectLayoutBoundary
Objects_Knuckles_MCZ_1:	BINCLUDE	"level/objects/Knuckles/MCZ_1.bin"
	ObjectLayoutBoundary
Objects_Knuckles_MCZ_2:	BINCLUDE	"level/objects/Knuckles/MCZ_2.bin"
	ObjectLayoutBoundary
Objects_Knuckles_MTZ_1:	BINCLUDE	"level/objects/Knuckles/MTZ_1.bin"
	ObjectLayoutBoundary
Objects_Knuckles_MTZ_2:	BINCLUDE	"level/objects/Knuckles/MTZ_2.bin"
	ObjectLayoutBoundary
Objects_Knuckles_MTZ_3:	BINCLUDE	"level/objects/Knuckles/MTZ_3.bin"
	ObjectLayoutBoundary
Objects_Knuckles_OOZ_1:	BINCLUDE	"level/objects/Knuckles/OOZ_1.bin"
	ObjectLayoutBoundary
Objects_Knuckles_OOZ_2:	BINCLUDE	"level/objects/Knuckles/OOZ_2.bin"
	ObjectLayoutBoundary
Objects_Knuckles_WFZ_1:	BINCLUDE	"level/objects/Knuckles/WFZ_1.bin"
	ObjectLayoutBoundary

	endif	; FeatureKnuckles
