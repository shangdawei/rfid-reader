	#include <p16f88.inc>
	#include <RfidReader.inc>

TagDataBuffer idata 0x110 
BitsLeftInCurrentByte	db	.8	
RawDataBuffer  			res 	.94


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
	
	;208 cycles
	movlw	0x45
	movwf	Temp1
Delay_0
	decfsz	Temp1, f
	goto	Delay_0

			;2 cycles
	goto	$+1

	return


;******************************************************************************

StoreBit
	global	StoreBit

	call 	GetBit
	rlf		INDF, f
		
	decfsz	BitsLeftInCurrentByte, f
	 goto 	BitStored
	
	; set up for next byte in buffer
	incf		FSR, f
	movfw	FSR
	
	; check if buffer is full
	addlw	.255 - LastAddrInRawDataBuffer	
	bc		BufferFull ; If FSR > LastAddrInRawDataBuffer
	
	; reinitialize the "bits left" value, since we are at the next, empty byte
	movlw	.8
	movwf	BitsLeftInCurrentByte
		
	goto		BitStored			
BufferFull
	banksel	PIE1
	bcf		PIE1, TMR2IE 	; disable timer interrupt	
	bsf		CardRead
		
BitStored
	return


;******************************************************************************

WaitForTagAndReadRawData
	global	WaitForTagAndReadRawData

	bcf		CardRead

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

	banksel	T2CON
	bcf		T2CON, TMR2ON
	clrf		TMR2

	; Select the correct bank for indirect addressing
	bsf		STATUS, IRP
	; Initialize the FSR to point to RawDataBuffer for indirect addressing
	movlw	RawDataBuffer
	movwf	FSR


	;-------------------------------------------------------------------------
	; Read the tag
	;

	call 	SyncWithFirstBitOfTag

	banksel	PR2
	movlw	.200
	movwf	PR2			; will cause an interrupt every 800 cycles
	bsf		INTCON, PEIE	; enable interrupts
	bsf		INTCON, GIE
	bsf		PIE1, TMR2IE 	; enable timer interrupt	

	banksel	T2CON
	movlw	b'00000101'
	movwf	T2CON		; turn on the timer, 1:4 prescaler

WaitForInterrupt
	btfss	CardRead
	goto 	WaitForInterrupt

	return

	end