; ---------------------------------------------------------------------------
; 2P VS zone menu with five zones (FeatureHTZVS)
;
; Instead of Sonic 2's four boxes, a list like the Level Select's:
; EMERALD HILL, MYSTIC CAVE, CASINO NIGHT, HILL TOP and SPECIAL STAGE on the
; left (Up/Down), the zone's icon in the Level Select's emblem on the right,
; and the X icon once a zone has been played (Start then gives the error
; sound, as before). Current_Zone_2P is the index in that list.
; ---------------------------------------------------------------------------
VSMenu_Zones = 5
vsmenu_col = 5			; the list's left column (SPECIAL STAGE ends at 17)
vsmenu_first_line = 6		; one zone every three lines, down to line 18
vsmenu_emblem_col = 26		; the emblem (10x7 cells) beside the middle of the list
vsmenu_emblem_line = 9
vsmenu_icons = Chunk_Table+planeLoc(40,0,28)	; Level Select icons (4x3 cells each)

; MenuScreen, display off: plane A and the selection
VSMenu_Draw:
	cmpi.b	#VSMenu_Zones,(Current_Zone_2P).w
	blo.s	+
	clr.b	(Current_Zone_2P).w
+
	; the Level Select page, of which only the emblem (lines 20-26, columns
	; 24-33) is kept, moved up to the right of the list
	lea	(Chunk_Table).l,a1
	lea	(MapEng_LevSel).l,a0
	move.w	#make_art_tile(ArtTile_VRAM_Start,0,0),d0
	jsr	(EniDec).l
	lea	(Chunk_Table+planeLoc(40,24,20)).l,a0
	lea	(Chunk_Table+planeLoc(40,vsmenu_emblem_col,vsmenu_emblem_line)).l,a1
	moveq	#7-1,d1
.emblemLine:
	moveq	#10-1,d2
-	move.w	(a0)+,(a1)+
	dbf	d2,-
	lea	(40-10)*2(a0),a0
	lea	(40-10)*2(a1),a1
	dbf	d1,.emblemLine
	lea	(Chunk_Table).l,a1
	moveq	#0,d1			; line
.line:
	moveq	#0,d2			; column
.cell:
	cmpi.w	#vsmenu_emblem_line,d1
	blo.s	.clear
	cmpi.w	#vsmenu_emblem_line+6,d1
	bhi.s	.clear
	cmpi.w	#vsmenu_emblem_col,d2
	blo.s	.clear
	cmpi.w	#vsmenu_emblem_col+9,d2
	bls.s	.keep
.clear:
	clr.w	(a1)
.keep:
	addq.w	#2,a1
	addq.w	#1,d2
	cmpi.w	#40,d2
	blo.s	.cell
	addq.w	#1,d1
	cmpi.w	#28,d1
	blo.s	.line

	lea	(vsmenu_icons).l,a1
	lea	(MapEng_LevSelIcon).l,a0
	move.w	#make_art_tile(ArtTile_ArtNem_LevelSelectPics,0,0),d0
	jsr	(EniDec).l

	lea	(Chunk_Table).l,a1
	move.l	#vdpComm(VRAM_Plane_A_Name_Table,VRAM,WRITE),d0
	moveq	#40-1,d1
	moveq	#28-1,d2
	jsr	(PlaneMapToVRAM_H40).l
	bra.s	VSMenu_Redraw

; Every frame, interrupts off: Up/Down, then the list and the icon
VSMenu_Update:
	move.b	(Ctrl_1_Press).w,d0
	or.b	(Ctrl_2_Press).w,d0
	btst	#button_up,d0
	beq.s	.down
	subq.b	#1,(Current_Zone_2P).w
	bpl.s	VSMenu_Redraw
	move.b	#VSMenu_Zones-1,(Current_Zone_2P).w
	bra.s	VSMenu_Redraw
.down:
	btst	#button_down,d0
	beq.s	VSMenu_Redraw
	addq.b	#1,(Current_Zone_2P).w
	cmpi.b	#VSMenu_Zones,(Current_Zone_2P).w
	blo.s	VSMenu_Redraw
	clr.b	(Current_Zone_2P).w

VSMenu_Redraw:
	; the names, the selected one in palette line 3 (yellow)
	lea	(VDP_data_port).l,a6
	lea	VSMenu_Names(pc),a2
	move.l	#vdpComm(VRAM_Plane_A_Name_Table+planeLoc(64,vsmenu_col,vsmenu_first_line),VRAM,WRITE),d4
	moveq	#0,d5
.zone:
	move.l	d4,4(a6)
	moveq	#palette_line_0,d3
	cmp.b	(Current_Zone_2P).w,d5
	bne.s	+
	move.w	#palette_line_3,d3
+
	movea.l	(a2)+,a1
	moveq	#0,d1
	move.b	(a1)+,d1
-	moveq	#0,d0
	move.b	(a1)+,d0
	add.w	d3,d0
	move.w	d0,(a6)
	dbf	d1,-
	addi.l	#(64*2*3)<<16,d4	; three lines down
	addq.b	#1,d5
	cmpi.b	#VSMenu_Zones,d5
	blo.s	.zone

	; the icon, or the X for a played zone, with the zone's icon colours
	moveq	#0,d6
	move.b	(Current_Zone_2P).w,d6
	move.b	VSMenu_Icons(pc,d6.w),d6
	move.w	d6,d2
	jsr	(Chk2PZoneCompletion).l
	bmi.s	+			; not played yet
	moveq	#$D,d2			; the X
+
	mulu.w	#4*3*2,d2
	lea	(vsmenu_icons).l,a1
	adda.w	d2,a1
	move.l	#vdpComm(VRAM_Plane_A_Name_Table+planeLoc(64,vsmenu_emblem_col+3,vsmenu_emblem_line+2),VRAM,WRITE),d0
	moveq	#4-1,d1
	moveq	#3-1,d2
	jsr	(PlaneMapToVRAM_H40).l
	lea	(Pal_LevelIcons).l,a1
	lsl.w	#5,d6
	adda.w	d6,a1
	lea	(Normal_palette_line3).w,a2
    if fixBugs
	; upload the colours at once, as LevelSelect_DrawIcon does
	move.l	#vdpComm(2*16*2,CRAM,WRITE),VDP_control_port-VDP_data_port(a6)
    endif
	moveq	#bytesToLcnt(palette_line_size),d1
-
    if fixBugs
	move.l	(a1),(a6)
    endif
	move.l	(a1)+,(a2)+
	dbf	d1,-
	rts

; Level Select icon per zone (LevelSelect_IconTable)
VSMenu_Icons:
	dc.b	0, 5, 6, 2, $C	; EHZ, MCZ, CNZ, HTZ, Special Stage
	even

VSMenu_Names:
	dc.l	VSMenu_TextEHZ, VSMenu_TextMCZ, VSMenu_TextCNZ, VSMenu_TextHTZ, VSMenu_TextSS
VSMenu_Names_End:
    if (VSMenu_Names_End-VSMenu_Names)<>VSMenu_Zones*4
	error "VSMenu_Names needs one name per VS zone"
    endif

	charset '@',"\27\30\31\32\33\34\35\36\37\38\39\40\41\42\43\44\45\46\47\48\49\50\51\52\53\54\55"
	charset ' ',0
VSMenu_TextEHZ:	menutxt	"EMERALD HILL"
VSMenu_TextMCZ:	menutxt	"MYSTIC CAVE"
VSMenu_TextCNZ:	menutxt	"CASINO NIGHT"
VSMenu_TextHTZ:	menutxt	"HILL TOP"
VSMenu_TextSS:	menutxt	"SPECIAL STAGE"
	charset
	even
