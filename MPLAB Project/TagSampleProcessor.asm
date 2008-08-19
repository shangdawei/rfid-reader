	#include <p16f88.inc>
	#include <RfidReader.inc>

Globals		udata_shr 0x070
_BitCounter	res	.1
_ByteCounter	res	.1
_STATUS_TEMP	res	.1
_TagData		res	.7

TagSampleProcessor code

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

DecodeTagData
	
	nop

	return

;******************************************************************************

ExtractTagDataFromRawData
	global	ExtractTagDataFromRawData

	call		RotateRawDataBufferAddrToHeader
	bnc		NoValidTagFound

	call		DecodeTagData
	bnc		NoValidTagFound

NoValidTagFound
	return

ValidTagFound
	
	return
	
	end