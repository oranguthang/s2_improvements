; ---------------------------------------------------------------------------
; Debug coordinates in the upper right corner (as in s1_improvements).
; While debug mode is available in a 1P game, the top row shows the camera
; X and Y position and the second row Sonic's (or Tails') X and Y position in
; hex; a third row shows SPR and the number of sprites drawn. SCORE and TIME
; keep their normal meaning.
;
; Sonic 2 has no spare VRAM in levels, so the overlay borrows the sidekick's
; 12-tile shield slot and packs two 4-pixel-wide characters into each tile
; (11 tiles). It is hidden while the sidekick has a shield.
; ---------------------------------------------------------------------------
ArtTile_Debug_Coords = ArtTile_ArtUnc_Shield_P2
hud_debug_font_space = $13		; index of the blank glyph

; Z=1 when the overlay is shown
HudDebug_Visible:
	tst.w	(Debug_mode_flag).w
	beq.s	.hide
	tst.w	(Two_player_mode).w
	bne.s	.hide
	tst.b	(Sidekick+id).w
	beq.s	.show
	btst	#status_secondary.shield,(Sidekick+status_secondary).w
	bne.s	.hide				; the shield uses these tiles
.show:
	ori	#4,ccr				; Z=1
	rts
.hide:
	andi	#~4,ccr				; Z=0
	rts

; ---------------------------------------------------------------------------
; Writes the overlay tiles (called by HudUpdate during V-Int)
; ---------------------------------------------------------------------------
HudDebug_Overlay:
	bsr.w	HudDebug_Visible
	bne.s	.return
	movem.l	d0-d7/a1/a6,-(sp)
	lea	(VDP_data_port).l,a6
	move.l	#vdpComm(tiles_to_bytes(ArtTile_Debug_Coords),VRAM,WRITE),VDP_control_port-VDP_data_port(a6)
	move.w	(Camera_X_pos).w,d4
	swap	d4
	move.w	(Camera_Y_pos).w,d4		; top row: camera X, camera Y
	move.w	(MainCharacter+x_pos).w,d5
	swap	d5
	move.w	(MainCharacter+y_pos).w,d5	; second row: player X, player Y
	moveq	#4-1,d7				; a 4x2-tile sprite piece goes column by column
.column:
	rol.l	#8,d4
	move.b	d4,d0
	bsr.s	HudDebug_DrawHexPair
	rol.l	#8,d5
	move.b	d5,d0
	bsr.s	HudDebug_DrawHexPair
	dbf	d7,.column
	moveq	#$10,d0				; "SP"
	moveq	#$11,d1
	bsr.s	HudDebug_DrawGlyphs
	moveq	#$12,d0				; "R "
	moveq	#hud_debug_font_space,d1
	bsr.s	HudDebug_DrawGlyphs
	moveq	#0,d0
	move.b	(Sprite_count).w,d0
	cmpi.w	#99,d0
	bls.s	+
	moveq	#99,d0
+
	divu.w	#10,d0
	move.l	d0,d1
	swap	d1				; ones
	bsr.s	HudDebug_DrawGlyphs
	movem.l	(sp)+,d0-d7/a1/a6
.return:
	rts

; d0.b = two hex digits for one tile
HudDebug_DrawHexPair:
	moveq	#$F,d1
	and.b	d0,d1
	lsr.b	#4,d0
	andi.w	#$F,d0
; d0.w = left glyph, d1.w = right glyph; writes one tile to (a6)
HudDebug_DrawGlyphs:
	lea	HudDebug_Font(pc),a1
	lsl.w	#4,d0
	lsl.w	#4,d1
	moveq	#8-1,d6
-	move.w	(a1,d0.w),d2
	swap	d2
	move.w	(a1,d1.w),d2
	move.l	d2,(a6)
	addq.w	#2,d0
	addq.w	#2,d1
	dbf	d6,-
	rts

; ---------------------------------------------------------------------------
; Draws the overlay sprites (BuildHUD jumps here after drawing the HUD)
; ---------------------------------------------------------------------------
HudDebug_DrawSprite:
	bsr.w	HudDebug_Visible
	bne.s	.return
	lea	HudDebug_Pieces(pc),a1
	moveq	#(HudDebug_Pieces_End-HudDebug_Pieces)/8-1,d1
	move.w	#spriteScreenPositionX(320-16-32),d3	; 16 pixels from the right, like SCORE on the left
	move.w	#spriteScreenPositionY(8),d2
	suba.l	a3,a3				; the pieces carry absolute tiles
	jmp	(DrawSprite_Loop).l
.return:
	rts

; Sonic 2 mapping pieces: Y and size, tile, 2P tile, X
HudDebug_Pieces:
	dc.w	(0<<8)|((4-1)<<2)|(2-1), high_priority|ArtTile_Debug_Coords, high_priority|(ArtTile_Debug_Coords>>1), 0
	dc.w	($10<<8)|((3-1)<<2)|(1-1), high_priority|(ArtTile_Debug_Coords+8), high_priority|((ArtTile_Debug_Coords+8)>>1), 0
HudDebug_Pieces_End:

; 4x8-pixel characters in colour 6 of palette line 0 (as the S2 debug digits):
; 0-F, S, P, R, blank. One word per pixel row.
HudDebug_Font:
	dc.w	$0000, $0000, $6660, $6060, $6060, $6060, $6660, $0000	; 0
	dc.w	$0000, $0000, $0600, $6600, $0600, $0600, $6660, $0000	; 1
	dc.w	$0000, $0000, $6660, $0060, $6660, $6000, $6660, $0000	; 2
	dc.w	$0000, $0000, $6660, $0060, $0660, $0060, $6660, $0000	; 3
	dc.w	$0000, $0000, $6060, $6060, $6660, $0060, $0060, $0000	; 4
	dc.w	$0000, $0000, $6660, $6000, $6660, $0060, $6660, $0000	; 5
	dc.w	$0000, $0000, $6660, $6000, $6660, $6060, $6660, $0000	; 6
	dc.w	$0000, $0000, $6660, $0060, $0600, $0600, $0600, $0000	; 7
	dc.w	$0000, $0000, $6660, $6060, $6660, $6060, $6660, $0000	; 8
	dc.w	$0000, $0000, $6660, $6060, $6660, $0060, $6660, $0000	; 9
	dc.w	$0000, $0000, $0600, $6060, $6660, $6060, $6060, $0000	; A
	dc.w	$0000, $0000, $6600, $6060, $6600, $6060, $6600, $0000	; B
	dc.w	$0000, $0000, $0660, $6000, $6000, $6000, $0660, $0000	; C
	dc.w	$0000, $0000, $6600, $6060, $6060, $6060, $6600, $0000	; D
	dc.w	$0000, $0000, $6660, $6000, $6600, $6000, $6660, $0000	; E
	dc.w	$0000, $0000, $6660, $6000, $6600, $6000, $6000, $0000	; F
	dc.w	$0000, $0000, $0660, $6000, $0600, $0060, $6600, $0000	; S
	dc.w	$0000, $0000, $6600, $6060, $6600, $6000, $6000, $0000	; P
	dc.w	$0000, $0000, $6600, $6060, $6600, $6060, $6060, $0000	; R
	dc.w	$0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000	; blank
