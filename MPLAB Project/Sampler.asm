	include	"P16F88.INC"

Sampler	code

SampleEncodedBits
	global SampleEncodedBits

	;setup ports
	banksel	TRISA
	
	bcf		TRISA, 0
	clrf		ANSEL	

;Setup comparator
;CMCON to XX0XX101
;Independent comparator 2, 1 is off
	banksel	CMCON
	
	movlw	b'00100101'
	movwf	CMCON

Loop
	banksel	CMCON
	btfss	CMCON, 7
	 goto	TurnLedOff
TurnLedOn
	banksel	PORTA
	bsf		PORTA, 0
	goto		Loop
	
TurnLedOff
	banksel	PORTA
	bcf		PORTA, 0
	goto		Loop

;Synchronize
;Get sample
;Process sample
;Store in program memory at a location

	end