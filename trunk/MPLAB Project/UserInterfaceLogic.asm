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

EnterNormalOperation
	global	EnterNormalOperation

	bcf		InAdminMode
	call		OnNormalOperation

	call		WaitForTagAndReadRawData
	call		ExtractTagDataFromRawData
	bnc		EnterNormalOperation

	call		FindTagInDb
	bc		TagAuthorized
	goto		TagNotAuthorized
	
TagAuthorized
	call		SendAuthSignal
	call		OnTagAuthorized
	call		Delay3sec
	goto		EnterNormalOperation

TagNotAuthorized
	call		OnTagNotAuthorized
	call		Delay3sec
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

	call		FindTagInDb
	bnc		AuthorizeTag
	goto		DeauthorizeTag

AuthorizeTag
	call		AddTagToDb
	call		OnAuthorizeTag
	call		Delay3sec
	goto		EnterAdminMode

DeauthorizeTag
	call		RemoveTagFromDb
	call		OnDeauthorizeTag
	call		Delay3sec
	goto		EnterAdminMode

	return


;******************************************************************************

Delay3sec
			;5999992 cycles
	movlw	0x35
	movwf	Temp1
	movlw	0x15
	movwf	Temp2
	movlw	0x0E
	movwf	Temp3
Delay3sec_0
	decfsz	Temp1, f
	goto	$+2
	decfsz	Temp2, f
	goto	$+2
	decfsz	Temp3, f
	goto	Delay3sec_0

			;4 cycles
	goto	$+1
	goto	$+1

			;4 cycles (including call)
	return


	end