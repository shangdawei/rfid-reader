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

	banksel	PORTA
	bsf		GreenLed
	bsf		Speaker
	call		Delay150ms
	bcf		GreenLed	
	bcf		Speaker

	return


;******************************************************************************

OnTagNotAuthorized

	banksel	PORTA
	bsf		RedLed
	bsf		Speaker
	call		Delay150ms
	bcf		RedLed
	bcf		Speaker
	call		Delay150ms
	bsf		RedLed
	bsf		Speaker
	call		Delay150ms
	bcf		RedLed
	bcf		Speaker

	return


;******************************************************************************

OnAuthorizeTag

	banksel	PORTA
	bcf		RedLed
	bcf		GreenLed
	
	bsf		GreenLed
	bsf		Speaker
	call		Delay150ms
	call		Delay150ms
	bcf		GreenLed
	bcf		Speaker

	return


;******************************************************************************

OnDeauthorizeTag

	banksel	PORTA
	bcf		RedLed
	bcf		GreenLed
	
	bsf		RedLed
	bsf		Speaker
	call		Delay150ms
	bcf		RedLed
	bcf		Speaker
	call		Delay150ms
	bsf		RedLed
	bsf		Speaker
	call		Delay150ms
	bcf		RedLed
	bcf		Speaker

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
	call		Delay500ms
	goto		EnterNormalOperation

TagNotAuthorized
	call		OnTagNotAuthorized
	call		Delay500ms
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
	call		Delay500ms
	goto		EnterAdminMode

DeauthorizeTag
	call		RemoveTagFromDb
	call		OnDeauthorizeTag
	call		Delay500ms
	goto		EnterAdminMode

	return


;******************************************************************************


Delay500ms
			;999990 cycles
	movlw	0x07
	movwf	Temp1
	movlw	0x2F
	movwf	Temp2
	movlw	0x03
	movwf	Temp3
Delay500ms_0
	decfsz	Temp1, f
	goto	$+2
	decfsz	Temp2, f
	goto	$+2
	decfsz	Temp3, f
	goto	Delay500ms_0

			;6 cycles
	goto	$+1
	goto	$+1
	goto	$+1

			;4 cycles (including call)
	return


Delay150ms
			;299993 cycles
	movlw	0x5E
	movwf	Temp1
	movlw	0xEB
	movwf	Temp2
Delay150ms_0
	decfsz	Temp1, f
	goto	$+2
	decfsz	Temp2, f
	goto	Delay150ms_0

			;3 cycles
	goto	$+1
	nop

			;4 cycles (including call)
	return


	end