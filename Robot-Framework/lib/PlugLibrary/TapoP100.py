# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

from PyP100 import PyP100
from robot.libraries.BuiltIn import BuiltIn


class TapoP100:
    def __init__(self, *args, **kwargs):
        self._p100 = None

    def _get_p100(self):
        if not self._p100:
            ip_address = BuiltIn().get_variable_value("${SOCKET_IP_ADDRESS}")
            username = BuiltIn().get_variable_value("${PLUG_USERNAME}")
            password = BuiltIn().get_variable_value("${PLUG_PASSWORD}")
            self._p100 = PyP100.P100(
                ip_address, username, password
            )  # Creating a P100 plug object
            self._p100.handshake()  # Creates the cookies required for further methods
            self._p100.login()  # Sends credentials to the plug and creates AES Key and IV for further methods
        return self._p100

    def turn_plug_on(self):
        self._get_p100().turnOn()  # Sends the turn on request

    def turn_plug_off(self):
        self._get_p100().turnOff()  # Sends the turn off request

    def get_plug_info(self):
        return self._get_p100().getDeviceInfo()  # Returns dict with all the device info
