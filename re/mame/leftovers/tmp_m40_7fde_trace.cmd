bp a800,,{ printf "BP a800 r2=%04X r3=%04X r4=%04X r5=%04X r6=%04X r7=%04X r14=%04X r15=%04X\n",r2,r3,r4,r5,r6,r7,r14,r15 ; g }
bp a92a,,{ printf "BP a92a r2=%04X r3=%04X r4=%04X r5=%04X r6=%04X r7=%04X r14=%04X r15=%04X\n",r2,r3,r4,r5,r6,r7,r14,r15 ; g }
bp b668,,{ printf "BP b668 r2=%04X r3=%04X r4=%04X r5=%04X r6=%04X r7=%04X r14=%04X r15=%04X\n",r2,r3,r4,r5,r6,r7,r14,r15 ; g }
bp 7fde,,{ printf "BP 7fde pc=%08X r2=%04X r3=%04X r4=%04X r5=%04X r6=%04X r7=%04X r14=%04X r15=%04X\n",pc,r2,r3,r4,r5,r6,r7,r14,r15 ; g }
bp 7fe8,,{ printf "BP 7fe8 FATAL pc=%08X r2=%04X r3=%04X r4=%04X r5=%04X r6=%04X r7=%04X r14=%04X r15=%04X\n",pc,r2,r3,r4,r5,r6,r7,r14,r15 ; g }
bp 8002,,{ printf "BP 8002 RETURN pc=%08X r2=%04X r3=%04X r4=%04X r5=%04X r6=%04X r7=%04X r14=%04X r15=%04X\n",pc,r2,r3,r4,r5,r6,r7,r14,r15 ; g }
g
