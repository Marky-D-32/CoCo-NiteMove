        ORG $2134
        SETDP 0
BEGIN   LBSR INSTR
        
        ;************************
        ;* Setup Semi Graphics 24
        ;************************
SEMI24  LDX #$600                       ;Clear Screen
        LDA #$80
LOOP    STA ,X+
        CMPX #$1E00
        BCS LOOP
        LDA #$0D                        ;Semi Graphics
        STA $FF22
        STA $FFC0
        STA $FFC3
        STA $FFC5
        STA $FFC7
        
        ;**********************
        ; ONSCREEN INSTRUCTIONS
        ;**********************
CONTRL  LDX #$600                       ;Clear screen
        LDA #$80
LOOP1   STA ,X+
        CMPX #$1E00
        BNE LOOP1
        LDX #$0671                      ;Position on screen for instructions to be written
        STX $88
        CLRB                            ;Reset number of characters drawn
        LEAY PRINT,PCR                  ;Point to Instructions
LOOP2   LDA ,Y+                         ;Get next character of instruction 
        ANDA #$BF
        STA ,X+                         ;Write to screen
        STA $1F,X
        STA $3F,X
        STA $5F,X
        STA $7F,X
        STA $9F,X
        STA $BF,X
        CMPX #6269                      ;Finished writing instructions? (HEX $187D)
        BEQ SCORE                       ;Yes - write scrore text
        INCB                            ;No - incease number of characters drawn       
        CMPB #13                        ;Finished writing all characters for line
        BNE LOOP2                       ;No - write next character
LINE    CLRB                            ;Yes - reset character count for line
        LEAX 755,X                      ;Reposition point of screen for character to be drawn
        BNE LOOP2                       ;Write next line of characters
PRINT   FCB /CONTROLS:-   /
        FCB /CURSOR KEYS  /
        FCB /FOR MOVEMENT./
        FCB /PRESS ENTER  /
        FCB /TO CHANGE.   /
        FCB /"R" RESTARTS /
        FCB /"Q" QUITS    /
        
        ;*********************
        ; SCORE INITIALIZATION
        ;*********************
SCORE   LDX #6244                       ;Position on screen for Score to be written
        STX $88                         
        CLRB                            ;Reset number of characters drawn
        LEAY SCORE1,PCR                 ;Point to Score text
LOOP3   LDA ,Y+                         ;Get next character
        ANDA #$BF
        STA ,X+                         ;Write to screen
        STA $1F,X
        STA $3F,X
        STA $5F,X
        STA $7F,X
        STA $9F,X
        STA $BF,X
        INCB                            ;Increase number of characters drawn
        CMPB #8                         ;Finished writing all characters?
        BNE LOOP3                       ;No - continue writing score text
        LDD #$3030                      ;Write "00" 
        STD $1F00                       ;To screen score position
        BRA BOARD                       
SCORE1  FCB /MOVES 00/
        
        ;****************************
        ; SET UP DISPLAY - draw board
        ;****************************
BOARD   LDX #$0660                      ;Draw position on screen
        LDD #$0000                      ;column and row draw count
        LDY #$CFCF                      ;White Square
        LDU #$AFAF                      ;Blue Square
ROWS    STY ,X++                        ;Draw white square pixel
        STU ,X++                        ;Draw Blue square pixel
        INCA
        CMPA #4                         ;Have we drawn 8 columns?
        BNE ROWS                        ;No - draw next two columns
        LEAX 16,X                       ;Yes - go down a row in cell
        CLRA                            ;Reset column count
        INCB                            ;Increase row count
        CMPB #16                        ;Have we drawn all rows in cell?
        BNE ROWS                        ;No 
        EXG Y,U                         ;Yes - switch cell colours
        CLRB                            ;reset cell row count
        CMPX #$1660                     ;Finished all cells?
        BNE ROWS                        ;No
        
        ;*************************
        ; RANDOMISE START POSITION
        ;*************************
        LDA $1F80
        CMPA #50                        ;Level "2" selected
        BEQ START2
        LDX #$0E64                      ;Level 1 - start position (change to 0660 for top level position)
        BNE START1
START2  JSR $BF1F                       ;RANDOM NUMBER: Generates an 8 bit random number and puts it in location 278
        LDB 278                         ;Produce one of: 60,62,64,66,68,6A,6C,6E
        ANDB #$07
        ASLB
        ADDB #$60
        PSHS B
        JSR $BF1F                       ;RANDOM NUMBER: Generates an 8 bit random number and puts it in location 278
        LDA 278                         ;Produce one of: 06,08,0A,0C,0E,10,12,14
        ANDA #$07
        ASLA
        ADDA #$06
        PULS B
        TFR D,X
        LDY ,X                          ;Get value in current cursor position
        CMPY #$AFAF                     ;Is it a blue square?
START1  LBEQ FSTCHK                     ;Yes - set cursor to blue checked
        LBNE NXTCHK                     ;No - set cursor to Buff checked
        
        ;*********************************************************
        ; MAIN CONTOL ROUTINE - Check if any valid moved available
        ;*********************************************************
WAIT    LDU $1F30                       ;Get cursor psotion
        LEAU -1538,U                    ;Point to cell up 2, left 1  
        BSR CHECK
        LEAU 4,U                        ;Point to cell up 2, right 1
        BSR CHECK
        LEAU 506,U                      ;Point to cell up 1, left 2
        BSR CHECK
        LEAU 8,U                        ;point to cell up 1, right 2
        BSR CHECK
        LEAU 1016,U                     ;point to cell down 1, left 2
        BSR CHECK
        LEAU 8,U                        ;point to cell down 1, right 2
        BSR CHECK
        LEAU 506,U                      ;point to cell down 2, left 1
        BSR CHECK
        LEAU 4,U                        ;point to cell down 2, right 1
        BSR CHECK
        LBSR NOMOVE                     ;No moves available - finish
CHECK   LDD ,U                          ;Get calue from cell to check
        CMPA #$AF                       ;Is a blue square ?
        LBEQ CYAN                       ;Change it to Cyan
        CMPA #$CF                       ;Is a buff square ?
        LBEQ ORANGE                     ;Change it orange
        PULS PC                         
        
        ;*******************
        ;Check for Key press
        ;*******************
KEYS    JSR $A1C1                       ;POLCAT:Keyboard input:put into Register A
        BEQ KEYS
        CMPA #81                        ;'Q'
        LBEQ QUIT
        CMPA #82                        ;'R'
        LBEQ BEGIN
        CMPA #$5E                       ;Up Arrow
        BNE DOWN                        ;Not pressed - check for down arrow
        LDD -544,X                      ;Check if top of board                      
        CMPA #$80
        BEQ KEYS                        ;Yes - repeat key check
        LBSR CHEK                       ;move allowed - change colour of cell moving FROM
        LEAX -1024,X                    ;Get position of new cell
        LDD ,X                          ;Get new cell values
        LBNE CHEK2                      ;Change colour of cell moving TO
DOWN    CMPA #$0A                       ;Down arrow
        BNE LEFT                        ;Not pressed check for left arrow
        LDD 32,X                        ;Check if bottom of board
        CMPA #$80
        BEQ KEYS                        ;Yes - repeat key check
        LBSR CHEK                       ;move allowed - change colour of cell moving FROM
        LDD ,X                          ;Get new cell values
        LBSR CHEK2                      ;Change colour of cell moving TO
LEFT    CMPA #$08                       ;Left Arrow
        BNE RIGHT                       ;Not pressed check for right arrow
        LDD -33,X                       ;check if move beyond left of board
        CMPA #$80
        BEQ KEYS                        ;Yes - repeat key check 
        LBSR CHEK                       ;move allowed - change colour of cell moving FROM
        LEAX -514,X                     ;Get position of new cell
        LDD ,X                          ;Get new cell values
        LBSR CHEK2                      ;Change colour of cell moving TO
RIGHT   CMPA #$09                       ;Right Arrow
        BNE ENTER                       ;Not pressed - check for enter
        LDD -30,X                       ;CHeck if move beyond right of board
        CMPA #$80
        BEQ KEYS                        ;Yes - repeat key check
        LBSR CHEK                       ;move allowed - change colour of cell moving FROM
        LEAX -510,X                     ;Get position of new cell
        LDD ,X                          ;Get new cell values
        LBSR CHEK2                      ;Change colour of cell moving TO
ENTER   CMPA #$0D                       ;Enter
        BNE KEYS                        ;Not pressed - repeat key check
        LDU $1F20                       ;Get original cursor position - where last cell was set
        LEAU -1026,U                    ;Point back to where we want to go
        STU $1F20                       ;Store value
        CMPX $1F20                      ;Compare with new cursor psotion
        LBEQ CANGO                      ;They are the same - move allowed
        LEAU 4,U                        ;point to cell up 2, right 1
        STU $1F20
        CMPX $1F20
        LBEQ CANGO
        LEAU 506,U                      ;point to cell up 1, left 2
        STU $1F20
        CMPX $1F20
        LBEQ CANGO
        LEAU 8,U                        ;point to call up 1, right 2
        STU $1F20
        CMPX $1F20
        LBEQ CANGO
        LEAU 1016,U                     ;point to cell down 1, left 2
        STU $1F20
        CMPX $1F20
        LBEQ CANGO
        LEAU 8,U                        ;point to cell down 1, right 2
        STU $1F20
        CMPX $1F20
        LBEQ CANGO
        LEAU 506,U                      ;point to cell down 2, left 1
        STU $1F20
        CMPX $1F20
        LBEQ CANGO
        LEAU 4,U                        ;point to cell down 2, right 1
        STU $1F20
        CMPX $1F20
        LBEQ CANGO
        LEAU -1026,U                    ;Can't move - point back to starting point
        STU $1F20                       ;And save
NOGO    STX $1F60                       ;position of cell we were tring to move to
        LDX #$1B66                      ;Position to display you cant go there text
        STX $88                         ;Move cursor to required text position
        CLRB
        LEAY CANT,PCR                   ;write text
LOOP4   LDA ,Y+
        ANDA #$BF
        STA ,X+
        STA $1F,X
        STA $3F,X
        STA $5F,X
        STA $7F,X
        STA $9F,X
        STA $BF,X
        INCB
        CMPB #19
        BNE LOOP4
        LDY #$FFFF                      ;delay so text can be read
DELAY   LEAY -1,Y
        BNE DELAY
        LDX $1F60                       ;Get position of cell we were trying to move to
        LBSR CHEK                       ;Remove checked pattern from cell we were trying to move to
        LDA #255
        LDX #200
        LBSR SOUND
        LDA #125
        LDX #100
        LBSR SOUND
        LDX #$1B66                      ;Position of displayed you cant go there text
        LDA #$80                        ;Clear text
LOOP5   STA ,X+
        CMPX #$1E00
        BNE LOOP5
        LDX $1F30                       ;Get original cell position
        STX $1F20                       ;And save
        LEAX -512,X
        LDD ,X
        LBNE CHEK2                      ;Draw checked (ie cursor) on original cell position
CANGO   LEAX -512,X                     ;Move to top level corner of cell
        LDD ,X                          ;Get value in current cell position
        CMPD #$AAAA                     ;Blue Checked ?
        BEQ FSTCHK                      ;Colour in cell with Orange
        CMPD #$CACA                     ;Buff Checked ?
        BEQ NXTCHK                      ;Colour in cell with Cyan
        LEAX 512,X
        LBNE NOGO                       ;Cell has already been set - cannot move to it.
FSTCHK  LDY #$FFFF                      ;Set orange
        LBSR MOVE                       ;Draw cell
        LBSR UNITS                      ;Increase score
        PSHS X
        LDA #187                        ;Play sound
        LDX #85
        LBSR SOUND
        PULS X
        STX $1F20                       ;Store new cursor position
        STX $1F30                       ;Store new cursor position
        LEAX -512,X
        LBNE WAIT                       ;Goto Main control routine
NXTCHK  LDY #$DFDF                      ;Set Cyan 
        LBSR MOVE                       ;Draw Cell
        LBSR UNITS                      ;Increase score
        PSHS X
        LDA #187                        ;Play sound
        LDX #85
        LBSR SOUND
        PULS X
        STX $1F20                       ;Store new cursor position
        STX $1F30                       ;Store new cursor position
        LEAX -512,X
        LBNE WAIT                       ;Goto Main control routine
SCRCHK  LDD $1F00                       ;$1F00 = score (written on screen)
        CMPA #54                        ;Check for 6
        LBNE KEYS                       ;No - check key press \ cursor move
        CMPB #52                        ;Check for 4
        LBEQ ENDING                     ;Yes - no more moves available
        LBNE KEYS                       ;Check for key press \ cursor move
CANT    FCB /YOU CAN T GO THER/
        FCB /E!/

        ;************************************************
        ;COLOUR CHANGE of Cell that cursor is moving from
        ;************************************************
CHEK    LEAX -512,X                     
        LDD ,X                          ;Get colour of current cell
        CMPA #$DF                       ;All Cynan
        BNE FF
        LDY #$DFDF                      ;Set to Cyan
        BRA MOVE                        ;Draw
FF      CMPA #$FF                       ;All Orange
        BNE AA
        LDY #$FFFF                      ;Set to ALL Orange
        BRA MOVE                        ;Draw
AA      CMPA #$AA                       ;Check for Blue \ Black
        BNE CA
        LDY #$AFAF                      ;Set to ALL blue
        BRA MOVE                        ;Draw
CA      CMPA #$CA                       ;Check for Buff \Black
        BNE DA
        LDY #$CFCF                      ;Set to ALL Buff
        BRA MOVE                        ;Draw
DA      CMPA #$DA                       ;Check for Cyan \ Black
        BNE FA
        LDY #$DFDF                      ;Set to ALL Cyan
        BRA MOVE                        ;Draw
FA      CMPA #$FA                       ;Check for Orange \ Black
        LDY #$FFFF                      ;Set to All Orange

MOVE    CLRB                            ;Draw the cell
LOOP6   STY ,X
        LEAX 32,X
        INCB
        CMPB #16
        BNE LOOP6
        PULS PC

        ;************************************************************************
        ; CURSOR COLOUR CONTROLS - Change colour of Cell that cursor is moving to
        ;************************************************************************
CHEK2   CMPA #$AF                       
        BEQ BLUE
        CMPA #$CF
        BEQ BUFF
        CMPA #$DF
        BEQ CYAN
        CMPA #$FF
        BEQ ORANGE
BLUE    LDY #$AAAA                      ;Blue \ Black
        LDU #$A5A5                      ;Black \ Blue
        BRA MOVE2
BUFF    LDY #$CACA                      ;Buff \ Black
        LDU #$C5C5                      ;Black \ Buff
        BRA MOVE2
CYAN    LDY #$DADA                      ;Cyan \ Black
        LDU #$D5D5                      ;Black \ Cyan
        BRA MOVE2
ORANGE  LDY #$FAFA                      ;Orange \ Black
        LDU #$F5F5                      ;Black \ Orange
        BRA MOVE2
MOVE2   CLRA
        CLRB
LOOP7   STY ,X                          ;Draw game checked cursor on screen
        LEAX 32,X                       
        INCB
        CMPB #4
        BNE LOOP7
        INCA
        CMPA #4
        BNE SWOP
        PSHS X
        LDA #31
        LDX #69
        LBSR SOUND                      ;Make a sound
        PULS X
        LBRA SCRCHK                     ;Exit - goto score check
SWOP    EXG U,Y                         ;swap colour\black to black\colour or vice versa
        CLRB
        BRA LOOP7                       ;Repeat
        
        ;***************************************
        ; COUNTING ROUTINE - INCREASE SCORE BY 1
        ;***************************************
UNITS   PSHS A,B,X
        LDX #6218                       ;Score position on screen
COUNT   LDD $1F00                       ;Get current score
        CMPB #57                        ;unit = 9
        BEQ TENS                        ;Yes
        INCB                            ;increase unit
LOOP8   STD ,X                          ;Write score to screen
        LEAX 32,X                       ;Next line on screen
        CMPX #6456                      ;Finished drawing?
        BLO LOOP8                       ;No - repeat
        STD $1F00                       ;Write last line of score to screen
        PULS X,A,B,PC                   ;Return
TENS    INCA                            ;Increase '10'
        LDB #47                         ;reset Unit value
        STD $1F00                       ;Write to screen
        BRA COUNT
        
        ;***************
        ; SOUND ROUTINES
        ;***************
SOUND   PSHS A
        LDA $FF01
        ANDA #247
        STA $FF01
        LDA $FF03
        ANDA #247
        STA $FF03
        LDA $FF23
        ORA #8
        STA $FF23
        ORCC #$50
        PULS A
        PSHS X
        LDB #252
SD1     STB $FF20
SD2     LEAX -1,X
        BNE SD2
        LDX ,S
        CLR $FF20
SD3     LEAX -1,X
        BNE SD3
        LDX ,S
        DECA
        BNE SD1
        ANDCC #$AF
        PULS X,PC

        ;***********************
        ;No more moves available
        ;***********************
NOMOVE  LDA #131                        ;Make Sound
        LDX #102
        LBSR SOUND
        LDA #200
        LDX #225
        LBSR SOUND
FINISH  LDX #$1B66                      ;Display text position
        STX $88                         ;Move cursor to required text position
        CLRB
        LEAY TYPE,PCR                   ;Write text to screen
LOOP9   LDA ,Y+
        ANDA #$BF
        STA ,X+
        STA $1F,X
        STA $3F,X
        STA $5F,X
        STA $7F,X
        STA $9F,X
        STA $BF,X
        INCB
        CMPB #19
        BCS LOOP9
        LDX $1F20
        LEAX -512,X
        LDD ,X
        LBRA CHEK2
TYPE    FCB /SORRY NO MOVES/
        FCB / LEFT/
        
        ;************
        ;ANOTHER GAME
        ;************
ENDING  LDX #$1B60                      ;Display text position
        STX $88                         ;Move cursor to required text position
        CLRB
        LEAY AGAIN,PCR                  ;Point to text
LOOP10  LDA ,Y+                         ;Display text
        ANDA #$BF
        STA ,X+
        STA $1F,X
        STA $3F,X
        STA $5F,X
        STA $7F,X
        STA $9F,X
        STA $BF,X
        INCB
        CMPB #31
        BCS LOOP10
LOOP11  JSR $A1C1                       ;POLCAT:Keyboard input:put into Register A
        CMPA #$59                       ;'Y'
        LBEQ BEGIN                      ;Start again
        CMPA #$4E                       ;'Q'
        LBEQ QUIT                       ;Exit game
        BNE LOOP11
AGAIN   FCB /WELL DONE ANOTHER/
        FCB / GAME (Y OR N)/
        
        ;*********************
        ; INITIAL TEXT DISPLAY
        ;*********************
INSTR   JSR $A928                       ;CLEAR SCREEN: clears screen to space and 'homes' cursor
        LDX #$04A2                      ;Display text position
        STX $88                         ;Move cursor to required text position
        LEAX RULES,PCR                  ;Point to riles text
        JSR $B99C                       ;Write Rules
        JSR $B99C              	        ;Write Rules
	LDX #$400		        ;Invert screen green/black to black/green
LOOP12  LDA ,X
        EORA #$40
        STA ,X+
        CMPX #$5FF
        BLS LOOP12
        LDX #$400		        ;Draw Top Blue scrolling border
        LDA #$AF
LOOP13  STA ,X+
        CMPX #$41E
        BLS LOOP13
        LDX #$5A2                       ;Draw bottom Yellow text border
        LDA #156
LOOP14  STA ,X+
        CMPX #$5BD
        BLS LOOP14
        LDA #152
        STA $5BE
        LDX #$41F                       ;Draw right White Scolling Border
        LDA #$CF
LOOP15  STA ,X
        LEAX 32,X
        CMPX #$5DF
        BLS LOOP15
        LDA #146
        STA $43E
        LDX #$45E                       ;Draw right Yellow text border 
        LDA #154
LOOP16  STA ,X
        LEAX 32,X
        CMPX #$59E
        BLS LOOP16
        LDX #$5E1                       ;Draw Bottom Cyan Scolling border
        LDA #$DF
LOOP17  STA ,X+
        CMPX #$600
        BLS LOOP17
        LDA #145
        STA $421
        LDX #$422                       ;Draw top yellow text border
        LDA #147
LOOP18  STA ,X+
        CMPX #$43D
        BLS LOOP18
        LDX #$420                       ;Draw Left Orange scrolling border
        LDA #$FF
LOOP19  STA ,X
        LEAX 32,X
        CMPX #$5E0
        BLS LOOP19
        LDA #148
        STA $5A1
        LDX #$441                       ;Draw Left yellow text border
        LDA #149
LOOP20  STA ,X
        LEAX 32,X
        CMPX #$581
        BLS LOOP20

        ;**********************
        ;Check for key presses
        ;**********************
LOOP21  JSR $A1C1                       ;POLCAT:Keyboard input:put into Register A
        CMPA #49                        ;Check for "1"
        LBEQ LEVEL
        CMPA #50                        ;check for "2"
        LBEQ LEVEL
        CMPA #32                        ;Check for Space
        LBEQ CKLEVL             
        
        ;*************************************************
        ;Update screen display while waiting for key press
        ;*************************************************
        LDA #1
LOOP22  PSHS A
        LDB #2
LOOP23  PSHS B
        LDX #$400                       ;Scroll top line left
        LDY #$401
        LDA #31
LOOP24  LDB ,Y+
        STB ,X+
        DECA
        BNE LOOP24
        PULS B
        DECB
        BNE LOOP23
        LDX #$41F                       ;Scroll right line Up
        LDY #$43F
        LDA #$15
LOOP25  LDB ,Y
        STB ,X
        LEAY 32,Y
        LEAX 32,X
        DECA
        BNE LOOP25
        LDB #2
LOOP26  LDX #$600                       ;Scroll bottom line right
        LDY #$5FF
        LDA #31
        PSHS B
LOOP27  LDB ,-Y
        STB ,-X
        DECA
        BNE LOOP27
        PULS B
        DECB
        BNE LOOP26
        LDX #$5E0                       ;Scroll left line down
        LDY #$5C0
        LDA #15
LOOP28  LDB ,Y
        STB ,X
        LEAY -32,Y
        LEAX -32,X
        DECA
        BNE LOOP28
        PULS A
        DECA
        BNE LOOP22
        LDA #28                         ;Scroll text left
        LDX #$5C1
        LDY #$5C2
        LDU ,X
LOOP29  LDB ,Y+
        STB ,X+
        DECA
        BNE LOOP29
        STU $5DD
        LDY #12000                      ;Slow things down
SLOW    LEAY -1,Y
        BNE SLOW
        LBRA LOOP21
        
        ;*******************        
        ; SCROLL SCREEN LEFT
        ;*******************
SCROLL  CLR $1F70
        LDB #32
LOOP30  LDX #$400
        LDA #$80
LOOP31  STA ,X
        LEAX 32,X
        CMPX #$601
        BLS LOOP31
        LDX #$400
        LDY #$401
LOOP32  LDA ,Y+
        STA ,X+
        CMPX #$600
        BLS LOOP32
        PSHS Y
        LDY #$1500
LOOP33  LEAY -1,Y
        BNE LOOP33
        PSHS B
        LDA #10
        LDX #36
        LBSR SOUND
        PULS B
        DECB
        BNE LOOP30
        LBRA SEMI24
        
        ;*****************
        ;START LEVEL CHECK
        ;*****************
LEVEL   STA $1F70                       ;A will be 49 or 50
        STA $1F80
        LDX #$5C1                       
        STX $88
        LEAX SPCBAR,PCR                 ;Replace "enter level" text with "press spacebar"
        JSR $B99C                       ;Write text to screen
        LDA #200
        LDX #25
        LBSR SOUND
        LBRA LOOP21                     ;Scan keyboard
SPCBAR  FCB /       PRESS SPAC/
        FCB /EBAR TO START/,0

        ;**********************************
        ;Check game level has been selected
        ;**********************************
CKLEVL  LDA $1F70                       ;Key game level selected
        CMPA #49
        LBEQ SCROLL                     ;If 1 has previously been pressed, scroll and start game
        CMPA #50
        LBEQ SCROLL                     ;If 2 has previously been pressed, scroll and start game
        LBNE LOOP21                     ;No level selected - check for key press
RULES   FCB /  CHANGE THE B/
        FCB /OARD FROM BLUE  /
        FCB /    & WHITE TO O/
        FCB /RANGE AND CYAN  /
        FCB /                /
        FCB /                /
        FCB /    USING THE CU/
        FCB /RSOR KEYS MOVE  /
        FCB /    AS THE KNIGH/
        FCB /T CAN IN CHESS  /
        FCB /                /
        FCB /                /
        FCB /                /
        FCB /                /
        FCB /                /
        FCB /                /
        FCB /                /
        FCB /                /
        FCB /    ENTER SKILL /
        FCB /LEVEL 1 OR 2 ?/,0

        ;***********************
        ; FINISH RETURN TO BASIC
        ;***********************
QUIT    JSR $A027                       ; RESET:resets whole works, as if reset button has been pressed

