usbhub3p_CLI.py
========================


General Overview:
-----------------
Demonstrates how you can create a command line interface (CLI) via python to execise the USBHub3p.
The example was written explicity for the USBHub3p but is easily modifiable for all BrainStem devices.

The example takes a "enable" and "port" argument which it will then execute setPortEnable/setPortDisable
on the given port.B


Example Usage:
-----------------
Disable Port 1 via Python 3
python3 usbhub3p_CLI.py -p 1 -e 0

Enable Port 1 via Python 3
python3 usbhub3p_CLI.py -p 1 -e 1

Disable Port 7 via Python 2
python2 usbhub3p_CLI.py -p 7 -e 0

Enable Port 7 via Python 2
python2 usbhub3p_CLI.py -p 7 -e 1


How to Run:
-----------
To run this example follow the instructions enumerated in the BrainStem python documentation.