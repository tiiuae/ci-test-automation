===============================================================================
BrainStem Linux Driverless
===============================================================================

You must run udev.sh located in the "BrainStem_linux_Driverless" folder 
once prior to connecting to your BrainStem module. By default users do not have 
permissions to connect to BrainStem devices, udev.sh places a rule in the udev 
rules folder granting access to users in group dialout, and adds the current 
user to the dialout rules. Running the script requires sudo access, alternatively 
running the two commands separately from the root user command line will work as 
well replacing $user with the user on your system. Restart the machine when this 
is complete.

===============================================================================
If you have questions, please see the reference, or check out our guides
at www.acroname.com.
