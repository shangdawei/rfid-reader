	#include <p16f88.inc>

TagSamplerData idata
Flags	res	.1
Bit		equ	1

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
	WaitForComparatorLowToHighEdge

	banksel	TMR0
	clrf		TMR0		; TMR0 will start in 2 instructions (1 us) as per 16f88 datasheet (page 67)

	WaitForComparatorLowToHighEdge
	
	banksel	TMR0
	movfw	TMR0

	; At 12.5k the min timer value:
	;		80 - 2 = 78 us * .5 us per inst = 156
	; Anything 78 us (156 instructions) or slower is mark

	addlw	.255 - .157
	bc		SetBitHigh	; timer value > 157
	bcf		Flags, Bit	; timer value <= 157
	goto		ReturnFromGetBit
SetBitHigh
	bsf		Flags, Bit	

ReturnFromGetBit										
	return


;******************************************************************************

HoldForLowBit
	return


;******************************************************************************

HoldForHighBit
	return
	

;******************************************************************************

SyncWithLowToHighBitEdge
	
	call	HoldForLowBit
	call HoldForHighBit
	
	return


;******************************************************************************

WaitForTagAndReadRawData
	global	WaitForTagAndReadRawData

	;-------------------------------------------------------------------------
	; Set up
	;

													errorlevel -302
	; Set up the comparator for independent mode
	; Using two external pins, RA1 and RA2
	banksel	CMCON
	movlw	b'00000101'
	movwf	CMCON
													errorlevel +302

	; Set up the timer
	; 	- disable timer interrupt
	; 	- use instruction clock
	; 	- assign postscaler to WDT
	bcf		INTCON, 5
	bcf		OPTION_REG, 5
	bsf		OPTION_REG, 3
	
	return

end