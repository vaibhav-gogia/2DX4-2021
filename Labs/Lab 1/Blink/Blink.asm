	title "Blink V. 1.0"
	subtitle "The uC Equivalent of Hello world"
; This program uses Assembly language to blink a small LED, using the PIC16F1936's onboard timers
; and interrupts.  Use and modify this code however you wish

; ***** Program Header *******************************************************************************
	list P=PIC16F1936, ST=OFF, MM=OFF, N=42, B=6, W=1 ; <-- List file directives
	include <p16f1936.inc> ; <--Use the name of your PIC here

; You can set configuration bits here too.  I have opted not to.  There are different bits
; for different situations, and MPlab has a tool for setting them
; My settings are as follows
; CONFIG1: 2FC4
; CONFIG2: 1BFF

; ******* Definitions ********************************************************************************

; Time to create variables
; cblock actually just tells the compiler to start allocating space in the chip starting at 
; memory location h'20' or register 32 of bank 0.  Page 31 of the data sheet shows that we have a 96 byte
; general purpose register starting at this location in bank 0.
; Variables here are just names for memory locations.

	cblock h'20'
				; As it turns out, I didn't really need any variables.  Oh well
	endc

; Time to assign names to some buttons
; All of these will be on Port B.  Specific pins are addressed or tested as Port, Bitnumber.
; These definitions just give the bit location a name.  Every instance of the name is replaced
; by the bit location (0-7)

; These are actually called labels.  They're the only thing allowed in column 0. 
; MPlab assumes that anything not a semicolon in column 0 is a label.

HIGH_BYTE	equ b'00001011'		; These two values relate to the delay between flashes
LOW_BYTE	equ b'11011100'		;

LED			equ 0				; LED on pin 0 of port B

; You can also give certain numbers a name.  This beats going through your code every time you want to
; change a silly constant.  This is exactly like defining constants in C++ or Java.
; See my lovely label?

One_Second equ d'10'			; The label "One Second" means in compilerspeak "10"


; ******* Main Program ********************************************************************************
; Org 0 tells the compiler that this is literally the origin of the actual program, IE line 0
; From hereon out, the compiler assumes that each instruction is to be executed sequentially.
	org 0

; ******* Initializing the PIC ************************************************************************
; Initialization is all about getting the right numbers in the right registers in the right order.
; I suggest doing things in the following order 1) Oscillator.  2) Ports  3) Special registers 
; 4) User variables.  However it is -just- a suggestion, and you might want to do things differently
; Start_Program and Main are just labels.  You could call Start_Program whatever you wanted really/
; The PIC just executes instructions sequentially starting at org 0

Start_Program	call Init_Osc		; Initialize the Internal Oscillator
				call Init_Ports		; Initialize the ports of the chip
				call Init_Timer		; Initialize one of the onboard timers
				call Init_Intr		; Initialize interrupts


Main
				call Half_Second_Delay
				call Toggle_LED
				bra Main	; loop forever til chip reset
							; This means that our sub-programs, written below here, will only
							; be reachable through a branching instruction
							
; ******* Sub-programs/methods*************************************************************************


; Initialize the PIC Oscillator to operate at 4 Mhz.  4 Mhz is a good speed because it means the
; instruction cycle will take approximately 1 uS.  For the 16F1936, the default frequency after a reset
; is 500 kHz.  However our device has 9 options for the internal oscillator.  These values can also
; be found on page 110 of the data sheet.
; 31 khz -- Uncalibrated internal clock source
; 31.25 khz
; 125 khz
; 250 khz
; 500 khz -- Default clock speed
; 1 Mhz
; 2 Mhz
; 4 Mhz
; 8 Mhz
; 16 Mhz
; To initialize the internal oscillator we must first move to the memory bank the register is in
; On the memory map, page 27 of the data sheet, the OSCCON register is in bank 1.  So we move there
; Now we create the control byte
; First, we start by determining the type of clock used.
; We're using MPLab and the settings in our configuration word to determine the source
; so our control byte looks like this.  Bit 2 is unused, so it is left at 0
; xxxxx000
; Consulting page 110 of the data sheet, we now need to set bits 3-6, the internal
; frequency select bits.  4 Mhz HF means these four bits need to be 1101.  Our
; byte now looks like this x1101010.  Since we're internal oscillator only, we can
; set the PLL bit. 11101010

Init_Osc

		movlb 1				; Go into bank 1
		movlw b'11101010'	; Set the control byte
		movwf OSCCON
		movlb 0				; Go back to bank 0
		return ; Go UP on the calling stack.  This PIC has a stack 16 levels deep. 


; -----------------------------------------------------------------------
; The pins on the PIC are organized into ports.  Each port is about 8 bits wide.  However this
; is only a general rule and your device may vary.

; To setup a particular pin, we need to put values into the corresponding Analog Select
; register, and Tri-state register.  This ensures that our pin will be an output, and that
; it will be a digital output.
Init_Ports
		movlb 0
		clrf PORTB
		movlb 3
		clrf ANSELB	;	Make Port B all Digital
		movlb 1
		clrf TRISB	; Make Port B all output
		movlb 0		
		return

; -----------------------------------------------------------------------
; This method is going to use Timer 1 to control the blink rate of the LED
; The overall delay = (Frequency of the Oscillator / 4) * Prescale * Period
; Timer1 is in bank 0 so no switching is required. 
; I want my overall delay to be 500 milliseconds or 500000 microseconds.  One instruction
; cycle is 1 microsecond
;
; Timer 1 has a 3 bit prescaler allowing divisions of 1, 2, 4 or 8.  500000 factors to
; 2^5 x 5^6.  I can get 2^3 with a prescale value of 8, leaving my period to be 2^2 * 5^6
; or 62500 which is an acceptable value to express in 16 bits or 2 bytes.  This means I have to
; preload my timer with 2^16 -62500 or 3036

; T1CON is my control register.  I use it to select the various features of the model.  By knowing
; what I want Timer 1 to do, I can build a control byte.  I then move that byte to the register

; Bit 7-6: Clock source select bits.  Set to 00 in order to operate Timer1 from the instruction clock
; Bit 5-4: Prescale value.  Set to 11 in order to give me a prescale of 8
; Bit 3  : Control bit for a dedicated low power oscillator.  Set to 0, disabled.
; Bit 2  : External clock input synchronization control bit.  I'm using the internal clock.  Set to 0
; Bit 1  : Unimplemented.  Set to 0
; Bit 0  : On/Off bit.  Set to 1 to turn the timer on.  Starts as off
; My eventual control byte is 00110000 or 48 in decimal land.

Init_Timer
; Timer1 Registers: 
; Prescaler=1:8; TMR1 Preset=3036; Freq=2.00Hz; Period=0.50 s
	movlw d'48'
	movwf T1CON
	return

; However just setting up the timer is not all that needs to be done.  I also
; need to set up the interrupt registers.  This makes checking to see if the timer
; has overflowed a simple bit test.  That means I only have to set one interrupt bit/
; There are interrupt registers PIRx and interrupt enable registers PIEx
Init_Intr
	bsf PIE1, TMR1IE	; Enable the timer 1 overflow interrupt enable bit
	bcf PIR1, TMR1IF	; Clear the timer 1 overflow interrupt bit
		return


; ***** Timing Routines **************************************************
; Delay routine using interrupts.  Bsf and Bcf are used to set or clear a particular
; bit in your register of interest.
; This code clears the interrupt, preloads the timer, and then waits for the 
; overflow interrupt.
Half_Second_Delay

	bcf T1CON, TMR1ON	; Turn off timer one
	bcf PIR1, TMR1IF	; Clear the timer 1 overflow interrupt bit
	
	movlw LOW_BYTE		; Set the low byte
	movwf TMR1L
	movlw HIGH_BYTE		; Set the high byte
	movwf TMR1H	

	bsf T1CON, TMR1ON	; Turn the timer on

	btfss PIR1, TMR1IF	; Test the overflow interrupt
	bra $-1				; And wait for it!

	bcf T1CON, TMR1ON	; Turn off the timer
	bcf PIR1, TMR1IF	; Clear the interrupt
	return

; ***** Miscellaneous Routines*********************************************
; Toggle the state of the LED on Port B
Toggle_LED
	
	btfsc PORTB, LED	; is the LED off?
	bra Is_On			; Go to Is_On.  Will be skipped if the LED is off

Is_Off					; Executes if the LED is off
	bsf PORTB, LED
	return

Is_On					; Executes if the LED is on
	bcf PORTB, LED
	return

; ******* Ending the Program***********************************************
; The end directive tells the compiler to stop adding things to the hex file that's going to be loaded
; into the program memory 
	end