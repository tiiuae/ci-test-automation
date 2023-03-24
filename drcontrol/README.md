# drcontrol
Python drcontrol forked from https://code.google.com/p/drcontrol/

DRControl is Python script that controls the USB Relay board from Denkovi http://www.denkovi.com.

## Requirements
- Python 2.6+
- Tested on Raspberry Pi with Python 2.6
- Tested on Mac OSX 10.8.2 with Python 2.7.2
- Tested on Ubuntu 12.04 Desktop (via VMWare)
- Denkovi 4 USB Relay Board, product code DAE-CB/Ro4-USB

## Notes
The DRControl will always show all 8 relays even if the connected board is an 4 USB Relay Board. There is no way at the current time to identify if the board is 4 or 8 USB Relay Board.

## drcontrol.py

### Options
| Option |           Description           |
|:------:|:--------------------------------|
|   -d   | Device                          |
|   -r   | Relay Number                    |
|   -s   | Relay State                     |
|   -l   | List all available FTDI Devices |
|   -v   | Verbose                         |

### Device (-d)

`option -d <device serial number>`

Address the relay board with the serial number of the FTDI device, this can be listed with the "-l" (list) switch.

Example below is two devices listed, the "FT245R USB FIFO" is the relay board (4 x USB Board) which is then used the serial "A6VV5PHY" to show the state of the relay 1.

```
$ ./drcontrol.py -l Vendor Product Serial RFXCOM RFXtrx433 03VHG0NE FTDI FT245R USB FIFO A6VV5PHY 
$ ./drcontrol.py -d A6VV5PHY -r 1 -c state ON 
$
```
### Relay (-r)

`option -r <1..8|all>`

Needed in to address which relay is going to be commanded.

"ALL" can be used to send the command to all relays. Command is not case sensitive.

Example
```
$ ./drcontrol.py -d A6VV5PHY -r ALL -c state -v 
DRControl 0.12 
Device: A6VV5PHY 
Send command: Relay all (0xFF) to STATE 
Relay 1 state: ON (2) 
Relay 2 state: ON (8) 
Relay 3 state: ON (32) 
Relay 4 state: ON (128) 
Relay 5 state: ON (4) 
Relay 6 state: ON (16) 
Relay 7 state: ON (64) 
$
```
### Relay Command (-c)

`option -c <on|off|state>`

Options: on, off, state

ON = To set the relay ON

OFF = To set the relay OFF

STATE = To show the current state of the relay

Command is not case sensitive

Example
```
$ ./drcontrol.py -d A6VV5PHY -r 1 -c state ON $ ./drcontrol.py -d A6VV5PHY -r 1 -c off 
$ ./drcontrol.py -d A6VV5PHY -r 1 -c state OFF
$ ./drcontrol.py -d A6VV5PHY -r 1 -c on $ ./drcontrol.py -d A6VV5PHY -r 1 -c state ON 
$
```

### List devices (-l)

option -l

List all FTDI devices on the system.

Example
```
$ ./drcontrol.py -l Vendor Product Serial RFXCOM RFXtrx433 03VHG0NE FTDI FT245R USB FIFO A6VV5PHY 
$
```

### Verbose (-v)

`option -v`

Give verbose printouts of all commands.

Example
```
$ ./drcontrol.py -d A6VV5PHY -r 1 -c state -v 
DRControl 0.11 
Device: A6VV5PHY 
Send command: Relay 1 (0x2) to STATE 
Relay 1 state: ON (2) 
$ ./drcontrol.py -d A6VV5PHY -r 1 -c off -v 
DRControl 0.11 
Device: A6VV5PHY 
Send command: Relay 1 (0x2) to OFF 
Relay 1 to OFF 
$ ./drcontrol.py -d A6VV5PHY -r 1 -c state -v 
DRControl 0.11 
Device: A6VV5PHY 
Send command: Relay 1 (0x2) to STATE 
Relay 1 state: OFF (0) 
$
```
## Info

The USB 4 relay board is a product from Denkovi Assembly Electronics ltd

## Copyright

Copyright (C) 2012 Sebastian Sjoholm
