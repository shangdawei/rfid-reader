	#include	<p16f88.inc>


SampleStorage	idata	0x110
 SampledBits		res		.95
 LastTimerValue	res		.1


PeriodError	equ		.4
StoreBit		macro	bitNumber
	local HoldForHigh
	local _HoldForLow
	local HoldForLow
	local CheckForSpaceFreq
	local BitProcessed
	local SkipPeriod
													errorlevel	-207
	;------------------------------------------------------------------------------
	; we are at 8 MHz
	; .5 us per instruction
	
	;------------------------------------------------------------------------------
	; Attempt to synchronize
	HoldForHigh
		btfss	CMCON, 7
		 goto	HoldForHigh

		; At this point we are very much high for at most 4 instructions
		; 	in other words .5 * 4 = 2 us
		;	which means that the next edge is in
		;		64 us (15.625 kHz period) - 2 us = 62 us
		;	or 	80 us (12.5 kHz period) - 2 us = 78 us
		; 	or a little later
		;	so we have 62 us to do some work

		; Delay so the timer is reset at, at most, 20 instructions after the edge	
		; 					 	   at least, 16 instructions after the edge
		call		Delay10instr

		; Store current value of the timer in W register
		; We'll move into bank 2, since TMR0 is available there and there is more memory to store the samples
		banksel	2
		movfw	TMR0
		; Reset the timer
		clrf		TMR0
		; It will start in 2 instructions (1 us) as per 16f88 datasheet (page 67)
		
		; Check how long we've waited since the last reset
		; At 15.625k:
		;	Min timer value:
		;		detected late, followed by detected on edge
		;		64 us expected period - 2 us late error = 62 us * .5 us per inst = 124
		;	Max timer value:
		;		detected on time, followed by detected edge late
		;		64 us expected period + 2 us edge error = 66 us * .5 us per inst = 132
		; At 12.5k:
		;	Min timer value:
		;		80 - 2 = 78 us * .5 us per inst = 156 
		;	Max timer value:
		;		80 + 2 = 82 us * .5 us per inst = 164
		;	Experimental: 156, 123, 135, 150
		; We have 12 us beween 15.625k max and 12.5k min, 
		; We can use the timer value of 132 + (156-132)/2 = 144,
		; as the cut off value. Anything less is 15.625k, anything more is considered 12.5k.
		;

		; Select the correct bank for indirect addressing
		bsf		STATUS, IRP
		; Backup the timer value
		movwf	LastTimerValue


		addlw 	.255 - (.132 + PeriodError)
		btfsc	STATUS, C		
		 ; timer value > (132 + err)
		 goto	CheckForSpaceFreq	
		; timer value <= (132 + err)
		
		; restore timer value
		movfw	LastTimerValue

		addlw	.255 - (.124 - PeriodError)
		btfss	STATUS, C
		 ; timer value <= (124 - err)
		 goto	CheckForSpaceFreq
		; (124 - err) < timer value <= (132 + err)
		; Store bit as low for "space" frequency in FSK
		bcf		INDF, bitNumber

		goto		BitProcessed
		
	CheckForSpaceFreq
		;	restore timer value
		movfw	LastTimerValue

		addlw 	.255 - (.164 + PeriodError)
		btfsc	STATUS, C		
		 ; timer value > (164 + err)
		 goto	SkipPeriod	
		; timer value <= (164 + err)
		
		; restore timer value
		movfw	LastTimerValue

		addlw	.255 - (.156 - PeriodError)
		btfss	STATUS, C
		 ; timer value <= (156 - err)
		 goto	SkipPeriod
		; (156 - err) < timer value <= (164 + err)
		; Store bit as high for "mark" frequency in FSK
		bsf		INDF, bitNumber

		goto		BitProcessed
	
	SkipPeriod
		banksel	CMCON
	_HoldForLow
		btfsc	CMCON, 7
		 goto	_HoldForLow
		goto		HoldForHigh
													errorlevel 	-302
		; Now hold untill the signal is low, 
		; so we can safely hold for high at the next bit when this macro is cascaded
	BitProcessed
		banksel	CMCON
	HoldForLow
		btfsc	CMCON, 7
		 goto	HoldForLow
													errorlevel	+302
		endm



Sampler	code

WaitForCardAndReadRawData
	global WaitForCardAndReadRawData
	
	;------------------------------------------------------------------------------
	; Set up for sampling
	;------------------------------------------------------------------------------
	
	; Set up the comparator for independent mode
	; Using two external pins, RA1 and RA2
													errorlevel -302
	banksel	CMCON
	movlw	b'00000101'
	movwf	CMCON


	; Set up the timer
	; disable timer interrupt
	; use instruction clock
	; assign postscaler to WDT
	bcf		INTCON, 5
	bcf		OPTION_REG, 5
	bsf		OPTION_REG, 3
	
	; Reset the timer
	banksel	TMR0
	clrf		TMR0
													errorlevel +302
		
	; Initialize the FSR
	movlw	0x10
	movwf	FSR

	banksel	CMCON
	
StoreByte
	StoreBit	7
	fill		(nop), 7
	StoreBit 	6
	fill		(nop), 7
	StoreBit 	5
	fill		(nop), 7
	StoreBit 	4
	fill		(nop), 7
	StoreBit 	3
	fill		(nop), 7
	StoreBit 	2
	fill		(nop), 7
	StoreBit 	1
	fill		(nop), 7
	StoreBit 	0
	; If  - no more samples can be stored, FSR >= 0x6E
	movfw	FSR
	addlw	.255 - 0x6E + .1
	btfsc	STATUS, C
	 goto	SampleMemoryFilled
	; else - increment the byte pointer
	; 	    and go store another byte
	incf		FSR, f
	goto		StoreByte

SampleMemoryFilled
	return


; Delay = 10 instruction cycles
; Clock frequency = 8 MHz

; Actual delay = 5e-006 seconds = 10 cycles
; Error = 0 %

Delay10instr
			;6 cycles
	goto	$+1
	goto	$+1
	goto	$+1

			;4 cycles (including call)
	return


	end