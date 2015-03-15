# User Interface Specification #


### Turning the reader On/Off: ###

  * Turning the reader On:
    1. User turns the reader on using a power switch
    1. The power led lights up and a tone is sounded
    1. The reader goes into normal operation
  * The reader can be abruptly turned off at any point, by any means


### Normal operation: ###

  1. User may take any of the following actions:
    * User scans a tag by placing it over the antenna:
      1. If the tag is authorized, the green indicator blinks and a tone is sounded, once
      1. If the tag is not authorized, the red indicator blinks and a tone is sounded, twice
    * User presses the "Add/Remove Tag" button:
      1. The reader goes into the "Administrative mode"
  1. The reader goes back to "Normal operation"


### Administrative mode: ###

  1. Light up both the green and the red indicators
  1. User may take any of the following actions:
    * For any action:
      1. Turn off both the green and the red indicators
    * User scans a tag by placing it over the antenna:
      * If the tag is not authorized:
        1. The tag is added to the list of authorized tags
        1. The green indicator blinks and a tone is sounded, twice
      * If the tag is authorized:
        1. The tag is removed ftom the list of authorized tags
        1. The red indicator blinks and a tone is sounded, twice
    * The user presses the "Add/Remove Tag" button:
      1. Go back to "Normal operation"

### Resseting the reader: ###

  * User holds the "Add/Remove Tag" button while the reader is being turned on
    1. Reset the reader to factory defaults, clearing the list of authorized tags