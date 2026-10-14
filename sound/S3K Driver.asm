; ===========================================================================
; ---------------------------------------------------------------------------
; Flamedriver (FeatureSoundDriver = SoundDriver_S3K), as in s1_improvements
; ---------------------------------------------------------------------------
; Flamewing's Sonic 3 & Knuckles Z80 driver plays all music and sound effects.
; The game keeps its Sonic 2 interface: PlayMusic, PlaySound, PlaySound2 and
; PauseGame fill Sound_Queue, and sndDriverInput, which every V-Int routine
; calls with the Z80 stopped, passes the songs, sound effects and commands on.
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to load the sound driver
; ---------------------------------------------------------------------------

SoundDriverLoad:
	move	sr,-(sp)
	movem.l	d0-a6,-(sp)
	move	#$2700,sr
	move.w	#$100,(Z80_Bus_Request).l	; get the Z80 bus...
	move.w	#$100,(Z80_Reset).l		; ...and release the Z80 reset (held on startup)
-	btst	#0,(Z80_Bus_Request).l		; the bus is granted only out of reset
	bne.s	-
	lea	(Snd_Driver).l,a0
	lea	(Z80_RAM).l,a1
	jsr	(KosDec).l			; decompress the driver into Z80 RAM
	lea	(Z80_RAM+z80_stack).l,a1
	move.w	#zTracksStart-z80_stack-1,d0
-	clr.b	(a1)+				; clear the driver's variables
	dbf	d0,-
	btst	#0,(VDP_control_port+1).l	; PAL console?
	beq.s	+
	move.b	#1,(Z80_RAM+zPalFlag).l		; then update the music five times every six frames
+
	move.w	#0,(Z80_Reset).l		; reset the Z80...
	moveq	#signextendB($E6),d0
-	dbf	d0,-
	move.w	#$100,(Z80_Reset).l		; ...and let it run the new driver
	startZ80
	movem.l	(sp)+,d0-a6
	move	(sp)+,sr
	rts
; End of function SoundDriverLoad

; ---------------------------------------------------------------------------
; Subroutine to pass Sound_Queue to the driver (sndDriverInput jumps here;
; every V-Int routine calls it with the Z80 stopped)
; ---------------------------------------------------------------------------

SoundS3K_Input:
	lea	(Sound_Queue&$00FFFFFF).l,a0
	moveq	#0,d2				; no song or command sent this frame
	lea	SoundQueue.Music0(a0),a1
	bsr.s	SoundS3K_Slot
	tst.b	SoundQueue.Music0(a0)		; Music1 waits while Music0 is still queued
	bne.s	+
	lea	SoundQueue.Music1(a0),a1
	bsr.s	SoundS3K_Slot
+
	lea	SoundQueue.SFX0(a0),a1
	bsr.s	SoundS3K_Slot
	lea	SoundQueue.SFX1(a0),a1
	bsr.s	SoundS3K_Slot
	lea	SoundQueue.SFX2(a0),a1
SoundS3K_Slot:
	moveq	#0,d1
	move.b	(a1),d1
	beq.s	.return
	cmpi.b	#MusID__End,d1
	blo.s	.music
	cmpi.b	#SndID__End,d1
	blo.s	.soundEffect
	cmpi.b	#CmdID__First,d1
	blo.s	.handled			; unused IDs do nothing
	subi.b	#CmdID__First,d1
	add.w	d1,d1
	move.w	.commands(pc,d1.w),d1
	jmp	.commands(pc,d1.w)
; ---------------------------------------------------------------------------
.commands:
	dc.w	.stopSFX-.commands		; MusID_StopSFX
	dc.w	.fade-.commands			; MusID_FadeOut
	dc.w	.sega-.commands			; SndID_SegaSound
	dc.w	.speedUp-.commands		; MusID_SpeedUp
	dc.w	.slowDown-.commands		; MusID_SlowDown
	dc.w	.stop-.commands			; MusID_Stop
	dc.w	.pause-.commands		; MusID_Pause
	dc.w	.unpause-.commands		; MusID_Unpause
; ---------------------------------------------------------------------------
.music:
	tst.b	d2				; the driver reads one song or command per frame
	bne.s	.return
.sendMusic:
	moveq	#1,d2
	move.b	d1,(Z80_RAM+zMusicNumber).l
.handled:
	clr.b	(a1)
.return:
	rts
; ---------------------------------------------------------------------------
.soundEffect:
	subi.b	#SndID__First-zsfx__First,d1
	cmp.b	(Z80_RAM+zSFXNumber0).l,d1	; already requested this frame?
	beq.s	.handled
	tst.b	(Z80_RAM+zSFXNumber0).l
	bne.s	.secondSlot
	move.b	d1,(Z80_RAM+zSFXNumber0).l
	bra.s	.handled
.secondSlot:
	cmp.b	(Z80_RAM+zSFXNumber1).l,d1
	beq.s	.handled
	tst.b	(Z80_RAM+zSFXNumber1).l
	bne.s	.return				; both slots busy: try again next frame
	move.b	d1,(Z80_RAM+zSFXNumber1).l
	bra.s	.handled
; ---------------------------------------------------------------------------
.stopSFX:
	moveq	#zcmd_StopSFX,d1
	bra.s	.music
.fade:
	moveq	#zcmd_FadeOut,d1
	bra.s	.music
.stop:
	moveq	#zcmd_Stop,d1
	bra.s	.music
.sega:
	move.b	#zcmd_SegaSound,d1
	bra.s	.music
.speedUp:
	move.b	#8,(Z80_RAM+zTempoSpeedup).l	; Sonic 3 & Knuckles speed shoes tempo
	bra.s	.handled
.slowDown:
	move.b	#0,(Z80_RAM+zTempoSpeedup).l
	bra.s	.handled
.pause:
	move.b	#1,(Z80_RAM+zPauseFlag).l
	bra.s	.handled
.unpause:
	move.b	#$80,(Z80_RAM+zPauseFlag).l
	bra.s	.handled
; End of function SoundS3K_Input

; ---------------------------------------------------------------------------
; Subroutine to stop the SEGA chant early. The driver plays it with its
; interrupts off and checks for this command after every byte.
; ---------------------------------------------------------------------------

StopSegaPCM:
	stopZ80
	move.b	#zcmd_StopSega,(Z80_RAM+zMusicNumber).l
	startZ80
	rts
; End of function StopSegaPCM

; ===========================================================================
; The driver, Kosinski-compressed by the build into Size_of_Snd_driver_guess
Snd_Driver:
	include	"sound/flamedriver/Z80Driver.a80"	; reserves Size_of_Snd_driver_guess itself
Snd_Driver_End:

; DAC samples, sound effects, the SEGA chant and music, each in 32 KiB banks
; the Z80 reads through its ROM window.
	include	"sound/flamedriver/DACBanks.asm"
	include	"sound/S3K SFX Bank.asm"
	include	"sound/S3K Music Bank.asm"
	even
