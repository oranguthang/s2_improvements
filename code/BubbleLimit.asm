; Keep the last five small bubbles across vents and breath effects.
; Medium bubbles, breathable bubbles and countdown digits bypass the queue.
Bubble_KeepLatest:
	movem.l	d0-d2/a1-a3,-(sp)
	lea	(Small_bubble_fifo).w,a1
	movea.l	a1,a2
	moveq	#small_bubble_limit-1,d2
.scan:
	move.w	(a1)+,d0
	beq.s	.next
	movea.w	d0,a3
	cmpa.l	a0,a3
	beq.s	.next			; recycled slot, append it as newest
	tst.b	routine(a3)
	beq.s	.next
	cmpi.b	#ObjID_ARZBubbles,id(a3)
	beq.s	.vent
	cmpi.b	#ObjID_SmallBubbles,id(a3)
	bne.s	.next
	cmpi.b	#small_breath_subtype,subtype(a3)
	beq.s	.keep
	bra.s	.next
.vent:
	tst.b	subtype(a3)
	bne.s	.next
.keep:
	move.w	a3,(a2)+
.next:
	dbf	d2,.scan
	cmpa.w	#Small_bubble_fifo_end,a2
	blo.s	.append
	bsr.s	Bubble_EvictOldest
	lea	(Small_bubble_fifo).w,a2
	move.l	2(a2),(a2)+
	move.l	2(a2),(a2)+
.append:
	move.w	a0,(a2)+
.clear:
	cmpa.w	#Small_bubble_fifo_end,a2
	bhs.s	.done
	clr.w	(a2)+
	bra.s	.clear
.done:
	movem.l	(sp)+,d0-d2/a1-a3
	rts

; Bubbles draw in priority 1. Remove an already queued sprite before freeing it.
Bubble_EvictOldest:
	move.w	(Small_bubble_fifo).w,d0
	lea	(Object_Display_Lists+object_display_list_size).w,a1
	move.w	(a1),d2
	beq.s	.delete
	lea	2(a1),a2
.find:
	cmp.w	(a2)+,d0
	beq.s	.unqueue
	subq.w	#2,d2
	bne.s	.find
	bra.s	.delete
.unqueue:
	subq.w	#2,(a1)
	bra.s	.shiftNext
.shift:
	move.w	(a2),-2(a2)
	addq.w	#2,a2
.shiftNext:
	subq.w	#2,d2
	bne.s	.shift
.delete:
	movea.w	d0,a1
	jmp	(DeleteObject2).l
