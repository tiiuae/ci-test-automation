# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import asyncio
from KasaPlug import KasaPlug
from TapoP100 import TapoP100
from TapoP100v2 import TapoP100v2
from robot.libraries.BuiltIn import BuiltIn


# PlugLibrary Usage:
# * Tapo Plug:
#   -v PLUG_TYPE:TAPOP100 (default, needs SOCKET_IP_ADDRESS, PLUG_USERNAME and
#                          PLUG_PASSWORD)
# * Kasa Plug:
#   -v PLUG_TYPE:KASAPLUG (needs only SOCKET_IP_ADDRESS)
#
# * Tapo Plug Hardware Version 2.0:
#   -v PLUG_TYPE:TAPOP100v2 (needs only SOCKET_IP_ADDRESS)
#
class PlugLibrary:
    def __init__(self, *args, **kwargs):
        self._plug = None
        self._plug_type = "TAPOP100"

    def _get_plug(self):
        if not self._plug:
            # Setting self._plug for the first time
            self._plug_type = self._get_plug_type()
            if self._plug_type == "TAPOP100":
                self._plug = TapoP100()
            elif self._plug_type == "KASAPLUG":
                self._plug = KasaPlug()
            elif self._plug_type == "TAPOP100v2":
                self._plug = TapoP100v2()
        print(f"plug type: {self._plug_type}")
        return self._plug

    # Return TAPOP100 if PLUG_TYPE is not known
    def _get_plug_type(self):
        allowed_types = ["TAPOP100", "KASAPLUG", "TAPOP100v2"]
        raw = BuiltIn().get_variable_value("${PLUG_TYPE}")
        if raw in allowed_types:
            return raw
        else:
            # By default use TAPOP100
            return allowed_types[0]

    def turn_plug_on(self):
        if self._plug_type == "TAPOP100v2":
            asyncio.run(self._get_plug().turn_plug_on())
        else:
            self._get_plug().turn_plug_on()

    def turn_plug_off(self):
        if self._get_plug_type() == "TAPOP100v2":
            asyncio.run(self._get_plug().turn_plug_off())
        else:
            self._get_plug().turn_plug_off()
