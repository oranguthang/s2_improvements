Sound52_Header:
	smpsHeaderStartSong 3
	smpsHeaderVoice     Tails_Flying_Voices
	smpsHeaderTempoSFX  $01
	smpsHeaderChanSFX   $01

	smpsHeaderSFXChannel cFM4, Sound52_FM4,	$FA, $0B

; FM4 Data
Sound52_FM4:
	smpsSetvoice        $00
	dc.b	nE2, $08, $08
	smpsStop
