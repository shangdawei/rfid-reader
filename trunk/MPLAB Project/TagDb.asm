	#include <p16f88.inc>
	#include <RfidReader.inc>
	extern	_TagData

	errorLevel	-302


TagDbEepromVars 	org	0x2100
_NextRecord		de	.1
_TagDb			de	.252  ; MUST be in multiples of three bytes, _TagData size

_LastAddrInTagDb	equ	0xFC  ; MUST be the last byte of _TagDb



TagDb	code


;******************************************************************************

WaitForEepromWriteComplete	macro
	
	banksel	EECON1
	btfsc	EECON1, WR
	 goto	$-1
	
	endm


WriteEepromByte
	
	WaitForEepromWriteComplete

	banksel	EECON1
	bcf		EECON1, EEPGD	; Select data EEPROM as the dest
	bsf		EECON1, WREN	; Enable writes
	bcf		INTCON, GIE	; Disable interrupts

	; Start the write sequence
	movlw	0x55
	movwf	EECON2
	movlw	0xAA
	movwf	EECON2
	bsf		EECON1, WR

	bsf		INTCON, GIE 	; Enable interrupts
	bcf		EECON1, WREN	; Disable writes

	WaitForEepromWriteComplete

	return


;******************************************************************************

ReadEepromByte
	
	banksel	EECON1
	bcf		EECON1, EEPGD	; Select data EEPROM as the dest
	bsf		EECON1, RD	; Begin read
	
	return


;******************************************************************************

ClearTagDb
	global ClearTagDb

	banksel	EEADR
	movlw	_TagDb
	movwf	EEADR
	clrf		EEDATA

ClearEepromByte
	call		WriteEepromByte

	; Continue unless we reached the last byte in _TagDb
	banksel	EEADR
	movfw	EEADR
	sublw	_LastAddrInTagDb
	incf		EEADR, f
	bnz		ClearEepromByte ; If EEADR != _LastAddrInTagDb

	; Reset the next record pointer	
	banksel	EEADR
	movlw	_NextRecord
	movwf	EEADR
	movlw	_TagDb
	movwf	EEDATA
	call		WriteEepromByte

	return


;******************************************************************************

FindTagInDb
	global	FindTagInDb

	banksel	EEADR
	movlw	_TagDb
	movwf	EEADR

CompareTagDataToTagDbRecord
	; Compare first byte of record
	call		ReadEepromByte
	banksel	EEDATA
	movfw	EEDATA

	banksel	_TagData
	xorwf	_TagData + .0, w
	bnz		AdvanceToNextRecord

	; Second byte
	banksel	EEADR
	incf		EEADR, f
	call		ReadEepromByte
	banksel	EEDATA
	movfw	EEDATA

	banksel	_TagData
	xorwf	_TagData + .1, w
	bz		MatchThirdByte
	banksel	EEADR	; Roll back to begining of record
	decf		EEADR, f
	goto		AdvanceToNextRecord

MatchThirdByte
	banksel	EEADR
	incf		EEADR, f
	call		ReadEepromByte
	banksel	EEDATA
	movfw	EEDATA

	banksel	_TagData
	xorwf	_TagData + .2, w
	bz		MatchFound
	banksel	EEADR	; Roll back to begining of record
	decf		EEADR, f
	decf		EEADR, f

AdvanceToNextRecord
	banksel	EEADR
	; If all records in db were tried, give up
	movlw	_LastAddrInTagDb - .2
	xorwf	EEADR, w
	bz		NoMatchFound

	; If there are more records to try, advance
	incf		EEADR, f
	incf		EEADR, f
	incf		EEADR, f

	goto		CompareTagDataToTagDbRecord	

NoMatchFound
	bcf		STATUS, C
	return

MatchFound
	; Roll back EEADR to point to the begining of the record
	banksel	EEADR
	decf		EEADR, f
	decf		EEADR, f

	bsf		STATUS, C
	return


;******************************************************************************

AddTagToDb
	global	AddTagToDb

	; Get the next record pointer in the tag DB
	banksel	EEADR
	movlw	_NextRecord
	movwf	EEADR
	call		ReadEepromByte

	banksel	EEDATA
	movfw	EEDATA
	movwf	EEADR

	; Write first tag data byte
	banksel	_TagData
	movfw	_TagData

	banksel	EEDATA
	movwf	EEDATA
	call		WriteEepromByte

	; Secong byte
	banksel	_TagData
	movfw	_TagData + .1

	banksel	EEDATA
	incf		EEADR, f
	movwf	EEDATA
	call		WriteEepromByte

	; Third and last byte
	banksel	_TagData
	movfw	_TagData + .2

	banksel	EEDATA
	incf		EEADR, f
	movwf	EEDATA
	call		WriteEepromByte

	; Update the next record pointer
	banksel	EEADR
	movlw	_LastAddrInTagDb
	xorwf	EEADR, w
	bnz		AdvanceNextRecordPointer ; If next record pointer != _LastAddrInTagDb
	 movlw	_TagDb
	 movwf	EEADR
	 goto	SaveNextRecordPointer
AdvanceNextRecordPointer
	incf		EEADR, f

SaveNextRecordPointer
	movfw	EEADR
	movwf	EEDATA
	movlw	_NextRecord
	movwf	EEADR
	call		WriteEepromByte

	return

	end