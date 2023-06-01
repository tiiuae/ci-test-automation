===============================================================================
BrainStem 2.2 Reflex Example Readme
===============================================================================

This is a basic blink LED reflex example for the BrainStem 2.0 library. When run,
the reflex will blink the User LED on the BrainStem module 5 times and exit.
To compile and load the Blink_LED reflex, you must follow the steps outlined below.

Notes:
===============================================================================

1. First compile the reflex into a map file using the arc compiler. 
	bin>arc.exe Blink_LED.reflex	
	
	Acroname Reflex Compiler (arc)
	version 1.0, build 0
	Copyright 1994-2015, Acroname Inc.

	compiled to 97 bytes in Blink_LED.map	

2. Load the Blink_LED.map file into slot 0 of the Internal store on the BrainStem 
   device with serial number 0xXXXXXXXX.

	bin>ReflexLoader.exe -L -d 0xXXXXXXXX -i Blink_LED.reflex INTERNAL 0
	ReflexLoader [Version: 1.0 Apr 11 2016 16:27:51]
	[BrainStem Release: 2.2.4]
	[Copyright (C) 2016, Acroname Inc.]

	load slot	
		

3. Enable the reflex in the slot.

	bin>ReflexLoader.exe -E -d 0x40F5849A INTERNAL 0
	
	ReflexLoader [Version: 1.0 Apr 11 2016 16:27:51]
	[BrainStem Release: 2.2.4]
	[Copyright (C) 2016, Acroname Inc.]

	enable slot

	PROCESSING ENABLE
	Slot 0 has been enabled
	ReflexLoader [Version: 1.0 Apr 11 2016 16:27:51]
	[BrainStem Release: 2.2.4]
	[Copyright (C) 2016, Acroname Inc.]


a. If you need to find your serial number.

	bin>Updater.exe -D 
	Updater.exe [Version: 1.0 Mar 16 2016 13:50:28] [BrainStem Release:2.2.2] 
        [Copyright (C) 1994-2016, Acroname Inc.]

	Discovering Devices [USB]:
    		Device    Module   Router  Model               Firmware Version
    		XXXXXXXX  02       02      04 [USBStem     ]   2.2.4 (0)

	Discovering Devices [TCPIP]:
   		Device    Module   Router  Model               Firmware Version   [IP address]

	Completed processing: Updater [Version: 1.0 Mar 16 2016 13:50:28] 
	[BrainStem Release:2.2.2] [Copyright (C) 1994-2016, Acroname Inc.]

b. For full information about the ReflexLoader's capabilities.

	bin>ReflexLoader.exe -H


If you have questions, please see the reference, or check out our guides 
at www.acroname.com.

