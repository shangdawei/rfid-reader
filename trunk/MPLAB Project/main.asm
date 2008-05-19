;******************************************************************************
;   This file is a basic code template for code generation                    *
;   on the  PIC16F88. This file contains the basic code building              *
;   blocks to build upon.                                                     *
;                                                                             *
;   Refer to the MPASM User's Guide for additional information on             *
;   features of the assembler.                                                *
;                                                                             *
;   Refer to the respective data sheet for additional                         *
;   information on the instruction set.                                       *
;                                                                             *
;******************************************************************************
;                                                                             *
;    Filename:         xxx.asm                                                *
;    Date:                                                                    *
;    File Version:                                                            *
;                                                                             *
;    Author:                                                                  *
;    Company:                                                                 *
;                                                                             *
;                                                                             *
;******************************************************************************
;                                                                             *
;    Files required: P16F88.INC                                               *
;                                                                             *
;******************************************************************************
;                                                                             *
;    Features of the 16F88:                                                   *
;                                                                             *
;    1 10-bit PWM                                                             *
;    8 MHz Internal Oscillator                                                *
;    ICD support                                                              *
;    256 bytes of EEPROM data memory                                          *
;    Capture/Compare Module                                                   *
;                                                                             *
;******************************************************************************
;                                                                             *
;    Notes:                                                                   *
;                                                                             *
;                                                                             *
;******************************************************************************
;                                                                             *
;    Revision History:                                                        *
;                                                                             *
;******************************************************************************

;------------------------------------------------------------------------------
; PROCESSOR DECLARATION
;------------------------------------------------------------------------------

     LIST      p=16F88              ; list directive to define processor
     INCLUDE "P16F88.INC"         ; processor specific variable definitions

;------------------------------------------------------------------------------
;
; CONFIGURATION WORD SETUP
;
; The 'CONFIG' directive is used to embed the configuration word within the 
; .asm file. The lables following the directive are located in the respective 
; .inc file.  See the data sheet for additional information on configuration 
; word settings.
;
;------------------------------------------------------------------------------

;     __CONFIG    _CONFIG1, _CP_OFF & _CCP1_RB0 & _DEBUG_OFF & _WRT_PROTECT_OFF & _CPD_OFF & _LVP_OFF & _BODEN_OFF & _MCLR_ON & _PWRTE_ON & _WDT_OFF & _INTRC_IO
;     __CONFIG    _CONFIG2, _IESO_OFF & _FCMEN_OFF

	cblock 0x20
		led
	endc

;------------------------------------------------------------------------------
;
; VARIABLE DEFINITIONS
;
; Available Data Memory divided into Bank 0 through Bank 3.  Each Bank contains
; Special Function Registers and General Purpose Registers at the locations 
; below:  
;
;           SFR           GPR               SHARED GPR's
; Bank 0    0x00-0x1F     0x20-0x6F         0x70-0x7F    
; Bank 1    0x80-0x9F     0xA0-0xEF         0xF0-0xFF  
; Bank 2    0x100-0x10F   0x110-0x16F       0x170-0x17F
; Bank 3    0x180-0x18F   0x190-0x1EF       0x1F0-0x1FF
;
;------------------------------------------------------------------------------

W_TEMP         EQU        0x7D  ; w register for context saving (ACCESS)
STATUS_TEMP    EQU        0x7E  ; status used for context saving (ACCESS)
PCLATH_TEMP    EQU        0x7F  ; variable used for context saving

;------------------------------------------------------------------------------
; RESET VECTOR
;------------------------------------------------------------------------------

RESET     ORG     0x0000            ; processor reset vector
          PAGESEL START
          GOTO    START             ; go to beginning of program

;------------------------------------------------------------------------------
; INTERRUPT SERVICE ROUTINE
;------------------------------------------------------------------------------

ISR       ORG     0x0004            ; interrupt vector location

;         Context saving for ISR
          MOVWF   W_TEMP            ; save off current W register contents
          MOVF    STATUS,W          ; move status register into W register
          MOVWF   STATUS_TEMP       ; save off contents of STATUS register
          MOVF    PCLATH,W          ; move pclath register into W register
          MOVWF   PCLATH_TEMP       ; save off contents of PCLATH register

;------------------------------------------------------------------------------
; USER INTERRUPT SERVICE ROUTINE GOES HERE
;------------------------------------------------------------------------------
		

;         Restore context before returning from interrupt
          MOVF    PCLATH_TEMP,W     ; retrieve copy of PCLATH register
          MOVWF   PCLATH            ; restore pre-isr PCLATH register contents
          MOVF    STATUS_TEMP,W     ; retrieve copy of STATUS register
          MOVWF   STATUS            ; restore pre-isr STATUS register contents
          SWAPF   W_TEMP,F
          SWAPF   W_TEMP,W          ; restore pre-isr W register contents
          RETFIE                    ; return from interrupt

;------------------------------------------------------------------------------
; MAIN PROGRAM
;------------------------------------------------------------------------------

START

;------------------------------------------------------------------------------
; PLACE USER PROGRAM HERE
;------------------------------------------------------------------------------

; Enable all of A & B for Output
	clrf STATUS ; this also sets bank 0
	clrf PORTA

;======================== Input & Output memory Aid =================
; 1 (one) for Input - note that 1 and i look very much alike.
; 0 (zero) for Output - note that 0 and O look very much alike.
; But be sure to use numbers for setting the port pin directions.
;====================================================================
;========= TRIS command vs. TRISA, TRISB, etc register names ======
; First generation PICs used a command TRIS (tristate) that assigned
; the direction of the port pins. More modern PICs have registers
; called TRISA, TRISB, etc. and the preferred method is to write to
; those registers to control port direction.
;====================================================================
	movlw 0x00
	banksel TRISA
	movwf TRISA

;===================== Ports with possible A/D inputs ===============
; at this point a newbie would think that they had setup port A for
; all outputs, but when the program is run there will be NO outputs
; on port A. When a port contains the possibility of Analog to Digital
; converters those pins are defaulted to analog inputs. This is the safe
; thing to do to prevent damage. In the 16F88 port A has the analog inputs
; and so the Analog Select register needs to be programmed to make whatever
; port A bits we want to be Digital I/O pins. In this case we want all the
; pins on port A to be digital so using the memory aid above (Oh or zero for
; Output) we just clear the ANSEL register.
;====================================================================

	banksel ANSEL
	clrf ANSEL

	banksel PORTA
	clrf led

Loop
	movlw b'00000001'
	xorwf led, f
	movfw led
	movwf PORTA
	call Delay100ms
	goto Loop

; Delay = 0.1 seconds
; Clock frequency = 4 MHz

; Actual delay = 0.1 seconds = 100000 cycles
; Error = 0 %

	cblockTEST
	d1
	d2
	endc

Delay100ms
			;99993 cycles
	movlw	0x1E
	movwf	d1
	movlw	0x4F
	movwf	d2
Delay100ms_0
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	Delay100ms_0

			;3 cycles
	goto	$+1
	nop

			;4 cycles (including call)
	return


	end