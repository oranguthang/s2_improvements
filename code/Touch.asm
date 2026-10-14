; ---------------------------------------------------------------------------
; Object scan of TouchResponse, unrolled: same objects, same order and same
; registers as the original loop, at 22 cycles instead of 42 for each slot
; without collision_flags. TouchResponse jumps here with d2-d5 set up; each
; object with collision_flags is passed to Touch_CheckCollision with a1 = the
; object and d0 = its collision_flags. A miss returns here (Touch_NextObj);
; a hit drops the return address (Touch_Hit), so only one object is handled
; per frame, as before.
; (Exact alternative to the collision queue of "Optimizing Collision System":
; objects here may also be given collision_flags by other objects.)
; ---------------------------------------------------------------------------
Touch_ScanObjects:
.slot := 0
	rept (Dynamic_Object_RAM_End-Dynamic_Object_RAM)/object_size
	move.b	(Dynamic_Object_RAM+.slot*object_size+collision_flags).w,d0
	beq.s	*+2+4+6			; no collision_flags: next slot
	lea	(Dynamic_Object_RAM+.slot*object_size).w,a1
	jsr	(Touch_CheckCollision).l
.slot := .slot+1
	endm
	moveq	#0,d0
	rts
; End of function Touch_ScanObjects
