; ---------------------------------------------------------------------------
; Faster Kosinski and Enigma decoders, as in s1_improvements. KosDec and EniDec
; in s2.asm jump here; the formats, the output and the register contracts are
; those of the original routines.
; ---------------------------------------------------------------------------

; Faster version written by vladikcomper, with improvements by MarkeyJester
; and Flamewing (https://github.com/flamewing/mdcomp), as in s1_improvements:
; a bit-reversal table, unrolled copies and an inlined bitstream. Same output
; and registers as the original (a0 = after the end marker, a1 = after the
; data, d0-d6 trashed, d7 and a2-a6 preserved).
KosDec_Fast:
	movem.l	d7/a4-a5,-(sp)				; callers keep values in d7/a4 across KosDec
	moveq	#7,d7
	moveq	#0,d0
	moveq	#0,d1
	lea	KosDec_ByteMap(pc),a4			; load bit reversal table
	move.b	(a0)+,d0				; get description field low byte
	move.b	(a0)+,d1				; get description field high byte
	move.b	(a4,d0.w),d0				; reverse bit order...
	move.b	(a4,d1.w),d1				; ...for both bytes
	moveq	#7,d2					; 8 bits in the first byte
	moveq	#0,d3
	bra.s	.FetchNewCode
; ===========================================================================

.FetchCodeLoop:
	; code 1 (uncompressed byte)
	dbf	d2,.bits0
	moveq	#7,d2
	move.b	d1,d0					; use the second description byte
	not.w	d3					; have all 16 bits been used?
	bne.s	.bits0					; if not, branch
	move.b	(a0)+,d0				; get new description field
	move.b	(a0)+,d1
	move.b	(a4,d0.w),d0
	move.b	(a4,d1.w),d1
.bits0:
	move.b	(a0)+,(a1)+				; copy byte as-is

.FetchNewCode:
	add.b	d0,d0					; get next bit
	bcs.s	.FetchCodeLoop				; if code = 1, branch

	; codes 00 and 01
	moveq	#-1,d5
	lea	(a1),a5
	dbf	d2,.bits1
	moveq	#7,d2
	move.b	d1,d0
	not.w	d3
	bne.s	.bits1
	move.b	(a0)+,d0
	move.b	(a0)+,d1
	move.b	(a4,d0.w),d0
	move.b	(a4,d1.w),d1
.bits1:
	add.b	d0,d0
	bcs.w	.Code_01				; if code = 01, branch

	; code 00 (dictionary reference, 2-5 bytes, 8-bit displacement)
	dbf	d2,.bits2
	moveq	#7,d2
	move.b	d1,d0
	not.w	d3
	bne.s	.bits2
	move.b	(a0)+,d0
	move.b	(a0)+,d1
	move.b	(a4,d0.w),d0
	move.b	(a4,d1.w),d1
.bits2:
	add.b	d0,d0					; get high count bit
	bcs.s	.Copy45
	dbf	d2,.bits3
	moveq	#7,d2
	move.b	d1,d0
	not.w	d3
	bne.s	.bits3
	move.b	(a0)+,d0
	move.b	(a0)+,d1
	move.b	(a4,d0.w),d0
	move.b	(a4,d1.w),d1
.bits3:
	add.b	d0,d0					; get low count bit
	bcs.s	.Copy3
	dbf	d2,.bits4
	moveq	#7,d2
	move.b	d1,d0
	not.w	d3
	bne.s	.bits4
	move.b	(a0)+,d0
	move.b	(a0)+,d1
	move.b	(a4,d0.w),d0
	move.b	(a4,d1.w),d1
.bits4:
	move.b	(a0)+,d5				; d5 = displacement
	adda.w	d5,a5
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	bra.w	.FetchNewCode
; ===========================================================================

.Copy3:
	dbf	d2,.bits5
	moveq	#7,d2
	move.b	d1,d0
	not.w	d3
	bne.s	.bits5
	move.b	(a0)+,d0
	move.b	(a0)+,d1
	move.b	(a4,d0.w),d0
	move.b	(a4,d1.w),d1
.bits5:
	move.b	(a0)+,d5				; d5 = displacement
	adda.w	d5,a5
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	bra.w	.FetchNewCode
; ===========================================================================

.Copy45:
	dbf	d2,.bits6
	moveq	#7,d2
	move.b	d1,d0
	not.w	d3
	bne.s	.bits6
	move.b	(a0)+,d0
	move.b	(a0)+,d1
	move.b	(a4,d0.w),d0
	move.b	(a4,d1.w),d1
.bits6:
	add.b	d0,d0					; get low count bit
	bcs.s	.Copy5
	dbf	d2,.bits7
	moveq	#7,d2
	move.b	d1,d0
	not.w	d3
	bne.s	.bits7
	move.b	(a0)+,d0
	move.b	(a0)+,d1
	move.b	(a4,d0.w),d0
	move.b	(a4,d1.w),d1
.bits7:
	move.b	(a0)+,d5				; d5 = displacement
	adda.w	d5,a5
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	bra.w	.FetchNewCode
; ===========================================================================

.Copy5:
	dbf	d2,.bits8
	moveq	#7,d2
	move.b	d1,d0
	not.w	d3
	bne.s	.bits8
	move.b	(a0)+,d0
	move.b	(a0)+,d1
	move.b	(a4,d0.w),d0
	move.b	(a4,d1.w),d1
.bits8:
	move.b	(a0)+,d5				; d5 = displacement
	adda.w	d5,a5
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	bra.w	.FetchNewCode
; ===========================================================================

.Code_01:
	; code 01 (dictionary reference, 13-bit displacement, or special)
	moveq	#0,d4
	dbf	d2,.bits9
	moveq	#7,d2
	move.b	d1,d0
	not.w	d3
	bne.s	.bits9
	move.b	(a0)+,d0
	move.b	(a0)+,d1
	move.b	(a4,d0.w),d0
	move.b	(a4,d1.w),d1
.bits9:
	move.b	(a0)+,d6				; d6 = %LLLLLLLL
	move.b	(a0)+,d4				; d4 = %HHHHHCCC
	move.b	d4,d5					; d5 = %11111111 HHHHHCCC
	lsl.w	#5,d5					; d5 = %111HHHHH CCC00000
	move.b	d6,d5					; d5 = %111HHHHH LLLLLLLL
	and.w	d7,d4					; d4 = %00000CCC
	bne.s	.StreamCopy				; if CCC <> 0, branch

	; extended count
	move.b	(a0)+,d4				; read count
	beq.s	.Quit					; 0 indicates end of compressed data
	subq.b	#1,d4
	beq.w	.FetchNewCode				; 1 indicates no copy (padding)

	adda.w	d5,a5
	move.b	(a5)+,(a1)+				; copy 1 extra byte to compensate for the +1 in the count
	move.w	d4,d6
	not.w	d6
	and.w	d7,d6
	add.w	d6,d6
	lsr.w	#3,d4
	jmp	.largecopy(pc,d6.w)			; copy (count mod 8) bytes first
; ===========================================================================

.largecopy:
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	dbf	d4,.largecopy
	bra.w	.FetchNewCode
; ===========================================================================

.StreamCopy:
	adda.w	d5,a5
	move.b	(a5)+,(a1)+				; copy 1 extra byte to compensate for the +1 in the count
	eor.w	d7,d4
	add.w	d4,d4
	jmp	.mediumcopy(pc,d4.w)			; copy CCC+1 bytes
; ===========================================================================

.mediumcopy:
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	bra.w	.FetchNewCode
; ===========================================================================

.Quit:
	movem.l	(sp)+,d7/a4-a5
	rts
; End of function KosDec_Fast

; ===========================================================================
; Bit reversal table for Kosinski description fields
KosDec_ByteMap:
	dc.b	$00,$80,$40,$C0,$20,$A0,$60,$E0,$10,$90,$50,$D0,$30,$B0,$70,$F0
	dc.b	$08,$88,$48,$C8,$28,$A8,$68,$E8,$18,$98,$58,$D8,$38,$B8,$78,$F8
	dc.b	$04,$84,$44,$C4,$24,$A4,$64,$E4,$14,$94,$54,$D4,$34,$B4,$74,$F4
	dc.b	$0C,$8C,$4C,$CC,$2C,$AC,$6C,$EC,$1C,$9C,$5C,$DC,$3C,$BC,$7C,$FC
	dc.b	$02,$82,$42,$C2,$22,$A2,$62,$E2,$12,$92,$52,$D2,$32,$B2,$72,$F2
	dc.b	$0A,$8A,$4A,$CA,$2A,$AA,$6A,$EA,$1A,$9A,$5A,$DA,$3A,$BA,$7A,$FA
	dc.b	$06,$86,$46,$C6,$26,$A6,$66,$E6,$16,$96,$56,$D6,$36,$B6,$76,$F6
	dc.b	$0E,$8E,$4E,$CE,$2E,$AE,$6E,$EE,$1E,$9E,$5E,$DE,$3E,$BE,$7E,$FE
	dc.b	$01,$81,$41,$C1,$21,$A1,$61,$E1,$11,$91,$51,$D1,$31,$B1,$71,$F1
	dc.b	$09,$89,$49,$C9,$29,$A9,$69,$E9,$19,$99,$59,$D9,$39,$B9,$79,$F9
	dc.b	$05,$85,$45,$C5,$25,$A5,$65,$E5,$15,$95,$55,$D5,$35,$B5,$75,$F5
	dc.b	$0D,$8D,$4D,$CD,$2D,$AD,$6D,$ED,$1D,$9D,$5D,$DD,$3D,$BD,$7D,$FD
	dc.b	$03,$83,$43,$C3,$23,$A3,$63,$E3,$13,$93,$53,$D3,$33,$B3,$73,$F3
	dc.b	$0B,$8B,$4B,$CB,$2B,$AB,$6B,$EB,$1B,$9B,$5B,$DB,$3B,$BB,$7B,$FB
	dc.b	$07,$87,$47,$C7,$27,$A7,$67,$E7,$17,$97,$57,$D7,$37,$B7,$77,$F7
	dc.b	$0F,$8F,$4F,$CF,$2F,$AF,$6F,$EF,$1F,$9F,$5F,$DF,$3F,$BF,$7F,$FF
	even

; Faster version, as in s1_improvements, with ideas from Malachi's improved
; Enigma decompressor: the byte fetch is inlined in the main loop,
; format entries jump straight into $10 byte handler slots, and handlers
; return through a6. Output and registers are the same as the original
; (a0 = even address after the data; all other registers are preserved).
EniDec_Fast:
	movem.l	d0-d7/a1-a6,-(sp)
	lea	Eni_Loop(pc),a6				; handlers return here
	movea.w	d0,a3					; store starting art tile
	move.b	(a0)+,d0
	ext.w	d0
	movea.w	d0,a5					; store number of bits in inline copy value
	move.b	(a0)+,d0
	lsl.b	#3,d0
	movea.w	d0,a2					; store PCCVH flags bitfield
	move.w	(a0)+,d4
	add.w	a3,d4					; store incremental copy word
	movea.w	(a0)+,a4
	adda.w	a3,a4					; store literal copy word
	move.w	(a0)+,d5				; get first word in format list
	moveq	#16,d6					; initial shift value
; loc_173E:
Eni_Loop:
	subq.w	#7,d6					; assume a format list entry is 7 bits
	move.w	d5,d1
	lsr.w	d6,d1
	move.w	d1,d2					; copy format list entry
	andi.w	#$70,d1					; keep the 3 high bits (handler slot offset)
	cmpi.w	#$40,d1					; is the high bit of the entry set?
	bhs.s	.sevenbitentry
	addq.w	#1,d6					; if it isn't, the entry is actually 6 bits
	lsr.w	#1,d2
; loc_1758:
.sevenbitentry:
	cmpi.w	#9,d6					; does a new byte need to be read?
	bhs.s	.gotbits				; if not, branch
	addq.w	#8,d6
	asl.w	#8,d5
	move.b	(a0)+,d5
.gotbits:
	andi.w	#$F,d2					; get repeat count
	jmp	EniDec_00(pc,d1.w)
; End of function EniDec

; ===========================================================================
; Handlers are exactly $10 bytes apart, indexed by the 3 high bits of the
; format list entry. 6-bit entries (00 and 01) occupy two slots each.
; ---------------------------------------------------------------------------
; loc_1768:
EniDec_00:
.loop:		move.w	d4,(a1)+				; copy incremental copy word
	addq.w	#1,d4					; increment it
	dbf	d2,.loop				; repeat
	jmp	(a6)
	nop						; padding
	nop
	nop
	if (*-EniDec_00)<>$10
	fatal "EniDec_00 must be exactly $10 bytes, but it is $\{*-EniDec_00}"
	endif
; ===========================================================================

EniDec_00_Alt:
.loop:		move.w	d4,(a1)+				; copy incremental copy word
	addq.w	#1,d4					; increment it
	dbf	d2,.loop				; repeat
	jmp	(a6)
	nop						; padding
	nop
	nop
	if (*-EniDec_00_Alt)<>$10
	fatal "EniDec_00_Alt must be exactly $10 bytes, but it is $\{*-EniDec_00_Alt}"
	endif
; ===========================================================================
; loc_1772:
EniDec_01:
.loop:		move.w	a4,(a1)+				; copy literal copy word
	dbf	d2,.loop				; repeat
	jmp	(a6)
	nop						; padding
	nop
	nop
	nop
	if (*-EniDec_01)<>$10
	fatal "EniDec_01 must be exactly $10 bytes, but it is $\{*-EniDec_01}"
	endif
; ===========================================================================

EniDec_01_Alt:
.loop:		move.w	a4,(a1)+				; copy literal copy word
	dbf	d2,.loop				; repeat
	jmp	(a6)
	nop						; padding
	nop
	nop
	nop
	if (*-EniDec_01_Alt)<>$10
	fatal "EniDec_01_Alt must be exactly $10 bytes, but it is $\{*-EniDec_01_Alt}"
	endif
; ===========================================================================
; loc_177A:
EniDec_100:
	bsr.w	EniDec_FetchInlineValue
; loc_177E:
.loop:		move.w	d1,(a1)+				; copy inline value
	dbf	d2,.loop				; repeat
	jmp	(a6)
	nop						; padding
	nop
	if (*-EniDec_100)<>$10
	fatal "EniDec_100 must be exactly $10 bytes, but it is $\{*-EniDec_100}"
	endif
; ===========================================================================
; loc_1786:
EniDec_101:
	bsr.w	EniDec_FetchInlineValue
; loc_178A:
.loop:		move.w	d1,(a1)+				; copy inline value
	addq.w	#1,d1					; increment
	dbf	d2,.loop				; repeat
	jmp	(a6)
	nop						; padding
	if (*-EniDec_101)<>$10
	fatal "EniDec_101 must be exactly $10 bytes, but it is $\{*-EniDec_101}"
	endif
; ===========================================================================
; loc_1794:
EniDec_110:
	bsr.w	EniDec_FetchInlineValue
; loc_1798:
.loop:		move.w	d1,(a1)+				; copy inline value
	subq.w	#1,d1					; decrement
	dbf	d2,.loop				; repeat
	jmp	(a6)
	nop						; padding
	if (*-EniDec_110)<>$10
	fatal "EniDec_110 must be exactly $10 bytes, but it is $\{*-EniDec_110}"
	endif
; ===========================================================================
; loc_17A2:
EniDec_111:
	cmpi.w	#$F,d2
	beq.s	EniDec_Done
; loc_17A8:
.loop:		bsr.w	EniDec_FetchInlineValue			; fetch new inline value
	move.w	d1,(a1)+				; copy it
	dbf	d2,.loop				; and repeat
	jmp	(a6)
; ===========================================================================
; loc_17C4:
EniDec_Done:
	subq.w	#1,a0					; go back by one byte
	cmpi.w	#16,d6					; were we going to start on a completely new byte?
	bne.s	.notnewbyte				; if not, branch
	subq.w	#1,a0					; and another one if needed
; loc_17CE:
.notnewbyte:
	move.w	a0,d0
	lsr.w	#1,d0					; are we on an odd byte?
	bcc.s	.evenbyte				; if not, branch
	addq.w	#1,a0					; ensure we're on an even byte
; loc_17D6:
.evenbyte:
	movem.l	(sp)+,d0-d7/a1-a6
	rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Part of the Enigma decompressor
; Fetches an inline copy value and stores it in d1
; ---------------------------------------------------------------------------

; loc_17DC:
EniDec_FetchInlineValue:
	move.w	a3,d3					; copy starting art tile
	move.w	a2,d1					; copy PCCVH bitfield
	add.b	d1,d1					; is the priority bit set?
	bcc.s	.skippriority				; if not, branch
	subq.w	#1,d6
	btst	d6,d5					; is the priority bit set in the inline render flags?
	beq.s	.skippriority				; if not, branch
	ori.w	#$8000,d3				; otherwise set priority bit in art tile
; loc_17EE:
.skippriority:
	add.b	d1,d1					; is the high palette line bit set?
	bcc.s	.skiphighpal				; if not, branch
	subq.w	#1,d6
	btst	d6,d5
	beq.s	.skiphighpal
	addi.w	#$4000,d3				; set second palette line bit
; loc_17FC:
.skiphighpal:
	add.b	d1,d1					; is the low palette line bit set?
	bcc.s	.skiplowpal				; if not, branch
	subq.w	#1,d6
	btst	d6,d5
	beq.s	.skiplowpal
	addi.w	#$2000,d3				; set first palette line bit
; loc_180A:
.skiplowpal:
	add.b	d1,d1					; is the vertical flip flag set?
	bcc.s	.skipyflip				; if not, branch
	subq.w	#1,d6
	btst	d6,d5
	beq.s	.skipyflip
	ori.w	#$1000,d3				; set Y-flip bit
; loc_1818:
.skipyflip:
	add.b	d1,d1					; is the horizontal flip flag set?
	bcc.s	.skipxflip				; if not, branch
	subq.w	#1,d6
	btst	d6,d5
	beq.s	.skipxflip
	ori.w	#$800,d3				; set X-flip bit
; loc_1826:
.skipxflip:
	move.w	d5,d1
	move.w	d6,d7
	sub.w	a5,d7					; subtract length in bits of inline copy value
	bcc.s	.enoughbits				; branch if a new word doesn't need to be read
	move.w	d7,d6
	addi.w	#16,d6
	neg.w	d7					; calculate bit deficit
	lsl.w	d7,d1					; and make space for that many bits
	move.b	(a0),d5					; get next byte
	rol.b	d7,d5					; and rotate the required bits into the lowest positions
	add.w	d7,d7
	and.w	EniDec_Masks-2(pc,d7.w),d5
	add.w	d5,d1					; combine upper bits with lower bits
; loc_1844:
.maskvalue:
	move.w	a5,d0					; get length in bits of inline copy value
	add.w	d0,d0
	and.w	EniDec_Masks-2(pc,d0.w),d1		; mask value appropriately
	add.w	d3,d1					; add starting art tile
	move.b	(a0)+,-(sp)				; byte goes to the high byte of the stack word
	move.w	(sp)+,d5
	move.b	(a0)+,d5				; get next word
	rts
; ===========================================================================
; loc_1856:
.enoughbits:
	beq.s	.justenough				; if the word has been exactly exhausted, branch
	lsr.w	d7,d1					; get inline copy value
	move.w	a5,d0
	add.w	d0,d0
	and.w	EniDec_Masks-2(pc,d0.w),d1		; and mask it appropriately
	add.w	d3,d1					; add starting art tile
	move.w	d7,d6					; consume the inline copy value
	cmpi.w	#9,d6					; does a new byte need to be read?
	bhs.s	.locret					; if not, branch
	addq.w	#8,d6
	asl.w	#8,d5
	move.b	(a0)+,d5
.locret:
	rts
; ===========================================================================
; loc_1868:
.justenough:
	moveq	#16,d6					; reset shift value
	bra.s	.maskvalue
; ===========================================================================
; word_186C:
EniDec_Masks:
	dc.w	 1,    3,    7,   $F
	dc.w   $1F,  $3F,  $7F,  $FF
	dc.w  $1FF, $3FF, $7FF, $FFF
	dc.w $1FFF,$3FFF,$7FFF,$FFFF
; End of function EniDec_FetchInlineValue
