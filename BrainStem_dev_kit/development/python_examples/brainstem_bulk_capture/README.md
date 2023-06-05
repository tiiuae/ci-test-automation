brainstem_bulk_capture.py
=========================

General Overview:
-----------------
This script captures 8,000 analog voltage samples at a sample rate of 200,000 samples per second (Hertz) on Analog channel 0, using an MTMUSBStem. Since the bulk capture channel, number of samples, and sample rate are user configurable, the script prints out these values before performing the bulk capture. After the bulk capture has occurred the script prints out a list of all the samples. Each sample has its own line, and displays the sample number, the voltage calculated from each sample's two bytes of data, and the raw data from each sample's two bytes of data.

How to Run:
-----------
To run this example follow the instructions enumerated in the BrainStem python documentation.