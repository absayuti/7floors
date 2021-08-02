;===============================================================================
; Project   : 7 Floors a.k.a JumpMan
; Target    : Commodore 64
; Comments  : Machine Language (ML) Code to move the barrels
; Author    : ABSHMS June 2021
;===============================================================================
;
; This ML code is designed/setup like a Finite State Machine (FSM).
;
; Each call to this ML will execute the code once only.
;
; It will check the flags in the control block to determine which
; "state" a barrel is in and perfomr specific action accordingly.
;
; Each barrel has its own STATE and DIRECTION of it rolling motion.
; Valid states are:
;
;       0 = OFF       Barrel is not visible and not moving
;
;       1 = ROLLING   Barrel is rolling to LEFT (0) or RIGHT (1)
;
;       2+ = DROP      Barrel is dropping through a gap in a floor onto the
;                       floor below.
;
; A barrel starts rolling from the GOAL location at top right corner of the
; screen. DIRECTION of roll is to the LEFT obviously.A barrel will start
; ROLLING one after another according to INTERVAL specified by the BASIC MAIN
; program. This value is passed through a CONTROL BLOCK at 820-8xx.
;
; STATE and DIRECTION values are stored in CONTROL BLOCK too.
;
; If a barrel rolls beyond the left and right margin of the screen, it will
; sort of "bounce off the wall" i.e. changes its rolling DIRECTION.
;
; While in ROLLING state, either: (options)
;
;       (1) Check if it is on top of a gap in the floor. If it is on top of
;           a gap, it will change its STATE to DROP.
;  Or...
;       (2) BASIC main program checks if a barrel is on top of a gap in the
;           floor. If it is so, BASIC will set the correct STATE value
;           in the control block.
;
;       * Looks like option 2 is easier
;
; In DROP state, a barrel will do a drop motion to the floor below. While
; dropping, it uses its STATE value to indicate the following conditions:
;
;               2 = to start dropping
;               3 = dropped once (8 pixels)
;               4 = dropped 2x (16 pixels)
;               5 = dropped 3x (24 pixels)
;
; 24 pixels is equivalent to 1 floor dropped. Then it changes its STATE back
; to ROLLING with a random DIRECTION.
;
; If it drops to the lowest floor a barrel will change to OFF state.
;
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
; Main program
;------------------------------------------------------------------------------
*=$C000                         ; sys 49152


;-------------------------------------------------------------------------------
; Rolls or drop barrels if need to

Main
            LDA cb_reset        ; Check if we need to RESET all barrels
            BNE @skip
            JSR Resetbarrels
@skip
            JSR Checkhitplayer
            JSR Checkfloorgap
            JSR Checklaunchflag

            LDA #1              ; X holds the sprite number, ignore sprite 0
            TAX                 ; --> 0,1,2,3,4,5,6,7
            LDA #2              ; Y holds pointer to sprite x/y-coord
            TAY                 ; --> 0,2,4,6,8,10,12,14
Checkstate
            TXA
            ;STA screen+2            
            LDA br_state,X      ; Check state: 0=OFF 1=ROLLING 2=DROP
            BEQ Offbarrel       ; IF STATE=0 then make sure it is off
            CMP #1              ; ELSE IF STATE=1 then
            BEQ Checkdir        ;       Roll the barrel (check its direction)
            JSR Dropbarrel      ; ELSE Drop the barrel
            JMP Changeimage
Offbarrel
            LDA #0              ; Hide the barrel
            STA br_xh,X
            STA br_x,X
            STA br_y,X
            JSR Setcoordinate
            JMP Nextbarrel
Checkdir
            LDA br_dir,X        ; Get its rolling direction
            BEQ @toleft         
@toright
            JSR Rollright       
            JMP Changeimage     
@toleft
            JSR Rollleft        

Changeimage
            LDA sp_image,X      ; Cycle through barrel image
            CMP #barrel3        ; Last image?
            BEQ @reset          
            INC sp_image,X      
            JMP Nextbarrel      
@reset
            LDA #barrel1        
            STA sp_image,X      

Nextbarrel
            INX                 ; Point to next barrel
            INY                 ; Increase x/y-coord.reg. pointer by 2
            INY
            CPX #8              
            BNE Checkstate

            RTS


;-------------------------------------------------------------------------------
; Reset/off all barrels

Resetbarrels
            LDA #1
            STA cb_reset        ; OFF the RESET flag
            TAX
            LDA #0
@forloop
            STA br_state,X      ; OFF all barrels
            INX
            CPX #8
            BNE @forloop
            RTS

;-------------------------------------------------------------------------------
; Check if barrel hit player --> set flag

Checkhitplayer
            LDA collis1         ; Save sprite-sprite collision flags
            AND #1
            ;STA screen+10
            STA cb_hit
            RTS


;-------------------------------------------------------------------------------
; Check LAUNCH flag if we need to launch a new barrel       

Checklaunchflag
            LDA cb_launch
            BNE Pushbarrel
            ;STA screen+10 
            RTS
Pushbarrel
            LDA #0              ; Switch OFF flag
            STA cb_launch
            LDA #1              ; Check which barrel is OFF
            TAX
@forloop
            LDA br_state,X
            BEQ @pushit
            CPX cb_maxnum          ; Exceed max number of barrels?
            BCS @return         ; (specified by BASIC via cobloc)
            INX
            JMP @forloop
@pushit
            LDA #1              ; Set the barrel's state as ROLLING
            STA br_state,X
            LDA #1              ; Place it at starting point coord
            STA br_xh,X
            LDA #xstart
            STA br_x,X
            LDA #ystart
            STA br_y,X
            LDA #barrel1        ; Set its image vector
            STA sp_image,X
@return
            RTS


;-------------------------------------------------------------------------------
; Check if barrel is on touching the floor (on collision with background) 
;                  __          __
;                 /''\       /   \
;         _______ \__/ ______\__/_____
;          floor| gap |     floor
; 
; If yes, then set state=DROP 
;

Checkfloorgap
            LDA collis2         ; Save sprite-background collision flags
            STA whichbit
            LDA #1
            TAX
@forloop
            LDA br_state,X      ; Check its STATE
            ;STA screen+10
            CMP #1              
            BNE @next
@checkgap                       ; IF in ROLLING state...
            LDA lookupset,X     ; ..get the corresponding bit     
            AND whichbit        
            BNE @next           ; IF touching floor --> ignore it

            LDA #2              ; ELSE, set STATE = DROP
            STA br_state,X
@next 
            INX
            CPX #8
            BNE @forloop

            RTS

;-------------------------------------------------------------------------------
; Roll to the right X pixels

Rollright
            CLC                 ; Do 2-byte addition by xsize
            LDA br_x,X          
            ADC #xsize          
            STA br_x,X          
            LDA br_xh,X         
            ADC #0              
            STA br_xh,X         

@checkxcoord
            ;STA 1031            ; High byte already in A
            CMP #0              
            BNE @morethan255    
            JSR ClearMSB        ; If x<256 then clear MSB
            JMP @setcoord       

@morethan255
            JSR SetMSB          ; ELSE set MSB

            LDA br_x,X          ; Bump into right wall?
            CMP #xmax           
            BCC @setcoord       ; x<xmax, skip this

            LDA #xmax           ; Bumped ..
            STA br_x,X          ;  --> Stop rolling
            LDA #0              ;  --> change direction
            STA br_dir,X        

@setcoord
            JSR Setcoordinate   

            RTS

;-------------------------------------------------------------------------------
; Roll to the left X pixels

Rollleft
            SEC                 ; Do 2-byte subtraction by xsize
            LDA br_x,X          
            SBC #xsize          
            STA br_x,X          
            LDA br_xh,X         
            SBC #0              
            STA br_xh,X         

@checkxcoord
            ;STA 1031            ; High byte already in A
            CMP #0              
            BEQ @lessthan256    
            JSR SetMSB          ; If x>255 then set MSB
            JMP @setcoord       

@lessthan256
            JSR ClearMSB        ; ELSE clear MSB

            LDA br_x,X          ; Bump into left wall?
            CMP #xmin           
            BCS @setcoord       ; x>xmin, skip this

            LDA #xmin           ; Bumped ..
            STA br_x,X          ;  --> stop rolling
            LDA #1              ;  --> change direction
            STA br_dir,X        
@setcoord
            JSR Setcoordinate   

            RTS


;-------------------------------------------------------------------------------
; Drop the barrel

Dropbarrel
            LDA br_y,X          ; Drop 1 character (8 pixels)
            CLC
            ADC #ysize          
            STA br_y,X

            ;LDA br_state,X      ; IF we at 1st stage of drop
            ;CMP #2
            ;BNE @nextstage
            ;LDA br_dir,X        ; THEN place slight to left/right
            ;BEQ @slightleft     ; ...based of DIRECTION of rolling
@slightright
            ;LDA br_x,X
            ;CLC
            ;ADC #xsize
            ;STA br_x,X
            ;JMP @nextstage
@slightleft
            ;LDA br_x,X
            ;SBC #xsize
            ;STA br_x,X
@nextstage
            INC br_state,X      ; Count how many drops already done
            LDA br_state,X      
            ;STA screen+4
            CMP #5              ; If we reached the floor below
            BCS @set2rolling    ; .. then change STATE=ROLLING
            LDA br_y,X          ; IF we reached ground floor
            CMP #floor0
            BCS @set2off
            JMP @setcoord 
@set2rolling
            LDA #1              ; change state to ROLLING
            STA br_state,X      
            LDA $DC04           ; Timer A Low-Byte
            AND #1              ; Check LSB
            STA br_dir,X
            JMP @setcoord
@set2off
            LDA #0              ; change state to OFF
            STA br_state,X      
@setcoord
            JSR Setcoordinate   
            RTS


;-------------------------------------------------------------------------------
; Set sprite's X/Y coordinate

Setcoordinate

@setxcoord
            LDA br_x,X          
            STA sp_pos,Y        ; Set sprite's X coord register        

@setycoord
            LDA br_y,X          ; Get Y coord
            STA sp_pos+1,Y      ; Set Y coord register       

            RTS

;-------------------------------------------------------------------------------
; Subroutine to set MSB for sprite X coord > 255

SetMSB
            LDA lookupset,X     
            STA whichbit        
            LDA MSBreg          
            ORA whichbit        
            STA MSBreg          
            RTS

;-------------------------------------------------------------------------------
; Subroutine to clear MSB for sprite X coord <= 255

ClearMSB
            LDA lookupclr,X     
            STA whichbit        
            LDA MSBreg          
            AND whichbit        
            STA MSBreg          
            RTS

;------------------------------------------------------------------------------

Delay
            LDA #$00            
            STA dcount          ; high byte
@delayloop
            ADC #01             
            BNE @delayloop      
            CLC
            INC dcount          
            BNE @delayloop      
            CLC

            RTS


;------------------------------------------------------------------------------
;
;*** Control block
cobloc      = 820               ; Control block at 820-827
cb_launch   = cobloc            ; Flag = launch a barrel
cb_maxnum   = cobloc+1          ; Number = max number of barrels + 1
                                ; 5 = max 4 barrels. 8 = max 7 barrels
cb_hit      = cobloc+2          ; Flag = a barrel is crashed with player
cb_reset    = cobloc+3          ; Flag: 0 = Zero barrels

;*** variables
; These vars are set up like arrays. Each line reserves a space for 8 bytes
; Bytes #0 are not used because it points to sprite #0 while the barrels are
; sprites #1 - #7
;
br_state    byte 0,0,0,0,0,0,0,0 ; STATES of BARRELS. Byte 0 is not used
br_dir      byte 0,0,0,0,0,0,0,0 ; DIRECTIONs of rolling
br_xh       byte 0,0,0,0,0,0,0,0 ; High bytes of X coords
br_x        byte 0,0,0,0,0,0,0,0 ; LOW bytes of X coords
br_y        byte 0,0,0,0,0,0,0,0 ; Y coords
whichbit    byte 0               ; Used for masking the MSB of X-coords
count       byte 0               ; Some counters
count2      byte 0
dcount      byte 0

;*** lookup table for x-coord MSB -- the easier way???
lookupset   byte 1,2,4,8,16,32,64,128
lookupclr   byte %11111110,%11111101,%11111011,%11110111
            byte %11101111,%11011111,%10111111,%01111111

;*** Constants
xmin        = 24                ; Min & max allowable values for a barrel position
xmax        = 72                ; 320 = 256+64 = screen X max visible
ymin        = 50
ymax        = 229
xsize       = 8                 ; How much barrel moves in X and Y each time
ysize       = 8
floor0      = 226               ; Y-coord of the ground floor
xstart      = 72                ; Starting point coordinate
ystart      = 68                ; +1 so that the barrel touches the floor

;*** Vectors
screen      = $C800             ; Text screen is at 51200
sp_image    = $CBF8             ; Sprite shape pointers = 51200+1016
barrel1     = 58                ; Images for barrel
barrel2     = 59                ; 
barrel3     = 60                ; 

;*** Registers
vic         = $D000             ; 53248
sp_pos      = vic               ; VIC registers for sprite positioning
MSBreg      = vic+16            ; Extended X position (x>255)
sprites     = vic+21            ; Active (ON) sprites
collis1     = vic+30            ; Sprite to sprite collision flags
collis2     = vic+31            ; Sprite to background collision flags
spcolor     = vic+39

; ------------------------------ end ------------------------------------------
