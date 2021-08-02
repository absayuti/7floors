!- ========================================
!- Project   : JumpMan a.ka. 7 Floors
!- Target    : Commodore 64
!- Comments  : Lightly based on Bonking Barrels (Compute!'s Gazette)
!- Author    : ABSHMS
!- ========================================
!- 
!-    v 0.1  21 Apr 2021
!-              Setup VIC, SID, sprites, control block etc
!-    v 0.2  13 June 2021
!-              Game screen, basic player movement
!-    v 0.3  14 June 2021
!-              Changed Ysize to 8. Adjust movement
!-              Simplified left/right motion -- dont need loop
!-              Player climbing up/down motion
!-              Small changes to the sprites - thinner man
!-                     included climbing man images
!-    v0.31  15 June 2021
!-              Added jumping man sprite images
!-              Added player jumping over gap when space bar is pressed
!-              Now, player will fall through a gap, with a sound effect
!-              Added GOAL and "reached goal" detection and sound
!-
!-    v0.40  17 June 2021
!-              ML code for rolling barrels. A barrel can ROLL, DROP or OFF.
!-              Control block: Launch barrel (flag), maximum barrels (number), 
!-              collision barrel-player (flag)
!-
!-    v0.41  23 June 2021
!-    v0.42  24 June 2021
!-              Modified state+image+keypress for better animation            
!-              Detect hit (collision of sprite0 and sprite1)
!-
!-    v0.43  27 June 2021
!-              Game play, timing, sequence, loops etc
!-              Title screen
!-              Improved sound effects
!-
!------------------------------------------------------------------------------
#region "Top comment block"
10 rem ********************************
20 rem            7 Floors
30 rem      
40 rem    Commodore 64 CBM BASIC 2.0
50 rem Lightly based on Bonking Barrels
60 rem   (Compute!'s Gazette 1984)
70 rem 
80 rem          ABSHMS 2021
90 rem ********************************
#endregion
!------------------------------------------------------------------------------
#region "Setup"
!-
100 gosub 2700                  :rem title screen 
106 xo=24 :xs=8 :yo=66 :ys=8    :rem Xoffset,Xsize,Yoffset,Ysize
108 xx=38 :yy=7                 :rem Xmax,Ymax (block size)
120 gosub 3000                  :rem General setup
130 gosub 6000                  :rem ML code loader
#endregion
!------------------------------------------------------------------------------
#region "MAIN ROUTINE/loop"
!-
!-  Repeat play game
180 gosub 1700     :rem INITIALIZE game
!-    Repeat game screen
200     gosub 1800 :rem Reset game screen/level
210     gosub 2000 :rem Setup game screen/level
215     gosub 300  :rem Play game screen/level
220     for t=1 to 1000: next
225     if ov<>0 then pl=pl-1
230     if pl=0 then 260
240     gosub 2800 :rem Continue
245     if ov=0 then lv=lv+1
!-    Until no more life
250   goto 200
!-
260   gosub 2900 :rem No more life, play again?
265   if k=0 then 280
!-  Loop until user quit
270 goto 180     :rem Play again from the beginning
!-
280 print"ok. bye!"
290 end
!-
#endregion
!------------------------------------------------------------------------------
#region "Play game screen/level"
!-  
300 gosub 500           :rem Place player
310 x=peek(vi+30)       :rem Clear collision register
315 n=20                :rem first barrel launched after 10 loops
!-
!-  REPEAT
!-    Roll barrels
320   sys 49152 :rem Launch/roll/drop/off barrels
!-    Check hit_flag
330   if peek(ht)<>0 then gosub 2400: ov=2: return
!-    If player is jumping, continue jumping and skip input
340   if jm>0 then goto 400
!-
!-    Get input --> change X/Y/shape
350   s=0     
355   get k$
360   if k$="{left}" then s=1: goto 400  
365   if k$="{right}" then s=2: goto 400 
370   if k$="{up}" then s=3: goto 400    
375   if k$="{down}" then s=4: goto 400 
380   if k$=" " and fc=1 then s=5: goto 400
385   if k$=" " and fc=2 then s=6: goto 400
!-
!-    Change to immediate shape
400   if s=0 then poke sp,49+(fc=1)
!-    Calculate next position & shape
410   on s gosub 600,700,800,1000,1200,1300
420   if s<>0 then gosub 500
!-
!-    Check gap on floor --> fall down
430   if jm=0 then gosub 1500
!-
!-    Count down to launch new barrel     
440   n=n-1
445   if n>0 then 470
450     poke cb,1: n=bt: bn=bn-1: sc=sc+10
455     print"{home}{reverse on}{dark gray}{right*5}"sc;     
460     print"{home}{right*36}   {left*3}"bn;
465     if bn=0 then ov=1 : return
!-
!-    Check goal
470   gosub 1400 :rem Check IF player reached GOAL
480   if ov=0 then return
!-
!-  UNTIL GAME OVER
490 goto 320
#endregion
!-
!------------------------------------------------------------------------------
#region "Place player"
!-
500 x=px*xs+xo : y=py*ys+yo
510 poke sp,ps
520 if x<256 then poke vm,peek(vm)and254: poke vi,x: goto 540
530 poke vm,peek(vm)or1: poke vi,x-255
540 poke vi+1,y
550 return
#endregion
!-
!------------------------------------------------------------------------------
#region "Move left"
!-
600 if cm>0 then return         :rem Player is on ladder
605 fq=3000: gosub 2500
610 px=px-2
620 if px<0 then px=0           :rem Hit left wall
630 ps=51
640 fc=1
650 return
#endregion
!-----------------------------------------------------------------------------
#region "Move right"
!-
700 if cm>0 then return         :rem Player is on ladder
705 fq=4000: gosub 2500
710 px=px+2
720 if px>xx then px=xx         :rem Hit right wall
730 ps=53
740 fc=2
750 return
#endregion
!-
!------------------------------------------------------------------------------
#region "Climb UP ladder"
!-
800 if cm<>0 then 830           :rem IF already in climbing mode, just climb
810   cc = py*40+px+txtscr+40   :rem ELSE check if player is under a ladder
820   if peek(cc)<>27 then return
830 py=py-1
840 ps=54
850 cm=cm+1                     :rem Count climbing motion
855 if cm<3 then return         :rem IF NOT top of ladder, return
860 fl=fl+1                     :rem ELSE, count 1 floor up
870 cm=0                        :rem RESET climb motion counter
880 ps=48                       :rem standing man again
885 if fc=2 then ps=49
888 sc=sc+10: print"{home}{reverse on}{dark gray}{right*5}"sc;
890 return
#endregion
!------------------------------------------------------------------------------
#region "Climb DOWN ladder"
!-
1000 if cm<>0 then 1030           :rem IF already in climbing mode, just climb
1010   cc=(py+2)*40+px+txtscr+80  :rem ELSE check if player is ON a ladder
1020   if peek(cc)<>27 then return
1025   cm=3
1030 py=py+1
1040 ps=53
1050 cm=cm-1                     :rem Count climbing motion
1055 if cm>0 then return         :rem IF NOT at bottom of ladder, return
1060 fl=fl-1                     :rem ELSE, count 1 floor down
1070 cm=0                        :rem RESET climb motion counter 
1080 ps=48  
1085 if fc=2 then ps=49
1088 sc=sc-10: print"{home}{reverse on}{dark gray}{right*5}"sc;
1090 return
#endregion
!-
!------------------------------------------------------------------------------
#region "Jump left"
!-
1200 if cm>0 then return        :rem Player is on ladder, dont jump
1205 if jm=1 then gosub 2600 :rem sound
1210 px=px-1
1220 if px<0 then px=0          :rem Hit left wall
1230 ps=56
1240 jm=jm+1
1250 if jm=4 then jm=0: ps=48
1260 return
#endregion
!------------------------------------------------------------------------------
#region "Jump right"
!-
1300 if cm>0 then return        :rem Player is on ladder
1305 if jm=1 then gosub 2600 :rem sound
1310 px=px+1 
1320 if px>xx then px=xx        :rem Hit right wall
1330 ps=57
1340 jm=jm+1
1350 if jm=4 then jm=0: ps=49
1360 return
#endregion
!-
!------------------------------------------------------------------------------
#region "Check if goal is reached"
1400 ov = -1
1410 cc = py*40+px+txtscr+80     :rem IF NOT the goal THEN ignore
1420 if peek(cc)<>225 then return
1430 gosub 2300                  :rem Tadadaa sound
1440 ov = 0
1450 sc=sc+50: print"{home}{reverse on}{dark gray}{right*5}"sc;
1490 return
#endregion
!-
!------------------------------------------------------------------------------
#region "Check for gap --> fall?"
!- 
1500 if fl=0 then return        :rem CAN'T fall if at ground floor
1505 cc = (py+2)*40+px+txtscr+80   :rem IF NOT a gap THEN ignore
1510 if peek(cc)<>32 or peek(cc+1)<>32 then return
1520 for i=1 to 3               :rem ELSE fall
1530   py=py+1
1540   y=py*ys+yo 
1550   poke vi+1,y
1560 next
1570 gosub 2200         :rem BHUP sound
1580 fl=fl-1 :rem Down one floor
1585 sc=sc-10: print"{home}{reverse on}{dark gray}{right*5}"sc;
1590 return
#endregion
!------------------------------------------------------------------------------
#region "INITIALIZE GAME"
!-
1700 lv=1       :rem Start at level 1
1710 sc=0       :rem score = 0
1720 pl=3       :rem 3 lives
1730 jm=0: cm=0 :rem not jumping, not climbing
1790 return
#endregion
!------------------------------------------------------------------------------
#region "RESET GAME SCREEN"
!-
1800 bt = int(100/lv)   :rem Timer for new barrel launch
1810 if bt<10 then bt=10
1814 bn = 25            :rem Number of barrels to timeout
1816 bm = 3+lv          :rem Max num barrel launched
1818 if bm>7 then bm=7
1820 poke cb,0: poke mx,bm :rem reset launch barrel flag, set max num barrels
1822 poke ht,0: poke rs,0 :rem reset "hit" register, reset all barrels
1830 for i=0 to 7       :rem RESET all sprites' positions
1840   poke vi+i*2,0: poke vi+i*2+1,0
1850 next
1870 px=0: py=7*3: fl=0 :rem X,Y position; floor #
1875 fc=0               :rem Man facing forward
1880 s=0: ps=ss(s)      :rem Standing man image
1885 poke vi+21,255     :rem ON all sprites
1890 return
#endregion
!------------------------------------------------------------------------------
#region "SETUP GAME SCREEN"
!-              Top banner + exit point
2000 poke 53280,11: poke 53281,0 :rem gray+black
2002 print"{clear}{dark gray}{reverse on}{space*40}";
2005 print"{home}score"sc"{right*8}level"lv"{right*3}p"pl;
2006 print"{home}{right*35}b"bn;
2008 print left$(ro$,3)left$(co$,38)"{cyan}{reverse on}{cm k} ";
2009 print left$(ro$,4)left$(co$,38)"{cm k} {reverse off}";
!-              Place platforms
2010 a$="{pink}"
2015 for i=1 to 20: a$=a$+"##" :next
2017 print"{home}";
2020 for i=1 to 7
2030   print :print
2040   print a$;
2050 next
!-             make holes and place ladders
2058 h0=19 :j0=19                      :rem prev hole,ladder values
2060 for i=1 to 7
2070   h=int(rnd(0)*20)                :rem location of hole
2075   if h=j0 then 2070
2080   print left$(ro$,i*3+2)left$(co$,h*2)"  ";
2090   j=int(rnd(0)*19)                :rem location of ladder
2095   if abs(j-h)<2 OR j=h0 or j=j0 then 2090 
2100   print left$(ro$,i*3+2)left$(co$,j*2)"{green}[]";
2105   print left$(ro$,i*3+3)left$(co$,j*2)"[]";
2110   print left$(ro$,i*3+4)left$(co$,j*2)"[]";
2115   h0=h :j0=j
2120   next
2130 print"{home}"
2190 return
#endregion
!------------------------------------------------------------------------------
#region "BHUP sound -- man bump onto something"
!-
2200 poke so+8,1         :rem Set high pulse width for voice 1
2210 poke so+24,15       :rem Set volume 15
2220 poke so+5,0*16+6    :rem Set Attack/decay for voice I
2230 poke so+6,10*16+0   :rem Set Sustain/Release for voice I
2240 poke so+4,32+1      :rem start SAWTOOTH waveform control voice 1
2250 fq=1200             :rem Set frequency 
2260 hf=int(fq/256) : lf=fq-hf*256
2270 poke so+0,lf : poke so+1,hf :rem high.and low frequencies for voice 1
2280 for t=1 to 100: next :rem wait for a short while
2285 poke so+4,32        :rem SAWTOOTH gate OFF
2290 poke so+24,0        :rem Set volume OFF
2295 return
#endregion
!------------------------------------------------------------------------------
#region "TA DA DAA -- goal reached"
!-
2300 poke so+24,15  :rem Set volume 15
2305 poke so+5,60: poke so+6,203  :rem ADSR v1
2310 poke so+4,33   :rem sawtooth ON
2315 fq=3600: tm=100 :rem frequency 1
2320 gosub 2365
2325 fq=2800        :rem frequency 2
2330 gosub 2365
2335 for i=1 to 100: next
2340 fq=4800: tm=200 :rem frequency 3
2345 gosub 2365
2350 poke so+4,32   :rem sawtooth + gate off
2355 rem poke so+24,0
2360 return
2365 poke so+0,fqand255: poke so+1,fq/256 :rem low+high bytes freq v1
2370 for i=1 to tm: next
2375 return
#endregion
!------------------------------------------------------------------------------
#region "Barrel hit player"
!-
2400 poke sp,61         :rem Change player to splat
2410 poke so+24,15       :rem Set volume 15
2420 poke so+5,0: poke so+6,240 :rem ADSR v1
2430 poke so+4,33        :rem SAWTOOTH v1
2440 for fq=1024 to 512 step -8
2450    poke so+1,fq/256: poke so+0,fq and 255 :rem high+low freq v1
2460 next
2470 poke so+4,32        :rem SAWTOOTH gate OFF
2480 poke so+24,0        :rem Set volume OFF
2490 return
#endregion
!------------------------------------------------------------------------------
#region "Tap sound"
!-
2500 poke so+24,15
2510 poke so+5,32: poke so+6,0: rem ADSR
2520 poke so+4,129 :rem Bit 7+bit1=noise ON
2530 rem f=4000
2540 poke so+1,fq/256: poke so,fq and 255
2550 poke so+4,128 : rem Sawtooth OFF
2560 return
#endregion
!------------------------------------------------------------------------------
#region "Twang sound"
!-
2600 poke so+5,0: poke so+6,203: rem ADSR
2610 poke so+2,0: poke so+3,2 :rem pulse width
2620 poke so+4,65 :rem Pulse ON
2630 for f=4000 to 5000 step 500
2640   poke so+1,f/256: poke so,f and 255
2650 next
2660 for t=1 to 50:next
2670 poke so+4,64 : rem pulse OFF
2680 return
#endregion
!------------------------------------------------------------------------------
#region "Screen/level over message"
2700 poke 53280,0: poke53281,0
2703 PRINT "{clear}  {reverse on}{yellow}             {reverse off}  {reverse on}{orange}         {reverse off} {reverse on}         {reverse off} {reverse on}   ";
2706 PRINT "{reverse off}  {reverse on}{yellow}             {gray} {reverse off} {reverse on}{orange}         {reverse off} {reverse on}         {reverse off} {reverse on}   ";
2709 PRINT "{reverse off}   {reverse on}{gray}         {yellow}   {gray} "
2712 PRINT "           {reverse on}{yellow}   {gray}  {reverse off} {reverse on}{orange}    {reverse off} {reverse on}         {reverse off} {reverse on}        ";
2715 PRINT "{reverse off}          {reverse on}{yellow}   {gray}  {reverse off}  {reverse on}{orange}    {reverse off} {reverse on}         {reverse off} {reverse on}        ";
2718 PRINT "{reverse off}         {reverse on}{yellow}   {gray}  "
2721 PRINT "        {reverse on}{yellow}   {gray}  {reverse off}  {reverse on}{yellow}  {reverse off}  {reverse on}{orange}       {reverse off} {reverse on}         {reverse off} {reverse on}   ";
2724 PRINT "{reverse off}        {reverse on}{yellow}   {gray} {reverse off}    {reverse on}{yellow} {gray} {reverse off} {reverse on}{orange}       {reverse off} {reverse on}         {reverse off} {reverse on}   ";
2727 PRINT "{reverse off}       {reverse on}{yellow}   {gray}  {reverse off}    {reverse on}{yellow} {gray} "
2730 PRINT "       {reverse on}{yellow}   {gray} {reverse off}     {reverse on}{yellow} {gray} "
2733 PRINT "      {reverse on}{yellow}   {gray}  {reverse off} {reverse on}{yellow}  {reverse off}  {reverse on} {gray} {reverse off}            {reverse on}{yellow} {reverse off} {reverse on}   "
2736 PRINT "      {reverse on}   {gray} {reverse off} {reverse on}{yellow} {gray}  {yellow} {reverse off} {reverse on} {gray} {reverse off}  {reverse on}{yellow}   {reverse off}   {reverse on}   {reverse off}  {reverse on} {gray}    {yellow}  "
2739 PRINT "     {reverse on}    {gray} {reverse off} {reverse on}{yellow} {gray} {reverse off}  {reverse on} {yellow} {gray} {reverse off} {reverse on}{yellow} {gray}   {yellow} {reverse off} {reverse on} {gray}   {yellow} {reverse off} {reverse on} {gray} {reverse off}  {reverse on}{yellow} {gray}  {yellow} "
2742 PRINT "     {reverse on}    {gray} {reverse off} {reverse on}{yellow} {gray} {reverse off}   {reverse on}{yellow} {gray} {reverse off} {reverse on}{yellow} {gray} {reverse off}  {reverse on}{yellow}";
2743 PRINT " {gray} {yellow} {gray} {reverse off}  {reverse on}{yellow} {gray} {yellow} {gray} {reverse off}  {reverse on}{yellow} {gray} {reverse off}  {reverse on} ";
2745 PRINT "{reverse off}     {reverse on}{yellow}    {gray} {yellow}   {reverse off}   {reverse on} {gray} {reverse off} {reverse on}{yellow} {gray} {reverse off}  {reverse on}{yellow} {gray} {yellow} {gray} {reverse off}  {reverse on}{yellow} {gray} {yellow} {gray} {reverse off}   {reverse on}{yellow}  "
2748 PRINT "     {reverse on}    {gray} {reverse off} {reverse on}{yellow} {gray}  {reverse off}  {reverse on}{yellow} {gray} {reverse off} {reverse on}{yellow} {gray} {reverse off}  {reverse on}{yellow} {gray} {yellow} {gray} {reverse off}  {reverse on}{yellow} {gray} {yellow} {gray} {reverse off}    {reverse on} {yellow} "
2751 PRINT "     {reverse on}    {gray} {reverse off} {reverse on}{yellow} {gray} {reverse off}   {reverse on}{yellow} {gray} {reverse off}  {reverse on}{yellow}   {gray}  {reverse off} {reverse on}{yellow}   {gray}  {yellow} {gray} {reverse off}  {reverse on}{yellow} {reverse off}  {reverse on} {gray} ";
2754 PRINT "{reverse off}     {reverse on}{yellow}    {gray} {reverse off} {reverse on}{yellow} {gray} {reverse off}  {reverse on}{yellow}   {reverse off}   {reverse on}{gray}   {reverse off}   {reverse on}   {yellow}   {reverse off}   {reverse on}  {gray}  ";
2757 PRINT "{reverse off}      {reverse on}    {reverse off} {reverse on}{yellow} {gray} {reverse off}   {reverse on}{dark gray}   {reverse off}            {reverse on}{gray}   {reverse off}   {reverse on}  "
2760 PRINT "            {reverse on} "
2763 PRINT "{reverse on}{orange}         {reverse off} {reverse on}         {reverse off} {reverse on}         {reverse off} {reverse on}          ";
2766 PRINT "{reverse on}         {reverse off} {reverse on}         {reverse off} {reverse on}         {reverse off} {reverse on}          ";
2767 print
2769 PRINT "{reverse on}    {reverse off} {reverse on}         {reverse off} {reverse on}         {reverse off} {reverse on}         {reverse off} {reverse on}     ";
2772 PRINT "{reverse on}    {reverse off} {reverse on}         {reverse off} {reverse on}         {reverse off} {reverse on}         {reverse off} {reverse on}    ";
2790 return
#endregion
!------------------------------------------------------------------------------
#region "Screen/level over message"
!-
2800 poke 53280,6: poke 53281,6 :rem blue/blue
2805 if ov=0 then a$=" level complete "
2810 if ov=1 then a$="CC time out! CCC"
2815 if ov=2 then a$="CC crashed! CCCC"
2825 if sc>hs then hs=sc
2830 poke vi+21,0    :rem OFF all sprites
2835 print"{clear}{cyan}{reverse off}{down*7}{right*4}U{C*30}I"
2840 for i=1 to 8
2845   print"{right*4}B{space*30}B"
2850 next
2855 print"{right*4}J{C*30}K"
2860 print"{home}{down*7}{right*12}"a$
2865 print"{yellow}{down*2}{right*12}score"sc
2870 print"{right*12}high score"hs
2875 print"{down}{right*10}level"lv"   players"pl
2880 print"{down*2}{cyan}{right*8} press any key when ready "
2885 for i=1 to 5: get k$: next  :rem flush keyboard buffer?
2890 get k$: if k$="" then 2890
2895 return
#endregion
!------------------------------------------------------------------------------
#region "Game over message"
!-
2900 poke 53280,2: poke 53281,2 :rem red/red
2902 poke vi+21,0 
2905 print"{clear}{yellow}{reverse off}{down*8}{right*4}U{C*30}I"
2910 for i=1 to 8
2915   print"{right*4}B{space*30}B"
2920 next
2925 print"{right*4}J{C*30}K"
2930 print"{home}{down*8}{right*15} game over "
2935 print"{white}{down*2}{right*12}level"lv
2940 print"{down}{right*12}score"sc
2945 print"{right*12}high score"hs
2950 print"{yellow}{down*2}{right*12} play again? (y/n) "
2955 for i=1 to 5: get k$: next
2960 get k$: if k$="" then 2960
2965 if k$="n" or k$="N" then k=0: return
2970 if k$="y" or k$="Y" then k=1: return
2975 goto 2960
#endregion

