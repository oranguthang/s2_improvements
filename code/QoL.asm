; ---------------------------------------------------------------------------
; Small quality-of-life features, each behind its Feature* switch.
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------
; FeatureExtraLives: a life for every 100 rings. Extra_life_flags(_2P) then
; counts the hundreds already rewarded; losing the rings clears it, so the
; next 100 rings give another life, as in s1_improvements.
; Returns Z=0 when a life is due (and counts it). No registers change.
; ---------------------------------------------------------------------------
ExtraLives_Check1P:
	movem.l	d0/a2/a4,-(sp)
	lea	(Ring_count).w,a2
	lea	(Extra_life_flags).w,a4
	bra.s	ExtraLives_Count

ExtraLives_Check2P:
	movem.l	d0/a2/a4,-(sp)
	lea	(Ring_count_2P).w,a2
	lea	(Extra_life_flags_2P).w,a4
	bra.s	ExtraLives_Count

; a2 = ring count, a4 = lives rewarded for rings
ExtraLives_Check:
	movem.l	d0/a2/a4,-(sp)
ExtraLives_Count:
	moveq	#0,d0
	move.w	(a2),d0
	divu.w	#100,d0
	cmp.b	(a4),d0				; more hundreds than lives given?
	bls.s	.none
	addq.b	#1,(a4)
	andi	#~4,ccr				; Z=0: give a life
	movem.l	(sp)+,d0/a2/a4			; (movem does not change the flags)
	rts
.none:
	ori	#4,ccr				; Z=1
	movem.l	(sp)+,d0/a2/a4
	rts
