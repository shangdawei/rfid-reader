	#include <p16f88.inc>
	#include <RfidReader.inc>

TagSampleProcessorVars	udata_shr 0x070
_BitCounter	res	.1
_ByteCounter	res	.1
_STATUS_TEMP	res	.1
_TagData		res	.4



TagSampleProcessor code


;******************************************************************************

ClearTagData

	clrf		_TagData
	clrf		_TagData + .1
	clrf		_TagData + .2
	clrf		_TagData + .3
	clrf		_TagData + .4
	clrf		_TagData + .5
	clrf		_TagData + .6

	return	


;******************************************************************************

RotateRawDataBufferAddrToHeader

	movlw	.8
	movwf	_BitCounter
	clrf		_ByteCounter
	clrf		_STATUS_TEMP

	bsf		STATUS, IRP ; Select the correct bank for indirect addressing
	banksel	RawDataBufferAddr

RotateRawDataBufferAddrOneBit
	movlw	LastAddrInRawDataBuffer
	movwf	FSR

	; initialize carry
	bcf		_STATUS_TEMP, C
	btfsc	RawDataBufferAddr, .7
	 bsf		_STATUS_TEMP, C

RotateCurrentRawDataByte
	; load carry
	bcf		STATUS, C
	btfsc	_STATUS_TEMP, C
	 bsf		STATUS, C	

	rlf		INDF, f

	; backup carry
	bcf		_STATUS_TEMP, C
	btfsc	STATUS, C
	 bsf		_STATUS_TEMP, C

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
	 goto	ManchesterDecodeFailed
	bsf		STATUS, C
	goto		SaveBit

BitIsZero
	btfss	RawDataBufferAddr + ByteNumber, BitNumber - .1
	 goto	ManchesterDecodeFailed
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


MachesterDecodeTagData

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

	bsf		STATUS, C
	return

ManchesterDecodeFailed
	bcf		STATUS, C
	return


;******************************************************************************

CheckTagDataParity

	nop
 
	return


;******************************************************************************

ExtractTagDataFromRawData
	global	ExtractTagDataFromRawData

	call		ClearTagData

	call		RotateRawDataBufferAddrToHeader
	bnc		NoValidTagFound

	call		MachesterDecodeTagData
	bnc		NoValidTagFound

	call		CheckTagDataParity
	bnc		NoValidTagFound

NoValidTagFound
	call 	ClearTagData
	return

ValidTagFound	
	return
	
	end