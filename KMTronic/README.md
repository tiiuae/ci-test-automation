<!--
    Copyright 2022-2025 TII (SSRC) and the Ghaf contributors
    SPDX-License-Identifier: CC-BY-SA-4.0
-->

# KMTronic relay board

USB controlled relay board to control test devices power suply.

### Relay control script

To control 4 channel KMtronic relay board use kmtronic_4ch_control.py. Board serial port is needed to given as argument and ON/OFF argument.
Relay number argument is needed if want to control ONLY that specified relay. Otherwise ALL relays is set ON/OFF.

Examples:

    $ python kmtronic_4ch_control.py /dev/ttyUSB0 OFF
    All relays set to OFF.

    $ python kmtronic_4ch_control.py /dev/ttyUSB0 ON 2
    Relay 2 set to ON.

### Relay status script

To get 4 channel KMtronic relay board status use kmtronic_4ch_status.py. Board serial port is needed to given as argument.
Status request return status of all relays.

Example:

    $ python kmtronic_4ch_status.py /dev/ttyUSB0
    Relay 1: OFF
    Relay 2: ON
    Relay 3: OFF
    Relay 4: OFF
