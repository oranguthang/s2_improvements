; ---------------------------------------------------------------------------
; Cheats: the title unlock code and the CHEATS page of the Level Select.
; The settings themselves are saved by code/Settings.asm.
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------
; Title code Up, Down, Down, Down, Left, Right (as in s1_improvements) unlocks
; the Level Select and its CHEATS page. With FeatureTitleMenu it replaces the
; sound test code 19, 65, 9, 17 (see CheckCheats).
; ---------------------------------------------------------------------------
TitleUnlockCheat:
	move.b	(Ctrl_1_Press).w,d1
	andi.b	#button_up_mask|button_down_mask|button_left_mask|button_right_mask,d1
	beq.s	.return
	lea	TitleUnlockCheat_Buttons(pc),a0
	move.w	(Title_unlock_entries).w,d0
	cmp.b	(a0,d0.w),d1
	bne.s	.reset
	addq.w	#1,(Title_unlock_entries).w
	tst.b	1(a0,d0.w)			; was that the last button?
	bne.s	.return
	move.w	#$101,(Level_select_flag).w	; and Slow_motion_flag, as the sound test code does
	jsr	(Settings_Save).l
	move.b	#SndID_Ring,d0			; the ring sound confirms a cheat
	jsr	(PlaySound).l
.reset:
	clr.w	(Title_unlock_entries).w
.return:
	rts

TitleUnlockCheat_Buttons:
	dc.b	button_up_mask, button_down_mask, button_down_mask, button_down_mask
	dc.b	button_left_mask, button_right_mask, 0
	even

; ---------------------------------------------------------------------------
; CHEATS page of the Level Select (Start on the CHEATS item).
; Up/Down select, Left/Right/A/B/C change, Start goes back to the level list.
; Every change is saved in SRAM at once.
; ---------------------------------------------------------------------------
cheats_row_emeralds = 0
cheats_row_debug = 1
cheats_row_rings = 2
cheats_row_drain = 3
cheats_row_god = 4
cheats_rows = 5

cheats_header_line = 4
cheats_first_line = 8			; rows are two lines apart
cheats_label_col = 6
cheats_value_col = 30
cheats_label_len = 21
cheats_value_len = 3

LevelSelect_Cheats:
	move	#$2700,sr
	bsr.w	CheatsPage_Clear
	bsr.w	CheatsPage_Draw
	move	#$2300,sr
	clr.b	(Ctrl_1_Press).w		; consume the Start that opened the page

.loop:
	move.b	#VintID_Menu,(Vint_routine).w
	jsr	(WaitForVint).l
	move	#$2700,sr
	bsr.w	CheatsPage_Controls
	move.w	d0,-(sp)
	bsr.w	CheatsPage_Draw
	move	#$2300,sr
	lea	(Anim_SonicMilesBG).l,a2
	jsr	(Dynamic_Normal).l
	tst.w	(sp)+				; leave the page?
	beq.s	.loop
	jsr	(Settings_Save).l
	if FeatureTitleMenu
	tst.b	(Cheats_from_title).w		; opened from the title menu?
	beq.s	.levelList
	clr.b	(Cheats_from_title).w
	st.b	(Title_skip_intro).w		; without the intro text
	move.b	#GameModeID_TitleScreen,(Game_Mode).w	; back to the title
	rts
.levelList:
	endif
	jmp	(LevelSelect_RedrawPage).l	; back to the level list, CHEATS still selected

; Fills the visible part of plane A with blank tiles.
CheatsPage_Clear:
	lea	(VDP_data_port).l,a6
	move.l	#vdpComm(VRAM_Plane_A_Name_Table,VRAM,WRITE),4(a6)
	moveq	#0,d0
	move.w	#64*28/2-1,d1
-	move.l	d0,(a6)
	dbf	d1,-
	rts

; ---------------------------------------------------------------------------
; Returns d0 = 1 to leave the page, otherwise 0
; ---------------------------------------------------------------------------
CheatsPage_Controls:
	move.b	(Ctrl_1_Press).w,d1
	andi.b	#button_up_mask|button_down_mask,d1
	bne.s	.updown
	subq.w	#1,(LevSel_HoldTimer).w		; held Up/Down repeats like the level list
	bpl.s	.change
.updown:
	move.w	#$B,(LevSel_HoldTimer).w
	move.b	(Ctrl_1_Held).w,d1
	andi.b	#button_up_mask|button_down_mask,d1
	beq.s	.change
	moveq	#0,d0
	move.b	(Cheats_menu_row).w,d0
	btst	#button_up,d1
	beq.s	.down
	subq.w	#1,d0
	bpl.s	.down
	moveq	#cheats_rows-1,d0
.down:
	btst	#button_down,d1
	beq.s	.setrow
	addq.w	#1,d0
	cmpi.w	#cheats_rows,d0
	blo.s	.setrow
	moveq	#0,d0
.setrow:
	move.b	d0,(Cheats_menu_row).w
	bra.w	.stay

.change:
	move.b	(Ctrl_1_Press).w,d1
	btst	#button_start,d1
	bne.w	.leave
	andi.b	#button_left_mask|button_right_mask|button_A_mask|button_B_mask|button_C_mask,d1
	beq.w	.stay
	moveq	#0,d0
	move.b	(Cheats_menu_row).w,d0
	cmpi.b	#cheats_rows,d0
	blo.s	+
	moveq	#0,d0
	move.b	d0,(Cheats_menu_row).w
+
	cmpi.b	#cheats_row_rings,d0
	beq.s	.rings
	add.w	d0,d0
	lea	CheatsPage_Vars(pc),a1
	movea.w	(a1,d0.w),a1
	eori.b	#1,(a1)				; ON/OFF rows
	cmpi.b	#cheats_row_drain*2,d0
	bne.s	.save
	tst.b	(Cheat_ring_drain).w
	beq.s	.save
	tst.b	(Cheat_super_rings).w
	bne.s	.save
	move.b	#10,(Cheat_super_rings).w	; a drain needs a ring cost: 0 becomes 10
	bra.s	.save

.rings:
	lea	CheatsPage_RingSteps(pc),a1
	move.b	(Cheat_super_rings).w,d0
	moveq	#CheatsPage_RingSteps_End-CheatsPage_RingSteps-1,d2
-	cmp.b	(a1,d2.w),d0
	beq.s	+
	dbf	d2,-
	moveq	#CheatsPage_RingSteps_End-CheatsPage_RingSteps-1,d2
+
	btst	#button_left,d1
	beq.s	.next
	subq.w	#1,d2
	bpl.s	.setstep
	moveq	#CheatsPage_RingSteps_End-CheatsPage_RingSteps-1,d2
	bra.s	.setstep
.next:
	addq.w	#1,d2
	cmpi.w	#CheatsPage_RingSteps_End-CheatsPage_RingSteps,d2
	blo.s	.setstep
	moveq	#0,d2
.setstep:
	move.b	(a1,d2.w),(Cheat_super_rings).w

.save:
	jsr	(Settings_Save).l		; also turns the drain off at 0 rings
.stay:
	moveq	#0,d0
	rts

.leave:
	moveq	#1,d0
	rts

; RAM byte of each row (SUPER RINGS is handled separately)
CheatsPage_Vars:
	dc.w	Cheat_all_emeralds&$FFFF
	dc.w	Debug_options_flag&$FFFF
	dc.w	Cheat_super_rings&$FFFF
	dc.w	Cheat_ring_drain&$FFFF
	dc.w	Cheat_god_mode&$FFFF
CheatsPage_Vars_End:

CheatsPage_RingSteps:
	dc.b	0, 10, 50
CheatsPage_RingSteps_End:
	even

; ---------------------------------------------------------------------------
; Draw the header, every row (the selected one in yellow) and the hint
; ---------------------------------------------------------------------------
CheatsPage_Draw:
	lea	(VDP_data_port).l,a6
	move.l	#vdpComm(VRAM_Plane_A_Name_Table+planeLoc(64,(40-6)/2,cheats_header_line),VRAM,WRITE),4(a6)
	lea	CheatsPage_Header(pc),a1
	move.w	#palette_line_3,d3
	moveq	#6-1,d2
	bsr.w	CheatsPage_DrawText

	lea	CheatsPage_Labels(pc),a1
	move.l	#vdpComm(VRAM_Plane_A_Name_Table+planeLoc(64,cheats_label_col,cheats_first_line),VRAM,WRITE),d4
	moveq	#0,d1
.row:
	move.l	d4,4(a6)
	moveq	#palette_line_0,d3
	cmp.b	(Cheats_menu_row).w,d1
	bne.s	+
	move.w	#palette_line_3,d3
+
	moveq	#cheats_label_len-1,d2
	bsr.w	CheatsPage_DrawText
	move.l	a1,-(sp)
	move.l	d4,d0
	addi.l	#(cheats_value_col-cheats_label_col)*2<<16,d0
	move.l	d0,4(a6)
	bsr.s	CheatsPage_GetValue
	moveq	#cheats_value_len-1,d2
	bsr.w	CheatsPage_DrawText
	movea.l	(sp)+,a1
	addi.l	#(64*2*2)<<16,d4		; two lines down
	addq.w	#1,d1
	cmpi.w	#cheats_rows,d1
	blo.s	.row

	move.l	#vdpComm(VRAM_Plane_A_Name_Table+planeLoc(64,cheats_label_col,cheats_first_line+cheats_rows*2+2),VRAM,WRITE),4(a6)
	lea	CheatsPage_Hint(pc),a1
	moveq	#palette_line_0,d3
	moveq	#CheatsPage_Hint_End-CheatsPage_Hint-1,d2
	bra.w	CheatsPage_DrawText

; d1.w = row; returns a1 = its 3-character value
CheatsPage_GetValue:
	cmpi.w	#cheats_row_rings,d1
	beq.s	.rings
	move.w	d1,d0
	add.w	d0,d0
	lea	CheatsPage_Vars(pc),a1
	movea.w	(a1,d0.w),a1
	moveq	#1,d0
	and.b	(a1),d0				; 0 = "OFF", 1 = " ON"
	bra.s	.text
.rings:
	moveq	#2,d0				; "  0"
	move.b	(Cheat_super_rings).w,d2
	beq.s	.text
	moveq	#3,d0				; " 10"
	cmpi.b	#10,d2
	beq.s	.text
	moveq	#4,d0				; " 50"
.text:
	move.w	d0,d2
	add.w	d0,d0
	add.w	d2,d0
	lea	CheatsPage_Values(pc,d0.w),a1
	rts

; a1 = text, d2 = length-1, d3 = palette line, a6 = VDP data port (address set)
CheatsPage_DrawText:
	moveq	#0,d0
	move.b	(a1)+,d0
	add.w	d3,d0
	move.w	d0,(a6)
	dbf	d2,CheatsPage_DrawText
	rts

	; the menu font, as in the Level Select and Options text
	charset '@',"\27\30\31\32\33\34\35\36\37\38\39\40\41\42\43\44\45\46\47\48\49\50\51\52\53\54\55"
	charset '0',"\16\17\18\19\20\21\22\23\24\25"
	charset '*',$1A
	charset ':',$1C
	charset '.',$1D
	charset ' ',0

CheatsPage_Values:
	dc.b	"OFF"	; 0
	dc.b	" ON"	; 1
	dc.b	"  0"	; 2
	dc.b	" 10"	; 3
	dc.b	" 50"	; 4
CheatsPage_Header:
	dc.b	"CHEATS"
CheatsPage_Labels:
	dc.b	"ALL EMERALDS         "
	dc.b	"DEBUG                "
	dc.b	"SUPER RINGS          "
	dc.b	"RING DRAIN           "
	dc.b	"GOD MODE             "
CheatsPage_Labels_End:
CheatsPage_Hint:
	dc.b	"START: BACK"
CheatsPage_Hint_End:
LevelSelect_CheatsItemText:		; the item drawn into the level list (see LevelSelect_DrawPage)
	dc.b	"CHEATS"
LevelSelect_CheatsItemText_End:

	charset
	even

	if (CheatsPage_Labels_End-CheatsPage_Labels)<>cheats_rows*cheats_label_len
		error "CheatsPage_Labels needs one label of cheats_label_len characters per row"
	endif
	if (CheatsPage_Vars_End-CheatsPage_Vars)<>cheats_rows*2
		error "CheatsPage_Vars needs one entry per row"
	endif

; ---------------------------------------------------------------------------
; Writes the current Level Select page's extra item names (levselpage_texts)
; into its decompressed mappings in Chunk_Table.
; ---------------------------------------------------------------------------
LevelSelect_DrawTexts:
	movem.l	d0-d2/a0-a3,-(sp)
	jsr	(LevelSelect_GetPage).l		; EniDec does not keep a2
	move.l	levselpage_texts(a2),d0
	beq.s	.done
	movea.l	d0,a3
.entry:
	move.w	(a3)+,d0
	bmi.s	.done
	lea	(Chunk_Table).l,a1
	adda.w	d0,a1
	movea.l	(a3)+,a0
	move.w	(a3)+,d2
	moveq	#0,d1
-	move.b	(a0)+,d1
	move.w	d1,(a1)+
	dbf	d2,-
	bra.s	.entry
.done:
	if FeatureSpecialStageSelect
	cmpi.b	#0,(Level_select_page).w	; the stock page shows the Special Stage number
	bne.s	+
	jsr	(LevelSelect_SpecialStageNumber).l
+
	endif
	movem.l	(sp)+,d0-d2/a0-a3
	rts

; ---------------------------------------------------------------------------
; Cheat effects
; ---------------------------------------------------------------------------

; Z=1 when the player counts as having all seven emeralds: really, or through
; ALL EMERALDS outside 2P games and title demos. The real count is never changed.
HasAllEmeralds:
	tst.b	(Cheat_all_emeralds).w
	beq.s	.real
	tst.w	(Two_player_mode).w
	bne.s	.real
	tst.w	(Demo_mode_flag).w
	bne.s	.real
	ori	#4,ccr				; Z=1
	rts
.real:
	cmpi.b	#7,(Emerald_count).w
	rts

; Level start: the DEBUG cheat makes debug mode available (B in a level)
; without holding A, as in s1_improvements; never in title demos.
Cheat_SetDebugMode:
	move.b	(Debug_options_flag).w,(Debug_mode_flag).w
	tst.w	(Demo_mode_flag).w
	beq.s	+
	clr.b	(Debug_mode_flag).w
+
	rts

; Debug mode: B enters object placement, except when it is part of a Super
; combo (A+B or B+C) while Sonic is airborne and rolling, as in s1_improvements.
; Returns Z=0 to enter placement. a0 = Sonic.
Sonic_ChkDebugToggle:
	btst	#button_B,(Ctrl_1_Press).w
	beq.s	.return				; Z=1: no B
	if FeatureSuperToggle
	tst.b	(Control_Locked).w
	bne.s	.enterdebug
	btst	#0,obj_control(a0)
	bne.s	.enterdebug
	move.b	status(a0),d0
	andi.b	#1<<status.player.in_air|1<<status.player.rolling,d0	; Super input is read while airborne and rolling
	cmpi.b	#1<<status.player.in_air|1<<status.player.rolling,d0
	bne.s	.enterdebug
	move.b	(Ctrl_1_Press).w,d0
	andi.b	#button_A_mask|button_C_mask,d0	; A+B or B+C on the same frame
	bne.s	.supercombo
	cmpi.b	#1,transform_combo_timer(a0)	; one frame left expires in Sonic_ToggleSuper
	bls.s	.enterdebug
	move.b	transform_combo_buttons(a0),d0
	andi.b	#button_A_mask|button_C_mask,d0	; A or C pressed earlier in the combo window
	beq.s	.enterdebug
.supercombo:
	moveq	#0,d0				; Z=1
	rts
	endif
.enterdebug:
	moveq	#1,d0				; Z=0
.return:
	rts

; Z=0 while GOD MODE protects the players: the cheat is on, outside 2P VS
; games and title demos. Only the flags change.
Cheat_GodModeActive:
	tst.w	(Two_player_mode).w
	bne.s	.off
	tst.w	(Demo_mode_flag).w
	bne.s	.off
	tst.b	(Cheat_god_mode).w
	rts
.off:
	ori	#4,ccr				; Z=1
	rts

; Called by KillCharacter (a0 = player). Returns Z=1 to let the player die.
; With GOD MODE nothing kills; a player below the bottom boundary (a pit)
; is put back on it and bounced up as an airborne, non-jumping player, so
; Left/Right can steer back to solid ground (as in s1_improvements).
Cheat_GodModeKill:
	bsr.s	Cheat_GodModeActive
	beq.s	.return
	move.l	d1,-(sp)
	move.w	(Camera_Max_Y_pos).w,d0
	move.w	(Camera_Max_Y_pos_target).w,d1	; the boundary may still be moving down
	cmp.w	d0,d1
	blo.s	+
	move.w	d1,d0
+
	addi.w	#screen_height,d0
	cmp.w	y_pos(a0),d0
	bge.s	.saved				; not in a pit: just survive
	move.w	d0,y_pos(a0)
	move.w	#-$A00,y_vel(a0)		; bounce roughly one screen high
	btst	#status.player.underwater,status(a0)
	beq.s	+
	move.w	#-$500,y_vel(a0)		; less is needed under water
+
	bset	#status.player.in_air,status(a0)
	clr.b	jumping(a0)			; letting go of jump must not cut the bounce short
	move.b	#2,routine(a0)			; back to normal control if he fell while hurt
.saved:
	move.l	(sp)+,d1
	moveq	#1,d0				; Z=0
.return:
	rts
