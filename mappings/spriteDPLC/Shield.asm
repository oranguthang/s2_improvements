MapR_Shield: mappingsTable
	mappingsTableEntry.w ShieldDPLC_0
	mappingsTableEntry.w ShieldDPLC_1
	mappingsTableEntry.w ShieldDPLC_2
	mappingsTableEntry.w ShieldDPLC_3
	mappingsTableEntry.w ShieldDPLC_4
	mappingsTableEntry.w ShieldDPLC_5
ShieldDPLC_0: dplcHeader
	dplcEntry 4, $0
ShieldDPLC_0_End
ShieldDPLC_1: dplcHeader
	dplcEntry 4, $4
ShieldDPLC_1_End
ShieldDPLC_2: dplcHeader
	dplcEntry 4, $8
ShieldDPLC_2_End
ShieldDPLC_3: dplcHeader
	dplcEntry 4, $C
ShieldDPLC_3_End
ShieldDPLC_4: dplcHeader
	dplcEntry 4, $10
ShieldDPLC_4_End
ShieldDPLC_5: dplcHeader
	dplcEntry 12, $14
ShieldDPLC_5_End
	even
