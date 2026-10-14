; Music banks for Flamedriver: each starts with the music pointer table and the
; universal voice bank (the driver reads them from the song's bank), then the
; Sonic 2 songs, assembled from sound/music by Flamedriver's SMPS2ASM. Move a
; song to the other bank if finishBank reports an overflow.
MusBank1:	startBank
	Music_Master_Table
z80_UniVoiceBank:	include "sound/flamedriver/UniBank.asm"
Mus_2PResult:	include "sound/music/81 - 2 Player Menu.asm"
Mus_EHZ:	include "sound/music/82 - EHZ.asm"
Mus_MCZ_2P:	include "sound/music/83 - MCZ 2P.asm"
Mus_OOZ:	include "sound/music/84 - OOZ.asm"
Mus_MTZ:	include "sound/music/85 - MTZ.asm"
Mus_HTZ:	include "sound/music/86 - HTZ.asm"
Mus_ARZ:	include "sound/music/87 - ARZ.asm"
Mus_CNZ_2P:	include "sound/music/88 - CNZ 2P.asm"
Mus_CNZ:	include "sound/music/89 - CNZ.asm"
Mus_DEZ:	include "sound/music/8A - DEZ.asm"
Mus_MCZ:	include "sound/music/8B - MCZ.asm"
Mus_EHZ_2P:	include "sound/music/8C - EHZ 2P.asm"
Mus_SCZ:	include "sound/music/8D - SCZ.asm"
Mus_CPZ:	include "sound/music/8E - CPZ.asm"
Mus_WFZ:	include "sound/music/8F - WFZ.asm"
Mus_HPZ:	include "sound/music/90 - HPZ.asm"
	finishBank

MusBank2:	startBank
	Music_Master_Table
	include "sound/flamedriver/UniBank.asm"
Mus_Options:	include "sound/music/91 - Options.asm"
Mus_SpecStage:	include "sound/music/92 - Special Stage.asm"
Mus_Boss:	include "sound/music/93 - Boss.asm"
Mus_EndBoss:	include "sound/music/94 - Final Boss.asm"
Mus_Ending:	include "sound/music/95 - Ending.asm"
Mus_SuperSonic:	include "sound/music/96 - Super Sonic.asm"
Mus_Invincible:	include "sound/music/97 - Invincible.asm"
Mus_ExtraLife:	include "sound/music/98 - Extra Life.asm"
Mus_Title:	include "sound/music/99 - Title Screen.asm"
Mus_EndLevel:	include "sound/music/9A - End of Act.asm"
Mus_GameOver:	include "sound/music/9B - Game Over.asm"
Mus_Continue:	include "sound/music/9C - Continue.asm"
Mus_Emerald:	include "sound/music/9D - Got Emerald.asm"
Mus_Credits:	include "sound/music/9E - Credits.asm"
Mus_Countdown:	include "sound/music/9F - Drowning.asm"
	finishBank
