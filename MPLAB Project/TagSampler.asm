	#include <p16f88.inc>
	extern	TurnLedOn
	extern	TurnLedOff
	
	errorlevel	-302

TagDataBuffer idata 0x110 
BitsLeftInCurrentByte	db	.8	
BitBuffer  			res 	.94
LastAddrInBuffer		equ 	0x6F


TagSamplerCode code

;******************************************************************************

WaitForComparatorLowToHighEdge	macro
	local HoldForLow
	local HoldForHigh
											
		banksel	CMCON
												errorlevel	-207
	HoldForLow
		btfsc	CMCON, 7
		 goto	HoldForLow

	HoldForHigh
		btfss	CMCON, 7
		 goto	HoldForHigh
												errorlevel	+207
	endm	; At this point we are high for at most 4 instructions (2 us)
	

;******************************************************************************

GetBit
	;  __|^^^^^^^|______|^^^^|____
 	;	*  TMR0 VALUE 	*  
	; Anything slower than 12.5 kHz is our mark frequency, everything else is space

	; measure period
	WaitForComparatorLowToHighEdge ; 4 cycles

	banksel	TMR0		; 2 cycles
	clrf		TMR0		; 3 cycles, TMR0 will start in 2 cycles (1 us) as per 16f88 datasheet (page 67)

	WaitForComparatorLowToHighEdge ; 1 cycle, possible and will result in the smallest timer value
	
	banksel	TMR0		; 2 cycles
	movfw	TMR0		; 1 cycle

	; At 12.5k the min timer value:
	;		80 us = 160 cycles
	;		160 cycles - 13 cycles (min overhead) = 147
	; Anything 147 cycles or slower is mark

	addlw	.255 - .146
	bc		SetBitHigh	; timer value > 146
	bcf		STATUS, C	; timer value <= 146
	nop		; pad the timing
	goto		ReturnFromGetBit
SetBitHigh
	bsf		STATUS, C	

ReturnFromGetBit										
	return


;******************************************************************************

SyncWithFirstBitOfTag

HoldForLowBit	
	call 	GetBit
	btfsc	STATUS, C
	 goto	HoldForLowBit

HoldForHighBit
	call 	GetBit
	btfss	STATUS, C
	 goto	HoldForHighBit
	; from experiment 168 cycles from edge

d1	db	0
	;240 cycles
	movlw	0x4F
	movwf	d1
Delay_0
	decfsz	d1, f
	goto	Delay_0
	goto	$+1

	return


;******************************************************************************

StoreBit
	global	StoreBit
	
	; debug pulse, should see it every 400 us (bit time) sharp!
	call		TurnLedOn
	call		TurnLedOff

	call 	GetBit
	rlf		INDF, f
		
	decfsz	BitsLeftInCurrentByte, f
	 goto 	BitStored
	
	; set up for next byte in buffer
	incf		FSR, f
	movfw	FSR
	
	; check if buffer is full
	addlw	.255 - LastAddrInBuffer	
	bc		BufferFull ; If FSR > LastAddrInBuffer
	
	; reinitialize the "bits left" value, since we are at the next, empty byte
	movlw	.8
	movwf	BitsLeftInCurrentByte
		
	goto		BitStored			
BufferFull
	banksel	PIE1
	bcf		PIE1, TMR2IE 	; disable timer interrupt	
		
BitStored
	return


;******************************************************************************

WaitForTagAndReadRawData
	global	WaitForTagAndReadRawData

	;-------------------------------------------------------------------------
	; Set up the comparator, timers, and indirect addressing
	;

	; Set up the comparator for independent mode
	; Using two external pins, RA1 and RA2
	banksel	CMCON
	movlw	b'00000101'
	movwf	CMCON
													

	; Disable timer interrupt
	bcf		INTCON, 5
	; TMR0, assign postscaler to WDT, use instruction clock
	bcf		OPTION_REG, 5
	bsf		OPTION_REG, 3	

	; Select the correct bank for indirect addressing
	bsf		STATUS, IRP
	; Initialize the FSR to point to TagData for indirect addressing
	movlw	BitBuffer
	movwf	FSR


	;-------------------------------------------------------------------------
	; Read the tag
	;

	call 	SyncWithFirstBitOfTag

	banksel	PR2
	movlw	.198
	movwf	PR2			; will cause an interrupt every 800 cycles
	bsf		INTCON, PEIE	; enable interrupts
	bsf		INTCON, GIE
	bsf		PIE1, TMR2IE 	; enable timer interrupt	

	banksel	T2CON
	movlw	b'00000101'
	movwf	T2CON		; turn on the timer, 1:4 prescaler

WaitForInterrupt
	goto WaitForInterrupt

	return

	end