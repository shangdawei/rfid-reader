	#include <p16f88.inc>
	#include <RfidReader.inc>

	errorLevel	-302

TagSampleProcessorVars	udata_shr 0x070
_BitCounter	res	.1
_ByteCounter	res	.1
_TagData		res	.4
	global	_TagData

_EvenParityBit	equ	.0
_OddParityBit	equ	.1


TagSampleProcessor code


;******************************************************************************

ClearTagData

	clrf		_TagData
	clrf		_TagData + .1
	clrf		_TagData + .2
	clrf		_TagData + .3

	return	


;******************************************************************************

RotateRawDataBufferAddrToHeader

	bsf		STATUS, IRP ; Select the correct bank for indirect addressing
	banksel	RawDataBufferAddr

RotateRawDataBufferAddrOneBit
	movlw	LastAddrInRawDataBuffer
	movwf	FSR

	; initialize carry
	bcf		Temp1, C
	btfsc	RawDataBufferAddr, .7
	 bsf		Temp1, C

RotateCurrentRawDataByte
	; load carry
	bcf		STATUS, C
	btfsc	Temp1, C
	 bsf		STATUS, C	

	rlf		INDF, f

	; backup carry
	bcf		Temp1, C
	btfsc	STATUS, C
	 bsf		Temp1, C

	; check if if we rotated every byte in the buffer
	decf		FSR, f	
	movfw	FSR
	addlw	.255 - RawDataBufferAddr + .1	
	bc		RotateCurrentRawDataByte ; If FSR >= RawDataBufferAddr
	
CheckForHeaderAndTrailer
	; [ 0x1D555955556 (52 bits of tag data) 0b000111 ]
	; Check for header
	movlw	0x1D
	xorwf	RawDataBufferAddr, w
	bnz		HeaderOrTrailerNotFound

	movlw	0x55
	xorwf	RawDataBufferAddr + .1, w
	bnz		HeaderOrTrailerNotFound

	movlw	0x59
	xorwf	RawDataBufferAddr + .2, w
	bnz		HeaderOrTrailerNotFound

	movlw	0x55
	xorwf	RawDataBufferAddr + .3, w
	bnz		HeaderOrTrailerNotFound

	movlw	0x55
	xorwf	RawDataBufferAddr + .4, w
	bnz		HeaderOrTrailerNotFound

	movlw	0x60
	xorwf	RawDataBufferAddr + .5, w
	andlw	0xF0
	bnz		HeaderOrTrailerNotFound

	; Check for trailer
	movlw	0x1C
	xorwf	RawDataBufferAddr + .12, w
	andlw	0xFC
	bnz		HeaderOrTrailerNotFound

	goto		TagDataFound

HeaderOrTrailerNotFound
	; increment byte counter every 8 bits rotated	
	decfsz	_BitCounter, f
	 goto	RotateRawDataBufferAddrOneBit
	movlw	.8
	movwf	_BitCounter

	incf		_ByteCounter, f
	movfw	_ByteCounter
	
	; check if we have rotated through the whole buffer
	addlw	.255 - ( LastAddrInRawDataBuffer - RawDataBufferAddr )
	bnc		RotateRawDataBufferAddrOneBit ; If _ByteCounter <= LastAddrInRawDataBuffer - RawDataBufferAddr
		
NoTagDataFound
	bcf		STATUS, C
	return

TagDataFound
	bsf		STATUS, C
	return


;******************************************************************************

MachesterDecodeBit	macro	ByteNumber, BitNumber
	local BitIsOne
	local BitIsZero
	local SaveBit
	
	btfsc	RawDataBufferAddr + ByteNumber, BitNumber
	 goto	BitIsOne
	goto		BitIsZero

BitIsOne
	btfsc	RawDataBufferAddr + ByteNumber, BitNumber - .1
	 goto	TagDataDecodeFailed
	bsf		STATUS, C
	goto		SaveBit

BitIsZero
	btfss	RawDataBufferAddr + ByteNumber, BitNumber - .1
	 goto	TagDataDecodeFailed
	bcf		STATUS, C

SaveBit
	rlf		_TagData + .3, f
	rlf		_TagData + .2, f
	rlf		_TagData + .1, f
	rlf		_TagData, f

	endm


MachesterDecodeByte	macro	ByteNumber

	MachesterDecodeBit	ByteNumber, .7	
	MachesterDecodeBit	ByteNumber, .5
	MachesterDecodeBit	ByteNumber, .3
	MachesterDecodeBit	ByteNumber, .1
	
	endm


DecodeTagData

	call 	ClearTagData

	banksel	RawDataBufferAddr
	
	errorLevel	-302
	MachesterDecodeBit	.5, .3
	MachesterDecodeBit	.5, .1
	MachesterDecodeByte	.6
	MachesterDecodeByte	.7
	MachesterDecodeByte	.8
	MachesterDecodeByte	.9
	MachesterDecodeByte	.10
	MachesterDecodeByte	.11
	errorLevel	+302

	; extract parity
	rrf		_TagData, f
	rrf		_TagData + .1, f
	rrf		_TagData + .2, f
	rrf		_TagData + .3, f
	btfsc	STATUS, C
	 bsf		_TagData, .1

	; move parity to the last byte in TagData
	movfw	_TagData
	movwf	Temp2
	movfw	_TagData + .1
	movwf	_TagData
	movfw	_TagData + .2
	movwf	_TagData + .1
	movfw	_TagData + .3
	movwf	_TagData + .2
	movfw	Temp2
	movwf	_TagData + .3

	bsf		STATUS, C
	return

TagDataDecodeFailed
	bcf		STATUS, C
	return


;******************************************************************************

CheckTagDataParity
	
	; calculate even parity
	clrf		Temp2

	btfsc	_TagData + .0, .7
	 incf	Temp2,f
	btfsc	_TagData + .0, .6
	 incf	Temp2,f
	btfsc	_TagData + .0, .5
	 incf	Temp2,f
	btfsc	_TagData + .0, .4
	 incf	Temp2,f
	btfsc	_TagData + .0, .3
	 incf	Temp2,f
	btfsc	_TagData + .0, .2
	 incf	Temp2,f
	btfsc	_TagData + .0, .1
	 incf	Temp2,f
	btfsc	_TagData + .0, .0
	 incf	Temp2,f
	btfsc	_TagData + .1, .7
	 incf	Temp2,f
	btfsc	_TagData + .1, .6
	 incf	Temp2,f
	btfsc	_TagData + .1, .5
	 incf	Temp2,f
	btfsc	_TagData + .1, .4
	 incf	Temp2,f

	btfsc	Temp2, .0
	 goto	CalcedEvenParityIsOne

CalcedEvenParityIsZero
	btfsc	_TagData + .3, _EvenParityBit
	 goto	WrongParity
	goto		CalcOddParity

CalcedEvenParityIsOne
	btfss	_TagData + .3, _EvenParityBit
	 goto	WrongParity	

CalcOddParity
	clrf		Temp2

	btfsc	_TagData + .1, .3
	 incf	Temp2,f
	btfsc	_TagData + .1, .2
	 incf	Temp2,f
	btfsc	_TagData + .1, .1
	 incf	Temp2,f
	btfsc	_TagData + .1, .0
	 incf	Temp2,f	
	btfsc	_TagData + .2, .7
	 incf	Temp2,f
	btfsc	_TagData + .2, .6
	 incf	Temp2,f
	btfsc	_TagData + .2, .5
	 incf	Temp2,f
	btfsc	_TagData + .2, .4
	 incf	Temp2,f
	btfsc	_TagData + .2, .3
	 incf	Temp2,f
	btfsc	_TagData + .2, .2
	 incf	Temp2,f
	btfsc	_TagData + .2, .1
	 incf	Temp2,f
	btfsc	_TagData + .2, .0
	 incf	Temp2,f

	btfss	Temp2, .0
	 goto	CalcedOddParityIsOne

CalcedOddParityIsZero
	btfsc	_TagData + .3, _OddParityBit
	 goto	WrongParity
	goto		CorrectParity

CalcedOddParityIsOne
	btfss	_TagData + .3, _OddParityBit
	 goto	WrongParity
	goto		CorrectParity

WrongParity
	bcf		STATUS, C	
	return

CorrectParity
	bsf		STATUS, C
	return


;******************************************************************************

ExtractTagDataFromRawData
	global	ExtractTagDataFromRawData

	call		ClearTagData

	movlw	.8
	movwf	_BitCounter
	clrf		_ByteCounter
	clrf		Temp1
	clrf		Temp2

RotateToNextHeaderInstance
	call		RotateRawDataBufferAddrToHeader
	bnc		NoValidTagFound

	call		DecodeTagData
	bnc		RotateToNextHeaderInstance

	call		CheckTagDataParity
	bnc		RotateToNextHeaderInstance

	goto		ValidTagFound

NoValidTagFound
	call 	ClearTagData
	bcf		STATUS, C
	return

ValidTagFound	
	bsf		STATUS, C
	return
	
	end