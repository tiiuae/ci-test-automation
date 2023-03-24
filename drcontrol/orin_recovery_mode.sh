#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: Ville-Pekka Juntunen <ville-pekka.juntunen@unikie.com>
# SPDX-FileCopyrightText: 2023 Technology Innovation Institute (TII)
# SPDX-FileCopyrightText: 2023 Unikie

############################################################################################################################

# Script for setting Nvidia Orin to recovy mode with Denkovi relay board
# Script using drcontrol.py for controllin releys to mimic pushing recovery and reset buttons to get device to recovery mode

############################################################################################################################

##### Functions

help(){
    echo "Options:"
    echo ""
    echo "-s, device serial number, example -s DAE005kM"
    echo "-h, Help message for command line options"
    exit 1
}

#############
# Main
#############

# Check is no arguments given
if [ $# -eq 0 ]; then
    help
fi

# Check if more than 2 postitional arguments given
if ! [ -z "$3" ]; then
    help
fi

# Handling optional arguments
while getopts ":hs" opt; do
    case $opt in
       h)  help ;;
       s)  
           if [ -z "$2" ]; then
               help
           fi
           echo "Given serial number: $2";;
      \?)  help ;;
      
    esac
done

# "push" Orin buttons to get device on recovery mode using drcontrol.py script
python3 drcontrol.py -d $2 -r 1 -c on
sleep 3
python3 drcontrol.py -d $2 -r 2 -c on
sleep 3
python3 drcontrol.py -d $2 -r 2 -c off
sleep 1
python3 drcontrol.py -d $2 -r 1 -c off
sleep 3

# Check that device is on recovery mode
output=$(lsusb | grep "NVIDIA Corp. APX")
if [[ $output == *"NVIDIA Corp. APX"* ]]; then
    echo "Orin is on recovery mode!"
else
    echo "Orin is not on recovery mode!" ; exit 1
fi
