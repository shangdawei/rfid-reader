	#include <p16f88.inc>
	errorlevel	-302

LedDriver		code

ToggleLed		macro	pinAction	
		; Set up the port for output
		banksel	TRISA
		bcf		TRISA, 0
		clrf		ANSEL	;very drastic, analog in completely disabled
	
		; Set the LED pin to low
		banksel	PORTA
		pinAction	PORTA, 0
			endm

TurnLedOn
 global TurnLedOn
	ToggleLed	bsf
	return

TurnLedOff
 global TurnLedOff
	ToggleLed	bcf
	return

	end

