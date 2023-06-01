brainstem2_signal.py
=========================

General Overview:
-----------------
This examples creates a signal loopback using a MTMUSBStem. It creates a square wave using the Digital pins and the Signal interface, which is the interface which allows those pins to produce square waves. The characteristics of the square wave are defined by setting T3 and T2 times on the Signal interface. That square wave is output from one Digital pin and then read in by another Digital pin. Lastly, the Duty Cycle of the square wave produced is calculated using the T3 and T2 times read from the input Signal interface.

It should be noted that while there are presets for the pins, the interfaces, the T3 time, and the T2 time, they are configurable by the user.

How to Run:
-----------
To run this example follow the instructions enumerated in the BrainStem python documentation.