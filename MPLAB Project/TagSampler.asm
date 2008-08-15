	#include <p16f88.inc>
	extern	TurnLedOn
	extern	TurnLedOff

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
											errorlevel	-207, -302
	HoldForLow
		btfsc	CMCON, 7
		 goto	HoldForLow

	HoldForHigh
		btfss	CMCON, 7
		 goto	HoldForHigh
											errorlevel	+207, +302
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

	; wait half bit time to put next call at 200 us after edge

	return


;******************************************************************************

RecordBitAndWaitForNext
	
	; keep track of how long it will take to process this bit
	banksel	TMR2		; 2 cycles
	clrf 	TMR2		; 1 cycle

	; debug pulse, should see it every 400 us (bit time) sharp!
	call		TurnLedOn
	call		TurnLedOff

	call 	GetBit
	rlf		INDF, f
		
	decfsz	BitsLeftInCurrentByte, f
	 goto 	WaitForNextBit
	; set up for next byte in buffer
	incf		FSR, f
	movfw	FSR
	; check if buffer is full
	addlw	.255 - LastAddrInBuffer	
	bc		BufferFull ; If FSR > LastAddrInBuffer
	; reinitialize the "bits left" value, since we are at the next, empty byte
	movlw	.8
	movwf	BitsLeftInCurrentByte

WaitForNextBit
	; put the next call to GetBit at 200 us (400 cycles) from last
DelayValue	db	0
ElapsedCycles	db 	0

	movfw	TMR2			; 1 cycle
	movwf	ElapsedCycles	; 1 cycle
	
	; 145 cycles
	movlw	0x30
	movwf	DelayValue
Delay_0
	decfsz	DelayValue, f
	goto	Delay_0

	; [255 - overhead - bit processing time (from TMR2)] cycles
	; WRONG DELAY!!
	movlw	.81
	movwf	DelayValue
	movfw	ElapsedCycles
	subwf	DelayValue, f
Delay_1
	decfsz	DelayValue, f
	goto	Delay_1
	
	goto 	RecordBitAndWaitForNext	; 2 cycles

BufferFull
	return


;******************************************************************************

WaitForTagAndReadRawData
	global	WaitForTagAndReadRawData

	;-------------------------------------------------------------------------
	; Set up the comparator, timers, and indirect addressing
	;
													errorlevel -302
	; Set up the comparator for independent mode
	; Using two external pins, RA1 and RA2
	banksel	CMCON
	movlw	b'00000101'
	movwf	CMCON
													errorlevel +302

	; Disable timer interrupt
	bcf		INTCON, 5

	; TMR0, assign postscaler to WDT, use instruction clock
	bcf		OPTION_REG, 5
	bsf		OPTION_REG, 3

	; TMR2
	banksel	T2CON
	movlw	b'00000100'
	movwf	T2CON		; turn on the timer, no pre/post scalers

	banksel	PR2
	movlw	0xFF
	movwf	PR2			; set timer period to 255
	bcf		PIE1, TMR2IE 	; disable interrupt
	

	; Select the correct bank for indirect addressing
	bsf		STATUS, IRP
	; Initialize the FSR to point to TagData for indirect addressing
	movlw	BitBuffer
	movwf	FSR


	;-------------------------------------------------------------------------
	; Read the tag
	;

	call 	SyncWithFirstBitOfTag
	call 	RecordBitAndWaitForNext

	return

end