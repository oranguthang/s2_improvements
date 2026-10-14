; ---------------------------------------------------------------------------
; Subroutine to pick the main direction of a player's movement in the air,
; for Sonic_DoLevelCollision and Tails_DoLevelCollision. It returns what
; CalcAngle(x_vel, y_vel)-$20 snapped to a multiple of $40 used to return,
; without a division (as in s1_improvements' Sonic_Floor):
;
;	d1 = x speed, d2 = y speed
;	d0.b = $00 down, $40 left, $80 up, $C0 right; other registers preserved
;
; CalcAngle's table returns exactly 45 degrees once small*256/big >= $FA,
; which tips near-diagonal movement into the next quadrant counterclockwise.
; That rounding is reproduced exactly by the "diagonal" test below
; (b/s = bigger/smaller absolute speed, unsigned like CalcAngle):
;	floor(256*s/b) >= $FA  <=>  128*s >= 125*b  <=>  3*b - 128*(b-s) >= 0
; ---------------------------------------------------------------------------
CalcAirQuadrant:
	move.l	d3,-(sp)
	moveq	#0,d3
	move.w	d1,d3
	bpl.s	.posX
	neg.w	d3				; d3 = |X|
.posX:
	moveq	#0,d0
	move.w	d2,d0
	bpl.s	.posY
	neg.w	d0				; d0 = |Y|
.posY:
	cmp.w	d3,d0				; same unsigned comparison CalcAngle uses
	bhs.s	.yIsBigger
	; |X| > |Y|
	sub.l	d3,d0				; s-b
	lsl.l	#7,d0				; -128*(b-s)
	add.l	d3,d0
	add.l	d3,d0
	add.l	d3,d0				; + 3*b
	spl	d0				; d0.b = $FF near the diagonal
	move.l	(sp)+,d3
	tst.w	d1
	bmi.s	.xLeft
	tst.w	d2				; moving right
	bmi.s	.right
	tst.b	d0
	bne.s	.down				; near the diagonal CalcAngle rounds to down
.right:
	moveq	#-$40,d0
	rts
.xLeft:
	tst.w	d2				; moving left
	bpl.s	.left
	tst.b	d0
	bne.s	.up				; near the diagonal CalcAngle rounds to up
.left:
	moveq	#$40,d0
	rts
; ---------------------------------------------------------------------------
.yIsBigger:
	; |Y| >= |X|
	sub.l	d0,d3				; s-b
	lsl.l	#7,d3				; -128*(b-s)
	add.l	d0,d3
	add.l	d0,d3
	add.l	d0,d3				; + 3*b
	spl	d0				; d0.b = $FF near the diagonal
	move.l	(sp)+,d3
	tst.w	d2
	bmi.s	.yUp
	tst.w	d1				; moving down
	bpl.s	.down				; (includes X = Y = 0)
	tst.b	d0
	bne.s	.left				; near the diagonal CalcAngle rounds to left
.down:
	moveq	#0,d0
	rts
.yUp:
	tst.w	d1				; moving up
	bmi.s	.up
	tst.b	d0
	bne.s	.right				; near the diagonal CalcAngle rounds to right
.up:
	moveq	#-$80,d0
	rts
; End of function CalcAirQuadrant
