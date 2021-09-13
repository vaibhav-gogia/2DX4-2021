;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Name: Vaibhav Gogia
; Lab Section: L05
; Description of Code: Switches LED D1 to D2 if 100 is pressed 
 
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


COMBINATION EQU 2_001
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
    ORR R0,R0, #0x1000         				          
    STR R0, [R1]               
    NOP 
    NOP   
   
    ;STEP 5
    LDR R1, =GPIO_PORTN_DIR_R   
    LDR R0, [R1] 
    ORR R0,R0, #0x3         ;bc this is an output port
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
    ORR R0,R0, #0x0      ;this is in an input
	STR R0, [R1]   
    
	;STEP 7
    LDR R1, =GPIO_PORTM_DEN_R   
    LDR R0, [R1] 
    ORR R0, R0, #0xF     ;for a 4 dig input
	                          
    STR R0, [R1]    
	BX  LR                     
State_Init LDR R5,=GPIO_PORTN_DATA_R  ;Locked is the Initial State
		   MOV R4,#2_00000010          ;D1 ON
	       STR R4,[R5]
	       BX LR 
Start                             
	BL  PortN_Init                
	BL  PortM_Init
	BL  State_Init
	LDR R0, = GPIO_PORTM_DATA_R  ; Inputs set pointer to the input 
	LDR R3, =COMBINATION         ;R3 stores our combination
	
Loop
			LDR R1,[R0]            
			AND R2,R1,#2_00001000    ;pin m3
			CMP R2, #2_00001000      ;check if the 4th button is pressed
			IT EQ                    
			ANDEQ R6,R1,#2_00000111  ;getting the input from buttons
			ANDNE R6,R1,#2_00000000  ;ignore the inputs from the buttons            This is done so the after unlocking, the lock resets on button release
			CMP R6,R3                ;compare with the required combination
			IT EQ
			BEQ Unlocked_State       
			BNE Locked_State         
 
Locked_State                    
	LDR R5,=GPIO_PORTN_DATA_R
	MOV R4,#2_00000010     ;D1 ON
	STR R4,[R5]
	B Loop
	
Unlocked_State
	LDR R5, =GPIO_PORTN_DATA_R
	MOV R4,#2_00000001     ;D2 turns ON
	STR R4, [R5]
	B Loop
	
	ALIGN   
    END  