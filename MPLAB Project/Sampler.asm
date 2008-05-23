	#include	<p16f88.inc>
	
	extern TurnLedOn
	extern TurnLedOff

Sampler	code

SampleAndStore	macro targetRegister
		btfsc	CMCON, 7
		 bsf		targetRegister, 7
		btfsc	CMCON, 7
		 bsf		targetRegister, 6
		btfsc	CMCON, 7
		 bsf		targetRegister, 5
		btfsc	CMCON, 7
		 bsf		targetRegister, 4
		btfsc	CMCON, 7
		 bsf		targetRegister, 3
		btfsc	CMCON, 7
		 bsf		targetRegister, 2
		btfsc	CMCON, 7
		 bsf		targetRegister, 1
		btfsc	CMCON, 7
		 bsf		targetRegister, 0
			endm

SampleEncodedBits
	global SampleEncodedBits

	; Set up the comparator
	banksel	CMCON
	movlw	b'00000101'
	movwf	CMCON
	
	; -------------------
	; we are at 500 kHz
	; 8 us per instruction
	
	; -------------------
	; Attempt to synchronize

HoldForHighEdge
	btfss	CMCON, 7
	 goto	HoldForHighEdge

	; at this point we HAVE a HIGH
	; start sampling as fast as possible
	
	errorlevel 1
curSampleReg =	0xA0
	while curSampleReg <= 0xEF
		SampleAndStore		curSampleReg
curSampleReg += 0x01
	endw
	errorlevel 0
	
	return
	

	end