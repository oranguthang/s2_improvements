; Casino Night portrait overlay. Keep the original rolling tiles on the
; foreground and draw the protected colours from the stock CNZ palette line 1.
CNZPortraitTile = $0500
CNZPortraitTile2P = $05B0

CNZPortrait_Spawn:
	tst.b	subtype(a0)		; ordinary point cages have no slot pictures
	beq.s	.return
	lea	.positions(pc),a2
	move.w	x_pos(a0),d1
.find:
	move.w	(a2)+,d0
	bmi.s	.return
	cmp.w	d1,d0
	bne.s	.next
	move.w	y_pos(a0),d0
	cmp.w	(a2),d0
	beq.s	.found
.next:
	addq.w	#4,a2
	bra.s	.find
.found:
	move.w	2(a2),d2
	jsr	(AllocateObject).l
	bne.s	.return
	move.b	#ObjID_PointPokey,id(a1)
	move.b	#4,routine(a1)
	move.w	a0,parent(a1)
	move.w	d1,x_pos(a1)
	move.w	d2,y_pos(a1)
	move.l	#CNZPortrait_Map,mappings(a1)
	move.b	#1<<render_flags.level_fg,render_flags(a1)
	move.b	#$30,width_pixels(a1)
	move.b	#7,priority(a1)		; behind the player and cage sprites
	move.w	#make_art_tile(CNZPortraitTile,1,0),art_tile(a1)
	tst.w	(Two_player_mode).w
	beq.s	.return
	move.w	#make_art_tile(CNZPortraitTile2P/2,1,0),art_tile(a1)
.return:
	rts

; Cage X, cage Y, centre Y of its three 32x32 symbols in the level plane.
.positions:
	dc.w	$04C0,$0460,$04A0, $06C0,$01E0,$0220, $1BC0,$0258,$02A0
	dc.w	$1DC0,$0158,$01A0, $22C0,$03CE,$03A0
	dc.w	$0A40,$0360,$0320, $0E40,$05E8,$0640, $15C0,$035C,$03A0
	dc.w	$1DC0,$0368,$03A0, $2440,$02E8,$0320
	dc.w	-1

CNZPortrait_Draw:
	movea.w	parent(a0),a1
	cmpi.b	#ObjID_PointPokey,id(a1)
	bne.s	.delete
	cmpi.b	#2,routine(a1)
	bne.s	.delete
	move.w	x_pos(a0),d0
	cmp.w	x_pos(a1),d0
	bne.s	.delete
	; Wait until the original initialization has uploaded all three strips.
	cmpi.b	#8,(SlotMachine_Routine).w
	blo.s	.hide
	jmp	(MarkObjGone).l
.delete:
	jmp	(DeleteObject).l
.hide:
	rts

CNZPortrait_Map: mappingsTable
	mappingsTableEntry.w CNZPortrait_Frame
CNZPortrait_Frame: spriteHeader
	spritePiece	-48,-16,4,4,$00,0,0,0,0
	spritePiece	-16,-16,4,4,$10,0,0,0,0
	spritePiece	 16,-16,4,4,$20,0,0,0,0
CNZPortrait_Frame_End

CNZPortrait_Sonic: binclude "art/uncompressed/CNZ Sonic portrait layer.bin"
CNZPortrait_Jackpot: binclude "art/uncompressed/CNZ Jackpot layer.bin"
	if FeatureKnuckles
CNZPortrait_Knuckles: binclude "art/uncompressed/CNZ Knuckles portrait layer.bin"
	endif
	even
