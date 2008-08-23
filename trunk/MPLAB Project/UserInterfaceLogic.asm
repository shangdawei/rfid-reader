	#include <p16f88.inc>
	#include <RfidReader.inc>
	extern	WaitForTagAndReadRawData
	extern	ExtractTagDataFromRawData
	extern	FindTagInDb
	extern	AddTagToDb
	extern	RemoveTagFromDb
	extern	_TagData


ButtonPort	equ	PORTB
ButtonTris	equ	TRISB
ButtonPin		equ	.0
#define	Button	ButtonPort, ButtonPin

RedLedPort	equ	PORTA
RedLedTris	equ	TRISA
RedLedPin	equ	.7
#define	RedLed	RedLedPort, RedLedPin

GreenLedPort	equ	PORTA
GreenLedTris	equ	TRISA
GreenLedPin	equ	.6
#define	GreenLed	GreenLedPort, GreenLedPin

SpeakerPort	equ	PORTA
SpeakerTris	equ	TRISA
SpeakerPin	equ	.0
#define	Speaker	SpeakerPort, SpeakerPin

AuthSignalPort equ	PORTA
AuthSignalTris	equ	TRISA
AuthSignalPin	equ	.3
#define	AuthSignal	AuthSignalPort, AuthSignalPin


LastTag		udata_shr
LastTag		res	.3
LastTagAge	res	.1


UserInterfaceLogic	code


;******************************************************************************

UiLogicSetup
	global 	UiLogicSetup
	
	call		ClearLastTag

	; Setup port direction
	banksel	TRISA
	bsf		ButtonTris, ButtonPin
	bcf		RedLedTris, RedLedPin
	bcf		GreenLedTris, GreenLedPin
	bcf		SpeakerTris, SpeakerPin
	bcf		AuthSignalTris, AuthSignalPin
	clrf		ANSEL

	; Setup button interrupt, used to switch modes
	bsf		INTCON, INTE	; INT0IE bit

	; Setup TMR1 interrupt, used to clear the recently scanned tag
	banksel	PIE1
	bsf		PIE1, TMR1IE

	banksel	T1CON
	movlw	b'00110000'	; Initially off
	movwf	T1CON
	
	; Enable interrupts
	bsf		INTCON, PEIE
	bsf		INTCON, GIE

	return


;******************************************************************************

OnNormalOperation

	banksel	PORTA
	bcf		RedLed
	bcf		GreenLed
	bcf		Speaker
	bcf		AuthSignal

	return


;******************************************************************************

OnAdminMode

	banksel	PORTA
	bsf		RedLed
	bsf		GreenLed
	bcf		Speaker
	bcf		AuthSignal

	return


;******************************************************************************

OnTagAuthorized
	return


;******************************************************************************

OnTagNotAuthorized
	return


;******************************************************************************

OnAuthorizeTag
	return


;******************************************************************************

OnDeauthorizeTag
	return


;******************************************************************************

SendAuthSignal
	; Send a 10 ms pulse on AuthSignal

	banksel	PORTA
	bsf		AuthSignal	
	
	; Delay 10 ms
	movlw	0x9F
	movwf	Temp1
	movlw	0x10
	movwf	Temp2
Delay_0
	decfsz	Temp1, f
	goto	$+2
	decfsz	Temp2, f
	goto	Delay_0
	goto	$+1

	bcf		AuthSignal

	return


;******************************************************************************

CheckLastTagAge
	global	CheckLastTagAge

	incf		LastTagAge, f
	movlw	.50 			; 50 * ((2^16 bits in timer) / 8e6 herts / 8 prescaler) = ~3.2 sec
	xorwf	LastTagAge, w
	skpz
	return		
	
	call ClearLastTag
	banksel	T1CON
	bcf		T1CON, TMR1ON	

	return


;******************************************************************************

ClearLastTag
	
	clrf		LastTagAge
	movlw	0xFF
	movwf	LastTag		; 0xFF
	clrf		LastTag + .1	; 0x00
	movwf	LastTag + .2	; 0xFF

	return


;******************************************************************************

ScannedTagIsLastTag

	; A tag was recently scanned, start age timer
	banksel	T1CON
	bsf		T1CON, TMR1ON
	
	movfw	LastTag
	xorwf	_TagData, w
	bnz		UpdateLastTag
	
	movfw	LastTag + .1
	xorwf	_TagData + .1, w
	bnz		UpdateLastTag

	movfw	LastTag + .2
	xorwf	_TagData + .2, w
	bnz		UpdateLastTag

	goto		LastTagMatch
	
UpdateLastTag
	movfw	_TagData
	movwf	LastTag
	movfw	_TagData + .1
	movwf	LastTag + .1		
	movfw	_TagData + .2
	movwf	LastTag + .2

	bcf		STATUS, C
	return

LastTagMatch
	bsf		STATUS, C
	return


;******************************************************************************

EnterNormalOperation
	global	EnterNormalOperation

	bcf		InAdminMode
	call		OnNormalOperation

	call		WaitForTagAndReadRawData
	call		ExtractTagDataFromRawData
	bnc		EnterNormalOperation

	call		ScannedTagIsLastTag
	bc		EnterNormalOperation	

	call		FindTagInDb
	bc		TagAuthorized
	goto		TagNotAuthorized
	
TagAuthorized
	call		SendAuthSignal
	call		OnTagAuthorized
	goto		EnterNormalOperation

TagNotAuthorized
	call		OnTagNotAuthorized
	goto		EnterNormalOperation

	return


;******************************************************************************

EnterAdminMode
	global	EnterAdminMode

	bsf		InAdminMode
	call		OnAdminMode

	call		WaitForTagAndReadRawData
	call		ExtractTagDataFromRawData
	bnc		EnterAdminMode

	call		ScannedTagIsLastTag
	bc		EnterNormalOperation

	call		FindTagInDb
	bnc		AuthorizeTag
	goto		DeauthorizeTag

AuthorizeTag
	call		AddTagToDb
	call		OnAuthorizeTag
	goto		EnterAdminMode

DeauthorizeTag
	call		RemoveTagFromDb
	call		OnDeauthorizeTag
	goto		EnterAdminMode

	return

	end