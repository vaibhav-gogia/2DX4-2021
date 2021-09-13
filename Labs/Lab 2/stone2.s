; Name: Jil Shah
; Student Number: 400252316
; Lab Section: L09
; Description of Code: Switches D2 to D1 if the sequence is 1001(on, off,off,on) 
 
; Original: Copyright 2014 by Jonathan W. Valvano, valvano@mail.utexas.edu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;ADDRESS DEFINTIONS
;The EQU directive gives a symbolic name to a numeric constant, a register-relative value or a program-relative value
SYSCTL_RCGCGPIO_R            EQU 0x400FE608  ;General-Purpose Input/Output Run Mode Clock Gating Control Register (RCGCGPIO Register)
GPIO_PORTN_DIR_R             EQU 0x40064400  ;GPIO Port N Direction Register address 
GPIO_PORTN_DEN_R             EQU 0x4006451C  ;GPIO Port N Digital Enable Register address
GPIO_PORTN_DATA_R            EQU 0x400643FC  ;GPIO Port N Data Register address
	
GPIO_PORTM_DIR_R             EQU 0x40063400  ;GPIO Port M Direction Register Address 
GPIO_PORTM_DEN_R             EQU 0x4006351C  ;GPIO Port M Direction Register Address 
GPIO_PORTM_DATA_R            EQU 0x400633FC  ;GPIO Port M Data Register Address      


COMBINATION EQU 2_1001   ;2316- 1001
COUNTER EQU 4
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Do not alter this section
        AREA    |.text|, CODE, READONLY, ALIGN=2 ;code in flash ROM
        THUMB                                    ;specifies using Thumb instructions
        EXPORT Start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Function PortN_Init 
PortN_Init 
    ;STEP 1
    LDR R1, =SYSCTL_RCGCGPIO_R 
    LDR R0, [R1]   
    ORR R0,R0, #0x1000        ;12th bit is 1   				          
    STR R0, [R1]               
    NOP 
    NOP   
   
    ;STEP 5
    LDR R1, =GPIO_PORTN_DIR_R   
    LDR R0, [R1] 
    ORR R0,R0, #0x3         ;0011 because this is an output port
	STR R0, [R1]   
    
    ;STEP 7
    LDR R1, =GPIO_PORTN_DEN_R   
    LDR R0, [R1] 
    ORR R0, R0, #0x3       ;0011                           
    STR R0, [R1]  
    BX  LR                            
 
PortM_Init 
    ;STEP 1 
	LDR R1, =SYSCTL_RCGCGPIO_R       
	LDR R0, [R1]   
    ORR R0,R0, #0x800      
	STR R0, [R1]   
    NOP 
    NOP   
 
    ;STEP 5
    LDR R1, =GPIO_PORTM_DIR_R   
    LDR R0, [R1] 
    ORR R0,R0, #0x0      ; 0  because this is in an input
	STR R0, [R1]   
    
	;STEP 7
    LDR R1, =GPIO_PORTM_DEN_R   
    LDR R0, [R1] 
    ORR R0, R0, #0x11     ;11 - 2 binary input
	                          
    STR R0, [R1]    
	BX  LR                     
State_Init LDR R5,=GPIO_PORTN_DATA_R  ;Locked is the Initial State
		   MOV R4,#2_00000010
	       STR R4,[R5]
	       BX LR 
Start                             
	BL  PortN_Init                
	BL  PortM_Init
	BL  State_Init
	LDR R0, = GPIO_PORTM_DATA_R      ; Inputs set pointer to the input 
	LDR R3, = COMBINATION           ;R3 stores our combination
	LDR R4, = COUNTER

IsZero		
			LDR R1,[R0]    
			AND R2,R1,#2_00010000   
			CMP R2, #2_00000000      ;is the pin m4 not pressed pressed  
			BNE IsZero
IsOne		
			LDR R1,[R0]    
			AND R2,R1,#2_00010000   
			CMP R2, #2_00010000      ;is the pin m4 pressed  
			BNE IsOne

CheckInput	
			AND R2,R1,#2_00000001    ;is button 1 pressed
			CMP R2,#2_00000001       ;button 1 is or not pressed
			BEQ OneDigitInput        ;true - check if one occurs in the right position
			BNE NotFirstDigit        ;false - check if zero occurs in the right position
			
OneDigitInput
			CMP R4,#3                ;is R4 equal to position 3
			BEQ CorrectCombination   ;correct combination so far, determine next input
			CMP R4,#0                ;check if R4 step 0 
			BEQ CorrectCombination   ;correct combination, turn on led 
			BNE Locked_State         ;it is the wrong digit 
			
NotFirstDigit
			CMP R4, #2               ;is R4 at position 2
			CMPNE R4, #1             ;or position 1
			BEQ CorrectCombination	 ;when its zero for position 1 and 2		
			BNE Locked_State	     ;wrong step go into locked
			

CorrectCombination
			CMP R4, #0               ;check if R4 is 0 
			BEQ Unlocked_State       ;call the unlock state which would switch led d2 to d1
			SUB R4,#1                ;R4=R4-1
			B IsZero                 ;take in another input 
 
Locked_State         
	LDR R4, = 3
	LDR R5,=GPIO_PORTN_DATA_R
	MOV R6,#2_00000010   ;PIN 0 - led d2 is on in the locked state
	STR R6,[R5]
	B IsZero
	
Unlocked_State
	LDR R5, =GPIO_PORTN_DATA_R
	MOV R6,#2_00000001  ;PIN 1 led d1 turns on 
	STR R6, [R5]
	LDR R4, =3
	B IsZero
	
	ALIGN   
    END  