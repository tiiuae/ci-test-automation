# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

from KasaPlug import KasaPlug
from TapoP100 import TapoP100
from robot.libraries.BuiltIn import BuiltIn


# PlugLibrary Usage:
# * Tapo Plug:
#   -v PLUG_TYPE:TAPOP100 (default, needs SOCKET_IP_ADDRESS, PLUG_USERNAME and
#                          PLUG_PASSWORD)
# * Kasa Plug:
#   -v PLUG_TYPE:KASAPLUG (needs only SOCKET_IP_ADDRESS)
#
class PlugLibrary:
    def __init__(self, *args, **kwargs):
        self._plug = None

    def _get_plug(self):
        if not self._plug:
            # Setting self._plug for the first time
            plug_type = self._get_plug_type()
            if plug_type == "TAPOP100":
                self._plug = TapoP100()
            elif plug_type == "KASAPLUG":
                self._plug = KasaPlug()
        return self._plug

    # Return TAPOP100 if PLUG_TYPE is not known
    def _get_plug_type(self):
        allowed_types = ["TAPOP100", "KASAPLUG"]
        raw = BuiltIn().get_variable_value("${PLUG_TYPE}")
        if raw in allowed_types:
            return raw
        else:
            # By default use TAPOP100
            return allowed_types[0]

    def turn_plug_on(self):
        self._get_plug().turn_plug_on()

    def turn_plug_off(self):
        self._get_plug().turn_plug_off()
