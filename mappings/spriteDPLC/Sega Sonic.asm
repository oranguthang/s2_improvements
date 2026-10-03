; Four private running frames for the Sega screen; independent of player assets.
.offsets:	mappingsTable
	mappingsTableEntry.w	.frame0
	mappingsTableEntry.w	.frame1
	mappingsTableEntry.w	.frame2
	mappingsTableEntry.w	.frame3

.frame0:	dplcHeader
	dplcEntry	$6, $0
	dplcEntry	$10, $6
.frame0_End

.frame1:	dplcHeader
	dplcEntry	$6, $16
	dplcEntry	$10, $1C
.frame1_End

.frame2:	dplcHeader
	dplcEntry	$6, $2C
	dplcEntry	$10, $32
.frame2_End

.frame3:	dplcHeader
	dplcEntry	$6, $42
	dplcEntry	$10, $48
.frame3_End
