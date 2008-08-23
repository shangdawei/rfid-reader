	#include <p16f88.inc>
	#include <RfidReader.inc>
	extern	_TagData

	errorLevel	-302


TagDbEepromVars 	org	0x2100
_NextRecord		de	.1

; _LastAddrInTagDb - _TagDb  MUST be divisible by three
_TagDb			equ	0x01
_LastAddrInTagDb	equ	0xFC


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

	; Search only if the db is not empty
	banksel	EEADR
	movlw	_NextRecord
	movwf	EEADR
	call		ReadEepromByte
	banksel	EEDATA
	movfw	EEDATA	; Backup the next record poiter
	movwf	Temp1
	movlw	_TagDb	; Is the db empty?
	xorwf	EEDATA, f
	bz		NoMatchFound

	; Otherwise search starting with first record
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
	movfw	Temp1	; Contains the backup of next record pointer
	xorwf	EEADR, w
	bz		NoMatchFound 	; If EEADR == next record pointer

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

	call		FindTagInDb
	bc		RecordAlreadyExists

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

RecordAlreadyExists
	return


;******************************************************************************

RemoveTagFromDb
	global 	RemoveTagFromDb
	
	call		FindTagInDb
	bnc		TagRemoved
	; EEADR contains the tag record pointer
		
ShiftNextDbByte
	banksel	EEADR

	movlw	_LastAddrInTagDb - .2
	xorwf	EEADR, w
	bz		UpdateNextRecordPointer

	incf		EEADR, f
	incf		EEADR, f
	incf		EEADR, f
	call		ReadEepromByte
	banksel	EEADR
	decf		EEADR, f
	decf		EEADR, f
	decf		EEADR, f
	call		WriteEepromByte
	banksel	EEADR
	incf		EEADR, f

	goto		ShiftNextDbByte

UpdateNextRecordPointer		
	; Decrement the next record pointer
	banksel	EEADR
	movlw	_NextRecord
	movwf	EEADR
	call		ReadEepromByte
	banksel	EEDATA
	decf		EEDATA, f
	decf		EEDATA, f
	decf		EEDATA, f
	call		WriteEepromByte

TagRemoved
	return

	end