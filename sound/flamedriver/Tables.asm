; ---------------------------------------------------------------------------
; Sonic 2 tables for Flamedriver (taken from s1_improvements). These replace the
; Sonic 3 & Knuckles tables at the end of Flamedriver's Macros.asm, as its README
; asks. The order of each table decides the IDs: music from $01 (MusID_*),
; sound effects from $01 in the driver (SndID_* in the game follow the music,
; see s2.constants.asm).
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------
; MACRO Gen_Sample_Table
; Every DAC sample the driver knows. Sonic 2 songs use the Sonic 2 set. With
; FeatureS3KDrums their kick, snare and timpani play the Sonic 3 & Knuckles
; samples; the timpani pitches keep Sonic 2's intervals (rate steps +3, +9, +10
; and +11 from the high timpani, the same as Sonic 1's).
Gen_Sample_Table macro declsample
	if (use_s3_samples<>0)||(use_sk_samples<>0)||(use_s3d_samples<>0)
		declsample $04,DAC_81_Data,dSnareS3
		declsample $0E,DAC_82_83_84_85_Data,dHighTom
		declsample $14,DAC_82_83_84_85_Data,dMidTomS3
		declsample $1A,DAC_82_83_84_85_Data,dLowTomS3
		declsample $20,DAC_82_83_84_85_Data,dFloorTomS3
		declsample $04,DAC_86_Data,dKickS3
		declsample $04,DAC_87_Data,dMuffledSnare
		declsample $06,DAC_88_Data,dCrashCymbal
		declsample $0A,DAC_89_Data,dRideCymbal
		declsample $14,DAC_8A_8B_Data,dLowMetalHit
		declsample $1B,DAC_8A_8B_Data,dMetalHit
		declsample $08,DAC_8C_Data,dHighMetalHit
		declsample $0B,DAC_8D_8E_Data,dHigherMetalHit
		declsample $11,DAC_8D_8E_Data,dMidMetalHit
		declsample $08,DAC_8F_Data,dClapS3
		declsample $03,DAC_90_91_92_93_Data,dElectricHighTom
		declsample $07,DAC_90_91_92_93_Data,dElectricMidTom
		declsample $0A,DAC_90_91_92_93_Data,dElectricLowTom
		declsample $0E,DAC_90_91_92_93_Data,dElectricFloorTom
		declsample $06,DAC_94_95_96_97_Data,dTightSnare
		declsample $0A,DAC_94_95_96_97_Data,dMidpitchSnare
		declsample $0D,DAC_94_95_96_97_Data,dLooseSnare
		declsample $12,DAC_94_95_96_97_Data,dLooserSnare
		declsample $0B,DAC_98_99_9A_Data,dHiTimpaniS3
		declsample $13,DAC_98_99_9A_Data,dLowTimpaniS3
		declsample $16,DAC_98_99_9A_Data,dMidTimpaniS3
		declsample $0C,DAC_9B_Data,dQuickLooseSnare
		declsample $0A,DAC_9C_Data,dClick
		declsample $18,DAC_9D_Data,dPowerKick
		declsample $18,DAC_9E_Data,dQuickGlassCrash
	endif
	if (use_s3_samples<>0)||(use_sk_samples<>0)
		declsample $0C,DAC_9F_Data,dGlassCrashSnare
		declsample $0C,DAC_A0_Data,dGlassCrash
		declsample $0A,DAC_A1_Data,dGlassCrashKick
		declsample $0A,DAC_A2_Data,dQuietGlassCrash
		declsample $18,DAC_A3_Data,dOddSnareKick
		declsample $18,DAC_A4_Data,dKickExtraBass
		declsample $0C,DAC_A5_Data,dComeOn
		declsample $09,DAC_A6_Data,dDanceSnare
		declsample $18,DAC_A7_Data,dLooseKick
		declsample $18,DAC_A8_Data,dModLooseKick
		declsample $0C,DAC_A9_Data,dWoo
		declsample $0A,DAC_AA_Data,dGo
		declsample $0D,DAC_AB_Data,dSnareGo
		declsample $06,DAC_AC_Data,dPowerTom
		declsample $10,DAC_AD_AE_Data,dHiWoodBlock
		declsample $18,DAC_AD_AE_Data,dLowWoodBlock
		declsample $09,DAC_AF_B0_Data,dHiHitDrum
		declsample $12,DAC_AF_B0_Data,dLowHitDrum
		declsample $18,DAC_B1_Data,dMetalCrashHit
		declsample $16,DAC_B2_B3_Data,dEchoedClapHit
		declsample $20,DAC_B2_B3_Data,dLowerEchoedClapHit
		declsample $0C,DAC_B4_C1_C2_C3_C4_Data,dHipHopHitKick
		declsample $0C,DAC_B5_Data,dHipHopHitPowerKick
		declsample $0C,DAC_B6_Data,dBassHey
		declsample $18,DAC_B7_Data,dDanceStyleKick
		declsample $0C,DAC_B8_B9_Data,dHipHopHitKick2
		declsample $0C,DAC_B8_B9_Data,dHipHopHitKick3
		declsample $18,DAC_BA_Data,dReverseFadingWind
		declsample $18,DAC_BB_Data,dScratchS3
		declsample $18,DAC_BC_Data,dLooseSnareNoise
		declsample $0C,DAC_BD_Data,dPowerKick2
		declsample $0C,DAC_BE_Data,dCrashingNoiseWoo
		declsample $1C,DAC_BF_Data,dQuickHit
		declsample $0B,DAC_C0_Data,dKickHey
		declsample $0F,DAC_B4_C1_C2_C3_C4_Data,dPowerKickHit
		declsample $11,DAC_B4_C1_C2_C3_C4_Data,dLowPowerKickHit
		declsample $12,DAC_B4_C1_C2_C3_C4_Data,dLowerPowerKickHit
		declsample $0B,DAC_B4_C1_C2_C3_C4_Data,dLowestPowerKickHit
	endif
	if (use_s2_samples<>0)
	if FeatureS3KDrums
		declsample $04,DAC_86_Data,dKick
		declsample $04,DAC_81_Data,dSnare
	else
		declsample $17,DAC_C5_Data,dKick
		declsample $01,DAC_C6_Data,dSnare
	endif
		declsample $06,DAC_C7_Data,dClap
		declsample $08,DAC_C8_Data,dScratch
	if FeatureS3KDrums
		declsample $14,DAC_98_99_9A_Data,dTimpani
	else
		declsample $1B,DAC_C9_CC_CD_CE_CF_Data,dTimpani
	endif
		declsample $0A,DAC_CA_D0_D1_D2_Data,dHiTom
		declsample $1B,DAC_CB_D3_D4_D5_Data,dVLowClap
	if FeatureS3KDrums
		declsample $0B,DAC_98_99_9A_Data,dHiTimpani
		declsample $0E,DAC_98_99_9A_Data,dMidTimpani
		declsample $15,DAC_98_99_9A_Data,dLowTimpani
		declsample $16,DAC_98_99_9A_Data,dVLowTimpani
	else
		declsample $12,DAC_C9_CC_CD_CE_CF_Data,dHiTimpani
		declsample $15,DAC_C9_CC_CD_CE_CF_Data,dMidTimpani
		declsample $1C,DAC_C9_CC_CD_CE_CF_Data,dLowTimpani
		declsample $1D,DAC_C9_CC_CD_CE_CF_Data,dVLowTimpani
	endif
		declsample $02,DAC_CA_D0_D1_D2_Data,dMidTom
		declsample $05,DAC_CA_D0_D1_D2_Data,dLowTom
		declsample $08,DAC_CA_D0_D1_D2_Data,dFloorTom
		declsample $08,DAC_CB_D3_D4_D5_Data,dHiClap
		declsample $0B,DAC_CB_D3_D4_D5_Data,dMidClap
		declsample $12,DAC_CB_D3_D4_D5_Data,dLowClap
	endif
	if (use_s3d_samples<>0)
		declsample $01,DAC_D6_Data,dFinalFightMetalCrash
		declsample $12,DAC_D7_Data,dIntroKick
	endif
	if (use_s3_samples<>0)
		declsample $16,DAC_D8_D9_Data,dEchoedClapHit_S3
		declsample $20,DAC_D8_D9_Data,dLowerEchoedClapHit_S3
	endif
	endm

; ---------------------------------------------------------------------------
; MACRO Gen_Music_Table
; The songs, in Sonic 2's MusID order (so the IDs stay $01-$1F). The driver
; needs MusID_ExtraLife for the 1-up song.
Gen_Music_Table macro declsong
	declsong 2PResult
	declsong EHZ
	declsong MCZ_2P
	declsong OOZ
	declsong MTZ
	declsong HTZ
	declsong ARZ
	declsong CNZ_2P
	declsong CNZ
	declsong DEZ
	declsong MCZ
	declsong EHZ_2P
	declsong SCZ
	declsong CPZ
	declsong WFZ
	declsong HPZ
	declsong Options
	declsong SpecStage
	declsong Boss
	declsong EndBoss
	declsong Ending
	declsong SuperSonic
	declsong Invincible
	declsong ExtraLife
	declsong Title
	declsong EndLevel
	declsong GameOver
	declsong Continue
	declsong Emerald
	declsong Credits
	declsong Countdown
	endm

; ---------------------------------------------------------------------------
; MACRO Gen_Sound_Table
; The sound effects, in Sonic 2's SndID order, except that RingLeft follows
; Ring: the driver alternates Ring with the entry right after it. It also
; raises the pitch of repeated Spindash revs (Sonic 2's SpindashRev).
; Unused38 and Unused47 are Sonic 2's unused slots $B8 and $C7.
Gen_Sound_Table macro declsfx
	declsfx Jump
	declsfx Checkpoint
	declsfx SpikeSwitch
	declsfx Hurt
	declsfx Skidding
	declsfx MissileDissolve
	declsfx HurtBySpikes
	declsfx Sparkle
	declsfx Beep
	declsfx Bwoop
	declsfx Splash
	declsfx Swish
	declsfx BossHit
	declsfx InhalingBubble
	declsfx ArrowFiring
	declsfx Shield
	declsfx LaserBeam
	declsfx Zap
	declsfx Drown
	declsfx FireBurn
	declsfx Bumper
	declsfx Ring
	declsfx RingLeft
	declsfx SpikesMove
	declsfx Rumbling
	declsfx Unused38
	declsfx Smash
	declsfx TailsGrab
	declsfx DoorSlam
	declsfx SpindashRelease
	declsfx Hammer
	declsfx Roll
	declsfx ContinueJingle
	declsfx CasinoBonus
	declsfx Explosion
	declsfx WaterWarning
	declsfx EnterGiantRing
	declsfx BossExplosion
	declsfx TallyEnd
	declsfx RingSpill
	declsfx Unused47
	declsfx Flamethrower
	declsfx Bonus
	declsfx SpecStageEntry
	declsfx SlowSmash
	declsfx Spring
	declsfx Blip
	declsfx Signpost
	declsfx CNZBossZap
	declsfx TailsFly
	declsfx TailsTired
	declsfx Signpost2P
	declsfx OOZLidPop
	declsfx SlidingSpike
	declsfx CNZElevator
	declsfx PlatformKnock
	declsfx BonusBumper
	declsfx LargeBumper
	declsfx Gloop
	declsfx PreArrowFiring
	declsfx Fire
	declsfx ArrowStick
	declsfx Helicopter
	declsfx SuperTransform
	declsfx Spindash
	declsfx Rumbling2
	declsfx CNZLaunch
	declsfx Flipper
	declsfx HTZLiftClick
	declsfx Leaves
	declsfx MegaMackDrop
	declsfx DrawbridgeMove
	declsfx QuickDoorSlam
	declsfx DrawbridgeDown
	declsfx LaserBurst
	declsfx Scatter
	declsfx Teleport
	declsfx Error
	declsfx MechaSonicBuzz
	declsfx LargeLaser
	declsfx OilSlide
	endm

; ---------------------------------------------------------------------------
; MACRO Gen_ContinuousSound_Table
; Sonic 2 has no continuous sound effects.
Gen_ContinuousSound_Table macro declsfx
	endm
