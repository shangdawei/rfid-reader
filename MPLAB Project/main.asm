;------------------------------------------------------------------------------
; PROCESSOR DECLARATION
;------------------------------------------------------------------------------

     LIST      p=16F88              ; list directive to define processor
     #INCLUDE <p16f88.inc>          ; processor specific variable definitions
	#include <RfidReaderMain.inc>
	
	errorlevel -302 ;remove message about using proper bank

	extern 	StoreBit
	extern	UiLogicSetup
	extern	EnterNormalOperation
	extern	EnterAdminMode


;------------------------------------------------------------------------------
; CONFIGURATION WORD SETUP
;------------------------------------------------------------------------------

	__config		_CONFIG1, _CP_OFF & _CCP1_RB0 & _DEBUG_ON & _WRT_PROTECT_OFF & _CPD_OFF & _LVP_OFF & _BODEN_OFF & _MCLR_ON & _PWRTE_OFF & _WDT_OFF & _INTRC_IO
	__config		_CONFIG2, _IESO_OFF & _FCMEN_OFF
	

;------------------------------------------------------------------------------
; VARIABLE DEFINITIONS
;------------------------------------------------------------------------------

Globals		udata_shr
Temp1		res		.1	; General purpose temp variables
Temp2		res		.1
Temp3		res		.1
Flags		res		.1	; Status flags for program flow
	global	Temp1, Temp2, Temp3, Flags

ContextVars	udata_shr
W_TEMP		res		.1
STATUS_TEMP	res		.1
PCLATH_TEMP	res		.1


;------------------------------------------------------------------------------
; RESET VECTOR
;------------------------------------------------------------------------------

RESET     CODE    0x0000
          pagesel START
          GOTO    START

;------------------------------------------------------------------------------
; INTERRUPT SERVICE ROUTINE
;------------------------------------------------------------------------------

INT_VECT  CODE    0x0004

	; Save context
	movwf	W_TEMP
	movfw	STATUS 	
	movwf	STATUS_TEMP
	movfw	PCLATH
	movwf	PCLATH_TEMP


	; What caused the interrupt?
	banksel	PIE1
	btfsc	PIE1, TMR2IF
	 goto	TMR2_Interrupt
	btfsc	INTCON, INTF
	 goto	Button_Interrupt
	goto 	RestoreContext


TMR2_Interrupt
	banksel	PIR1
	bcf		PIR1, TMR2IF	
	call		StoreBit
	goto		RestoreContext

Button_Interrupt
	; disable stray timer interrupt from sampling
	banksel	PIE1
	bcf		PIE1, TMR2IE 	
	banksel	TMR2
	clrf		TMR2
	bcf		PIR1, TMR2IF

	bcf		INTCON, INTF
	bsf		INTCON, GIE
	btfss	InAdminMode
	 goto	EnterAdminMode
	goto		EnterNormalOperation
		

RestoreContext
	movfw	PCLATH_TEMP
	movwf	PCLATH
	movfw	STATUS_TEMP
	movwf	STATUS
	swapf	W_TEMP,F
	swapf	W_TEMP,W  
	
	retfie


;------------------------------------------------------------------------------
; MAIN PROGRAM
;------------------------------------------------------------------------------

Main   code  

START
	; Switch to internal 8 MHz clock
	banksel	OSCCON
	movlw	b'01111100'
	movwf	OSCCON

	clrf		Flags

	call		UiLogicSetup
	call		EnterNormalOperation

	goto		START
	
	end