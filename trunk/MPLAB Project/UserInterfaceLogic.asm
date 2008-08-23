	#include <p16f88.inc>
	#include <RfidReader.inc>
	extern	WaitForTagAndReadRawData
	extern	ExtractTagDataFromRawData
	extern	FindTagInDb
	extern	AddTagToDb
	extern	RemoveTagFromDb


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


UserInterfaceLogic	code


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

UiSetup
	; Setup port direction
	banksel	TRISA
	bsf		ButtonTris, ButtonPin
	bcf		RedLedTris, RedLedPin
	bcf		GreenLedTris, GreenLedPin
	bcf		SpeakerTris, SpeakerPin
	bcf		AuthSignalTris, AuthSignalPin
	clrf		ANSEL
	
	btfsc	InAdminMode
	 goto	SetupForAdminMode

	; Normal operation
	banksel	PORTA
	bcf		RedLed
	bcf		GreenLed
	bcf		Speaker
	bcf		AuthSignal
	goto		SetupButtonInterrupt

SetupForAdminMode
	banksel	PORTA
	bsf		RedLed
	bsf		GreenLed
	bcf		Speaker
	bcf		AuthSignal

SetupButtonInterrupt
	bsf		INTCON, INTE	; INT0IE bit
	bsf		INTCON, GIE

	return

;******************************************************************************

EnterNormalOperation
	global	EnterNormalOperation

	bcf		InAdminMode
	call		UiSetup

NormalOperation
	call		WaitForTagAndReadRawData
	call		ExtractTagDataFromRawData
	bnc		NormalOperation

	call		FindTagInDb
	bc		TagAuthorized
	goto		TagNotAuthorized
	
TagAuthorized
	call		OnTagAuthorized
	goto		NormalOperation

TagNotAuthorized
	call		OnTagNotAuthorized
	goto		NormalOperation

	return


;******************************************************************************

EnterAdminMode
	global	EnterAdminMode

	bsf		InAdminMode
	call		UiSetup

AdminMode
	call		WaitForTagAndReadRawData
	call		ExtractTagDataFromRawData
	bnc		AdminMode

	call		FindTagInDb
	bc		AuthorizeTag
	goto		DeauthorizeTag

AuthorizeTag
	call		AddTagToDb
	call		OnAuthorizeTag
	goto		AdminMode

DeauthorizeTag
	call		RemoveTagFromDb
	call		OnDeauthorizeTag
	goto		DeauthorizeTag

	return

	end