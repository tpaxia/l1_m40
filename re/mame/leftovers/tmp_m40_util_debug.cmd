bp bbd0,,{ printf "HIT bbd0 R0=%04X R3=%04X R6=%04X R7=%04X\n",r0,r3,r6,r7 ; trace /private/tmp/m40_util_trace.tr,0 ; g }
bp c186,,{ printf "HIT c186 R0=%04X R3=%04X R6=%04X R7=%04X\n",r0,r3,r6,r7 ; g }
bp c200,,{ printf "HIT c200 R0=%04X R3=%04X R6=%04X R7=%04X\n",r0,r3,r6,r7 ; g }
g
