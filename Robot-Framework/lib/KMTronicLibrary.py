# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import serial
import time
from robot.libraries.BuiltIn import BuiltIn

class KMTronicLibrary:
    """
    Robot Framework Library for controlling KMTronic USB relays.
    """

    def __init__(self, port):
        """Initialize the serial connection"""
        self.ser = serial.Serial(
            port=port,  # Port to which the device is connected
            baudrate=9600,  # Baud rate
            bytesize=serial.EIGHTBITS,  # Number of data bits
            parity=serial.PARITY_NONE,  # No parity
            stopbits=serial.STOPBITS_ONE,  # One stop bit
            timeout=1  # Timeout for reading data
        )
        if self.ser.is_open:
            print(f"Connection established successfully on port {port}.")
        else:
            raise RuntimeError(f"Failed to open connection on port {port}")

    def close_relay_board_connection(self):
        """
        Close the serial connection.
        """
        if self.ser and self.ser.is_open:
            self.ser.close()
            self.ser = None
            print("Connection closed.")
        else:
            print("Connection is already closed.")

    def _check_connection(self):
        """
        Internal method to check if the serial connection is open.
        Raises an exception if the connection is not open.
        """
        if self.ser is None:
            raise RuntimeError("Serial connection is not initialized. Call 'open_connection' first.")
        if not self.ser.is_open:
            raise RuntimeError("Serial connection is not open. Call 'open_connection' first.")
        print("Serial connection is open and ready.")

    def set_relay_state(self, relay_number, state):
        """
        Set the state of a specific relay.

        :param relay_number: Relay number (1-4).
        :param state: Desired state ("ON" or "OFF").
        """
        self._check_connection()

        # Ensure relay_number is an integer
        try:
            relay_number = int(relay_number)
        except ValueError:
            raise ValueError(f"Invalid relay number: {relay_number}. Must be an integer.")

        if relay_number < 1 or relay_number > 4:
            raise ValueError("Relay number must be between 1 and 4.")

        if state not in ["ON", "OFF"]:
            raise ValueError("State must be 'ON' or 'OFF'.")

        # Send the command to the specific relay
        command = bytearray.fromhex('FF') + bytearray([relay_number]) + (b'\x01' if state == "ON" else b'\x00')
        self.ser.write(command)
        time.sleep(0.1)  # Wait for the command to process
        print(f"Relay {relay_number} set to {state}.")
        BuiltIn().log_to_console(f"Relay {relay_number} set to {state}.")

    def get_relay_state(self, relay_number):
        """
        Get the state of a specific relay.

        :param relay_number: Relay number (1-4).
        :return: "ON" if the relay is ON, otherwise "OFF".
        """
        self._check_connection()

        # Ensure relay_number is an integer
        try:
            relay_number = int(relay_number)
        except ValueError:
            raise ValueError(f"Invalid relay number: {relay_number}. Must be an integer.")

        if relay_number < 1 or relay_number > 4:
            raise ValueError("Relay number must be between 1 and 4.")

        # Send status command
        self.ser.write(bytearray.fromhex('FF0900'))
        time.sleep(0.1)  # Wait for response

        # Read response (4 bytes, one byte per relay)
        response = self.ser.read(4)

        if len(response) != 4:
            raise RuntimeError("Invalid response length received.")

        # Decode the state of the specified relay
        relay_state = response[relay_number - 1]
        return "ON" if relay_state == 1 else "OFF"
