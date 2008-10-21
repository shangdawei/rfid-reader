	list      p=10F222            ; list directive to define processor
	#include <p10F222.inc>        ; processor specific variable definitions

	__config   _MCLRE_OFF & _CP_OFF & _WDT_OFF & _MCPU_OFF & _IOFSCS_8MHZ


;**********************************************************************
RESET_VECTOR	CODE   0xFF       ; processor reset vector

; Internal RC calibration value is placed at location 0xFF by Microchip
; as a movlw k, where the k is a literal value.

MAIN			code    0x000
	movwf   OSCCAL            ; update register with factory cal value

START
	; output our 8 MHz clock at pin 3
	bsf		OSCCAL, FOSC4

	; set up GP0 as output for the carrier frequency
	bcf		ADCON0, ANS0

	movlw	b'11111110'
	tris		GPIO

LOOP
	bsf		GPIO, GP0		; 2
	goto	$+1				; 2
	goto	$+1				; 2
	goto	$+1				; 2
	; 8 cycles at .5e-6 sec per cycle, 4 us

	bcf		GPIO, GP0		; 2
	goto	$+1				; 2
	goto	$+1				; 2
	goto LOOP				; 2
	; 8 cycles at .5e-6 sec per cycle, 4 us
	; High for 4 us and low for 4 us, we have a 125 kHz square wave at GP0

	end

