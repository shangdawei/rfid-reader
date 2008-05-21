	#include	<p16f88.inc>
	
	extern TurnLedOn
	extern TurnLedOff

Sampler	code

SampleEncodedBits
	global SampleEncodedBits

	banksel	CMCON
	movlw	b'00000101'
	movwf	CMCON

Loop
	banksel 	CMCON
	btfss	CMCON, 7
	 goto	LedOff
LedOn
	call 	TurnLedOn
	goto		Loop
LedOff
	call		TurnLedOff
	goto		Loop

	end