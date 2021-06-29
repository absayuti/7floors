!------------------------------------------------------------------------------
!- JUMPMAN
!- Initialization subroutines
!-
3000 ro$="{home}{down*24}"      :rem row/column placement string 
3005 co$="{right*39}"
3010 gosub 3100                 :rem setup SID
3020 gosub 3200                 :rem setup VIC II
3025 gosub 2700                 :rem Title screen
3030 gosub 3400                 :rem copy character ROM
3035 gosub 3600                 :rem setup custom characters
3040 gosub 4000                 :rem setup sprites
3050 gosub 3800                 :rem setup control block
3060 return
!------------------------------------------------------------------------------
#region SID SETUP
!------------------------------------------------------------------------------
3100 print"{home}{reverse off}{yellow}{down*22}{right*12}please wait..."
3110 so=54272 : for i=so to so+24 : poke i,0 : next
3120 rem poke so+24,0: poke so+4,65: poke so+6,240
3130 return
#endregion
!------------------------------------------------------------------------------
#region "RELOCATE AND SETUP SCREEN + relocate charset"
!------------------------------------------------------------------------------
!-
!-   poke VIC+24, A+B
!-
!-   A = TXTSCR location = base + offset*1024
!-                            (offset = bits 4-7 of 53272 (VIC+24))
!-
!-   0000xxxx  0  base               poke VIC+24, 0+B
!-   0001xxxx  0  base+1024  $0400   poke VIC+24, 16+B
!-   0010xxxx  0  base+2048  $0800   poke VIC+24, 32+B   <=== $C800
!-   0011xxxx  0  base+3072  $0C00   poke VIC+24, 48+B
!-   0100xxxx  0  base+4096  $1000   poke VIC+24, 64+B
!-   0101xxxx  0  base+5120  $1400   poke VIC+24, 80+B
!-   0110xxxx  0  base+6144  $1800   poke VIC+24, 96+B
!-   0111xxxx  0  base+7168  $1C00   poke VIC+24, 112+B
!-   1000xxxx  0  base+8192  $2000   poke VIC+24, 128+B
!-   1001xxxx  0  base+8192  $2000   poke VIC+24, 144+B
!-   1010xxxx  0  base+8192  $2000   poke VIC+24, 160+B
!-   1011xxxx  0  base+8192  $2000   poke VIC+24, 176+B
!-   1100xxxx  0  base+8192  $2000   poke VIC+24, 192+B
!-   1101xxxx  0  base+8192  $2000   poke VIC+24, 208+B
!-   1110xxxx  0  base+8192  $2000   poke VIC+24, 234+B
!-   1111xxxx  0  base+8192  $2000   poke VIC+24, 240+B
!-
!-   B = CHARSET location = base + offset*2048
!-                            (offset = bits 1-3 of 53272 (VIC+24)
!-
!-   xxxx000x  0  base              poke VIC+24, A
!-   xxxx001x  2  base+2048 $0800   poke VIC+24, A+2
!-   xxxx010x  4  base+4096 $1000   poke VIC+24, A+4   <=== $D000
!-   xxxx011x  6  base+6144 $1800   poke VIC+24, A+6
!-   xxxx100x  8  base+8192  $2000  poke VIC+24, A+8
!-   xxxx101x 10  base+10240 $2800  poke VIC+24, A+10
!-   xxxx110x 12  base+12288 $3000  poke VIC+24, A+12
!-   xxxx111x 14  base+14336 $3800  poke VIC+24, A+14
!-
!-
!-   KERNEL's TXTSCR pointer = poke 648, P*256
!-
!-   e.g. TXTSCR @ $C800 = 51200
!-
!-                       --> 51200/256 = 200
!-                       --> poke 648,200
!-
3200 poke 56576,peek(56576)and252  :rem MOVE VIC BANK TO $C000–$FFFF
3210 vic=53248
3220 poke vic+24,32+4              :rem TXTSCR AT $C800, CHARSET AT $D000
3230 poke 648,200                  :rem TELL KERNEL TXTSCR AT $C800 (51200)
3240 txt=51200: co=55296           :rem TXTSCR RAM & colour RAM
3260 return
#endregion
!------------------------------------------------------------------------------
#region "COPY CHARACTER ROM TO RAM UNDERNEATH""
!------------------------------------------------------------------------------
3400 print"{home}{reverse off}{yellow}{down*22}{right*12}please wait..."
3410 sa=828
3420 for n=0 to 36
3430 read a% : poke sa+n,a%: next n
3440 sys sa
3450 return
3460 rem - ML - COPY CHAR ROM
3470 data 120,162,8,165,1,41,251,133
3480 data 1,169,208,133,252,160,0,132
3490 data 251,177,251,145,251,200,208,249
3500 data 230,252,202,208,244,165,1,9
3510 data 4,133,1,88,96
#endregion
!------------------------------------------------------------------------------
#region "SETUP CUSTOM CHARACTER DATA"
!------------------------------------------------------------------------------
3600 poke 56334, peek(56334) and 254    :rem Interrupts deactivate
3610 poke 1,peek(1) and 251             :rem E/A area deactivate, char set rom online
3615 read n
3618 if n<0 then 3650
3620 for a=53248+n*8 to 53248+n*8+7     :rem Poke custom characters data
3625   read d
3630   poke a,d
3640 next
3645 goto 3615
3650 poke 1,peek(1)or4                  :rem E/A area activate
3660 poke 56334, peek(56334) or 1       :rem Interrupts activate
3670 return
3680 rem
3690 rem custom chars data
3700 DATA 27, 127,96,96,96,127,96,96,96 : REM CHARACTER 27
3710 DATA 29, 254,6,6,6,254,6,6,6 : REM CHARACTER 29
3720 DATA 35, 247,247,247,0,254,254,254,0 : REM CHARACTER 35
3790 data -1
#endregion
!------------------------------------------------------------------------------
#region "SETUP/INIT CONTROL BLOCK AT 820-8xx"
!------------------------------------------------------------------------------
!- Nothing to really setup for this program
!-   820 = Barrel launch flag
!-   821 = Maximum number of barrels to use
!-   822 = Player-barrel collision flag (from ML)
!-   823 = Flag=0 -> Reset barrel to zero
!-
3800 cb=820: mx=821: ht=822: rs=823    
3890 return
!-
!------------------------------------------------------------------------------
#region "SETUP/INIT SPRITES"
!------------------------------------------------------------------------------
4000 sa=txt+1024        :rem Read sprite DATA
4010 for n=0 to 14*64-1
4020    read a: poke sa+n,a
4030 next n
4040 sp=txt+1016        :rem SPRITE SHAPE POINTER: sp+N,48+S
4050 dim ss(7)          :rem Sprite shape vector for player(state#)
4060 ss(0)=49: ss(1)=50: ss(2)=52: ss(3)=54: ss(4)=55: ss(5)=56: ss(6)=57
4100 poke vic+21,255    :rem SWITCH ON SPRITES
4110 vm = vic+16        :rem MSB for sprites' X position (53264)
4120 poke vic+27,0      :rem Sprites in FRONT of characters (53275)
4130 poke vic+39,1      :rem White player
4140 for i=1 to 7
4150   poke vic+39+i,6+i :rem Different colours for the barrels
4160 next
4190 return
#endregion
!------------------------------------------------------------------------------
#region "SPRITE DATA"
!------------------------------------------------------------------------------
4200 rem STAND
4210 data 0,0,0,1,128,0,1,128,0
4220 data 0,128,0,1,192,0,1,192,0
4230 data 1,160,0,3,160,0,1,192,0
4240 data 1,192,0,0,128,0,0,128,0
4250 data 0,192,0,0,192,0,0,160,0
4260 data 1,160,0,0,0,0,0,0,0
4270 data 0,0,0,0,0,0,0,0,0
4280 data 0
4290 rem STAND
4300 data 0,0,0,0,192,0,0,192,0
4310 data 0,128,0,1,192,0,1,192,0
4320 data 2,192,0,2,224,0,1,192,0
4330 data 1,192,0,0,128,0,0,128,0
4340 data 1,128,0,1,128,0,2,128,0
4350 data 2,192,0,0,0,0,0,0,0
4360 data 0,0,0,0,0,0,0,0,0
4370 data 0
4380 rem LEFT-1
4390 data 0,0,0,6,0,0,6,0,0
4400 data 2,0,0,7,0,0,7,0,0
4410 data 15,128,0,14,128,0,6,128,0
4420 data 14,0,0,22,0,0,19,0,0
4430 data 17,0,0,49,128,0,0,128,0
4440 data 0,128,0,0,0,0,0,0,0
4450 data 0,0,0,0,0,0,0,0,0
4460 data 0
4470 rem LEFT-2
4480 data 0,0,0,3,0,0,3,0,0
4490 data 1,0,0,3,192,0,7,160,0
4500 data 7,160,0,27,192,0,3,128,0
4510 data 3,128,0,2,128,0,2,192,0
4520 data 4,48,0,4,16,0,4,0,0
4530 data 12,0,0,0,0,0,0,0,0
4540 data 0,0,0,0,0,0,0,0,0
4550 data 0
4560 rem RIGHT-1
4570 data 0,0,0,0,96,0,0,96,0
4580 data 0,64,0,0,224,0,0,224,0
4590 data 1,240,0,1,112,0,1,96,0
4600 data 0,112,0,0,104,0,0,200,0
4610 data 0,136,0,1,140,0,1,0,0
4620 data 1,0,0,0,0,0,0,0,0
4630 data 0,0,0,0,0,0,0,0,0
4640 data 0
4650 rem RIGHT-2
4660 data 0,0,0,0,192,0,0,192,0
4670 data 0,128,0,3,192,0,5,224,0
4680 data 5,224,0,3,216,0,1,192,0
4690 data 1,192,0,1,64,0,3,64,0
4700 data 12,32,0,8,32,0,0,32,0
4710 data 0,48,0,0,0,0,0,0,0
4720 data 0,0,0,0,0,0,0,0,0
4730 data 0
4740 rem CLIMB-1
4750 data 0,0,0,3,0,0,3,32,0
4760 data 1,32,0,11,224,0,15,128,0
4770 data 11,128,0,3,128,0,3,128,0
4780 data 7,128,0,4,128,0,4,128,0
4790 data 12,128,0,0,128,0,0,128,0
4800 data 0,192,0,0,0,0,0,0,0
4810 data 0,0,0,0,0,0,0,0,0
4820 data 0
4830 rem CLIMB-2
4840 data 0,0,0,1,128,0,9,128,0
4850 data 9,0,0,15,160,0,3,224,0
4860 data 3,160,0,3,128,0,3,128,0
4870 data 3,192,0,2,64,0,2,64,0
4880 data 2,96,0,2,0,0,2,0,0
4890 data 6,0,0,0,0,0,0,0,0
4900 data 0,0,0,0,0,0,0,0,0
4910 data 0
4920 rem JUMP-L
4930 data 0,0,0,6,0,0,6,0,0
4940 data 1,0,0,3,128,0,23,192,0
4950 data 11,32,0,3,64,0,3,128,0
4960 data 15,144,0,112,232,0,32,192,0
4970 data 0,0,0,0,0,0,0,0,0
4980 data 0,0,0,0,0,0,0,0,0
4990 data 0,0,0,0,0,0,0,0,0
5000 data 0
5010 rem JUMP-R
5020 data 0,0,0,0,96,0,0,96,0
5030 data 0,128,0,1,192,0,3,232,0
5040 data 4,208,0,2,192,0,1,192,0
5050 data 9,240,0,23,14,0,3,4,0
5060 data 0,0,0,0,0,0,0,0,0
5070 data 0,0,0,0,0,0,0,0,0
5080 data 0,0,0,0,0,0,0,0,0
5090 data 0
5100 rem BARREL-1
5110 data 0,0,0,7,224,0,30,248,0
5120 data 55,172,0,127,126,0,94,250,0
5130 data 253,247,0,187,237,0,247,223,0
5140 data 175,191,0,95,122,0,126,238,0
5150 data 53,188,0,31,248,0,7,224,0
5160 data 0,0,0,0,0,0,0,0,0
5170 data 0,0,0,0,0,0,0,0,0
5180 data 0
5190 rem BARREL-2
5200 data 0,0,0,7,224,0,29,120,0
5210 data 55,220,0,127,246,0,95,254,0
5220 data 245,91,0,191,255,0,191,253,0
5230 data 234,175,0,95,250,0,111,254,0
5240 data 59,236,0,30,184,0,7,224,0
5250 data 0,0,0,0,0,0,0,0,0
5260 data 0,0,0,0,0,0,0,0,0
5270 data 0
5280 rem BARREL-2
5290 data 0,0,0,7,224,0,31,120,0
5300 data 53,220,0,126,246,0,95,126,0
5310 data 239,187,0,183,223,0,187,237,0
5320 data 253,247,0,94,250,0,111,126,0
5330 data 59,172,0,30,248,0,7,224,0
5340 data 0,0,0,0,0,0,0,0,0
5350 data 0,0,0,0,0,0,0,0,0
5360 data 0
5370 rem CLIMB-1
5380 data 0,0,0,33,132,0,17,136,0
5390 data 9,16,0,7,224,0,7,192,0
5400 data 3,128,0,3,128,0,3,128,0
5410 data 3,128,0,6,192,0,4,32,0
5420 data 8,16,0,80,10,0,32,4,0
5430 data 0,0,0,0,0,0,0,0,0
5440 data 0,0,0,0,0,0,0,0,0
5450 data 0
#endregion