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
;    Filename:         main.asm                                                *
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
;    This comment relates to MPLAB 7.61...                                    *
;                                                                             *
;    If interrupts are used, as in this template file, the 16F88.lkr          *
;    file will need to be modified as follows: Remove the lines               *
;                                                                             *
;    CODEPAGE   NAME=vectors  START=0x0      END=0x4      PROTECTED           *
;                                                                             *
;    and                                                                      *
;                                                                             *
;    SECTION    NAME=STARTUP  ROM=vectors                                     *
;                                                                             *
;    In addition, change the start address of the page 0 section              *
;    from 0x5 to 0x0                                                          *
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
     #INCLUDE <p16f88.inc>          ; processor specific variable definitions
	#include <RfidReaderMain.inc>
	
	errorlevel -302 ;remove message about using proper bank

	extern 	StoreBit
	extern	EnterNormalOperation
	extern	EnterAdminMode

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

	__config		_CONFIG1, _CP_OFF & _CCP1_RB0 & _DEBUG_ON & _WRT_PROTECT_OFF & _CPD_OFF & _LVP_OFF & _BODEN_OFF & _MCLR_ON & _PWRTE_OFF & _WDT_OFF & _INTRC_IO
	__config		_CONFIG2, _IESO_OFF & _FCMEN_OFF
	
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

Globals		udata_shr
Temp1		res		.1	; General purpose temp variables
Temp2		res		.1
Flags		res		.1	; Status flags for program flow
	global	Temp1, Temp2, Flags

ContextVars	udata_shr
STATUS_TEMP	res		.1
PCLATH_TEMP	res		.1

;------------------------------------------------------------------------------
; RESET VECTOR
;------------------------------------------------------------------------------

RESET     CODE    0x0000            ; processor reset vector
          pagesel START
          GOTO    START            ; go to beginning of program

;------------------------------------------------------------------------------
; INTERRUPT SERVICE ROUTINE
;------------------------------------------------------------------------------

INT_VECT  CODE    0x0004        ; interrupt vector location

	; Save context
	movfw	STATUS      	; move status register into W register
	movwf	STATUS_TEMP	; save off contents of STATUS register
	movfw	PCLATH		; move pclath register into W register
	movwf	PCLATH_TEMP	; save off contents of PCLATH register


	; What caused the interrupt?
	banksel	PIE1
	btfsc	PIE1, TMR2IF
	 goto	TMR2_Interrupt
	btfsc	INTCON, INTF
	 goto	Button_Interrupt
	goto 	RestoreContext


TMR2_Interrupt
	bcf		PIE1, TMR2IF	
	call		StoreBit
	goto		RestoreContext

Button_Interrupt
	bcf		INTCON, INTF
	btfss	InAdminMode
	 goto	EnterAdminMode
	goto		EnterNormalOperation
		

RestoreContext
	movfw	PCLATH_TEMP	; retrieve copy of PCLATH register
	movwf	PCLATH		; restore pre-isr PCLATH register contents
	movfw	STATUS_TEMP	; retrieve copy of STATUS register
	movwf	STATUS		; restore pre-isr STATUS register contents
	
	retfie


;------------------------------------------------------------------------------
; MAIN PROGRAM
;------------------------------------------------------------------------------

PROGRAM   CODE    

START
	; Switch to internal 8 MHz clock
	banksel	OSCCON
	movlw	b'01111100'
	movwf	OSCCON

MainLoop
	call		EnterNormalOperation

	goto		MainLoop
	
	end