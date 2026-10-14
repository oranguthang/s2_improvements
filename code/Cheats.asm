; ---------------------------------------------------------------------------
; Cheats: the title unlock code and the CHEATS page of the Level Select.
; The settings themselves are saved by code/Settings.asm.
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------
; Title code Up, Down, Down, Down, Left, Right (as in s1_improvements) unlocks
; the Level Select and its CHEATS page, like the sound test code 19, 65, 9, 17.
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
