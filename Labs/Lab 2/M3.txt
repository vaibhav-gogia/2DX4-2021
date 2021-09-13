;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Name: Vaibhav Gogia
; Student Number: 400253615
; Lab Section: L05
; Description of Code: sequential lock troubleshooting with the code 0100

 
; Original: Copyright 2014 by Jonathan W. Valvano, valvano@mail.utexas.edu



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;ADDRESS DEFINTIONS

SYSCTL_RCGCGPIO_R            EQU 0x400FE608  ;General-Purpose Input/Output Run Mode Clock Gating Control Register (RCGCGPIO Register)
GPIO_PORTN_DIR_R             EQU 0x40064400  ;GPIO Port N Direction Register address 
GPIO_PORTN_DEN_R             EQU 0x4006451C  ;GPIO Port N Digital Enable Register address
GPIO_PORTN_DATA_R            EQU 0x400643FC  ;GPIO Port N Data Register address
	
GPIO_PORTM_DIR_R             EQU 0x40063400  ;GPIO Port M Direction Register Address (Fill in these addresses)
GPIO_PORTM_DEN_R             EQU 0x4006351C  ;GPIO Port M Direction Register Address (Fill in these addresses)
GPIO_PORTM_DATA_R            EQU 0x400633FC  ;GPIO Port M Data Register Address      (Fill in these addresses) 

GPIO_PORTF_DATA_R             EQU     0x4005D3FC         ;GPIO Port N DATA Register 
GPIO_PORTF_DIR_R              EQU     0x4005D400         ;GPIO Port N DIR Register
GPIO_PORTF_DEN_R              EQU     0x4005D51C         ;GPIO Port N DEN Register

SEQUENCE EQU 2_0100		; combination to use for unlocking
COUNTER EQU 4				; counter to keep track of correct inputs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Do not alter this section

        AREA    |.text|, CODE, READONLY, ALIGN=2 ;code in flash ROM
        THUMB                                    ;specifies using Thumb instructions
        EXPORT Start

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Function PortN_Init          ;Initializing the necessary ports for this job
PortN_Init              
    ;STEP 1
    LDR R1, =SYSCTL_RCGCGPIO_R 
    LDR R0, [R1]   
    ORR R0,R0, #0x1000           				          
    STR R0, [R1]               
    NOP 
    NOP   
   
    ;STEP 5
    LDR R1, =GPIO_PORTN_DIR_R       ;initialize the direction register for port N
    LDR R0, [R1] 
    ORR R0,R0, #0x3                 ;it's an output register
	STR R0, [R1]   
    
    ;STEP 7
    LDR R1, =GPIO_PORTN_DEN_R        ;initialize the digital enable register for port M
    LDR R0, [R1] 
    ORR R0, R0, #0x3                                    
    STR R0, [R1]  
    BX  LR  

PortF_Init                               ;Port F needs to be intialized for troubleshooting to be able to use LEDs D3 and D4
	LDR R1, =SYSCTL_RCGCGPIO_R    		
	LDR R0, [R1]						
	ORR R0,R0, #0x820				 ;it's an output register	
	STR R0, [R1]						
	NOP
	NOP
		 
	;STEP 5
	LDR R1, =GPIO_PORTF_DIR_R			 ;initialize the direction register for port F
	LDR R0, [R1]						
	ORR R0,R0, #0x3					
	STR R0, [R1]	

	;STEP 7
	LDR R1, =GPIO_PORTF_DEN_R			 ;initialize the digital enable register for port M\F
	LDR R0, [R1]						
	ORR R0,R0, #0x3					
	STR R0, [R1]	
	BX LR

; Function PortM_Init
PortM_Init 
    ;STEP 1 
	LDR R1, =SYSCTL_RCGCGPIO_R       
	LDR R0, [R1]   
    ORR R0,R0, #0x800 
	STR R0, [R1]   
    NOP 
    NOP   
 
    ;STEP 5
    LDR R1, =GPIO_PORTM_DIR_R            ;initialize the direction register for port M
    LDR R0, [R1] 
    ORR R0,R0, #0x000                   ;initialized to 0 bc it is an input register
	STR R0, [R1]   
    
	;STEP 7
    LDR R1, =GPIO_PORTM_DEN_R             ;initialize the digital enable register for port M
    LDR R0, [R1] 
    ORR R0, R0, #0x11        
	                          
    STR R0, [R1]    
	BX  LR                     


State_Init LDR R5,=GPIO_PORTN_DATA_R  ;initial state (locked)
	       MOV R4,#2_00000010         ;D1 is on initially
	       STR R4,[R5]  
	       BX LR 

Start                             
	BL  PortN_Init    	; initializing ports and the initial state            
	BL  PortM_Init
	BL  PortF_Init
	BL  State_Init
	LDR R0, =GPIO_PORTM_DATA_R  ; Inputs set pointer to the input 
	LDR R3, =SEQUENCE       ; R3 stores the sequence
	LDR R4, =COUNTER			
	B isZero


;checking if the push button was pressed
isZero
	LDR R1, [R0]
	AND R2, R1, #2_00010000	; checking PM4
	CMP R2, #2_00000000
	BNE isZero		
	
isOne
	LDR R1, [R0]
	AND R2, R1, #2_00010000	; checking PM4
	CMP R2, #2_00010000
	BNE isOne				; stay here if zero
	;decrementing the counter if the current binary value is correct
	AND R2, R1, #2_01		; check PM0
	AND R7, R3, #2_01000	; checking the front bit of seq
	LSR R7, R7, #3			;shift bit right by 3 to compare w/ PM0
	CMP R7, R2
	BNE WrongEntry			; if entry is incorrect, go to wrongEntry


CorrectEntry				; if the entry was correct, decrement counter
	; checking if the sequence was correctly input
	LDR R9, =GPIO_PORTF_DATA_R     ;light up D4 if the input digits are correct
	MOV R8, #2_00000001
	STR R8, [R9]
	CMP R4, #0         ;if counter is 0, it means we have the right sequence
	BEQ Unlocked_State		; going to unlocked_stat
	SUB R4, #1
	LSL R3, R3, #1          ;logical shift left, one place at a time
	B isZero
	
WrongEntry
	LDR R4, =COUNTER			; starting over again by resetting values
	LDR R3, =SEQUENCE
	LDR R9, =GPIO_PORTF_DATA_R     ;LED d4 to go off if the input is incorrect
	MOV R8, #2_00000000
	STR R8, [R9]
	
	LDR R5, =GPIO_PORTN_DATA_R		; reset LED to locked
	MOV R6,#2_00000010
	STR R6, [R5]                    ;store contents of R5 into R6
	
	B isZero
	
	
Unlocked_State
	LDR R5, =GPIO_PORTN_DATA_R		
	MOV R6,#2_00000001				;switching LED 2 from 1
	STR R6, [R5]                   ;store contents of R5 into R6
	NOP 
	NOP
	NOP
	
	ALIGN   
    END  