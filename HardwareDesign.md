
---

### RFID Reader Basics ###

The RFID reader continuously transmits a 125 kHz carrier signal using its antenna. The passive RFID tag, embedded in an id card for example, powers on from the carrier signal. Once powered on, the tag transmits, back to the reader, an FSK encoded signal containing the data stored on the card. The FSK signal is a 125 kHz carrier, with 12.5 kHz as the mark frequency, and a 15.625 kHz as the space frequency. The encoded signal is picked up by the reader's antenna, filtered, and processed on the embedded microcontroller to extract the tag's unique identity. At this point the identity can be matched against the records stored on the reader.


---

### Top Level Design ###

From the functional description we can extract the basic tasks that a reader must perform:

  * Continuously transmit a 125 kHz sinusoidal signal using the antenna
  * Receive and filter the signal returning from the tag
  * Extract the digital data from the processed signal
  * Authenticate the tag using stored records

![http://rfid-reader.googlecode.com/svn/wiki/images/TopLevelDesign.png](http://rfid-reader.googlecode.com/svn/wiki/images/TopLevelDesign.png)



---

### Schematic Diagram ###

Let's start peeling off the layers of abstraction.

Following is our schematic implementation of the proposed top level design. Notice that every block on the schematic corresponds to a block in the top level design.

![![](http://rfid-reader.googlecode.com/svn/wiki/images/SchematicThumbnail.png)](http://rfid-reader.googlecode.com/svn/wiki/images/Schematic.png)



---

### Clock Generator ###

The clock generator serves a single purpose. It generates a low level 125 kHz square wave for use by the transmitting circuit within the antenna module.

Note that the Microcontroller does not need a clock source as it is using the internal clock of the chip.



---

### Antenna Module ###

The antenna module takes a 125 kHz square wave input, buffers it, using three shunted inverting gates, and converts it into a 125 kHz sinusoidal wave using the RLC circuit immediately following the buffers. The resulting wave is amplified, using a push pull amplifier, forming the carrier signal, and fed into an antenna that transmits the carrier continuously toward any RFID tag position above it.

The same antenna is used to capture the FSK encoded waveform returning from the tag. This resulting waveform, or simply the 125 kHz carrier, if no tag is present, is available as an output from the antena module.

_Note that this is the only stage requiring a 12V supply_



---

### Filtering Module ###

The filtering module's main purpose is to filter out the carrier signal and any noise that was picked up by the antenna.

To get rid of any high frequency interference and the 125 kHz carrier, which contains no data, we apply an envelope detector. The resulting waveform is a sinusoidal waveform of varrying frequency (ie. varrying period, if you prefer), with the variation representing our data.

From the previous stage we still have some low frequency and traces of high frequency interference in our signal. To get rid of both we pass the signal through two active bandpass filters, one at our mark frequency of 12.5 kHz, and one at our space frequency of 15.625 kHz. At this point we have a fairly clean signal at either the mark or the space frequency and minimal noise. The signal is still sinusoidal.

_Refer to the Microchip RFID Guide for some illustrations of this process._



---

### Microcontroller ###

We use a PIC 16F88 chip as the microcontroller.

The chip does not need an external clock source as it is using one of the internal oscillator to generate its clock.

The resistors are used to set the reference level for an internal comparator used to process the output of the filtering stage. The comparator is formed by the reference voltage at RA2 and the output of the filtering module at RA1.

The microcontroller processes the signal coming from the filtering module to extract the bits and decode them into usable data as per HID H10301 format, which is being used by the DuoProx II id cards. The hardware here is not very interesting. Most of the work is done in software on the chip. Read more about the chip and its function [here](TheMicrocontroller.md).