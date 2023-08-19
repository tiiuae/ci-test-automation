# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import asyncio
from kasa import SmartPlug
from robot.libraries.BuiltIn import BuiltIn


class KasaPlug:
    def _get_plug_address(self, *args, **kwargs):
        return BuiltIn().get_variable_value("${SOCKET_IP_ADDRESS}")

    def turn_plug_on(self):
        plug = SmartPlug(self._get_plug_address())
        asyncio.run(plug.turn_on())

    def turn_plug_off(self):
        plug = SmartPlug(self._get_plug_address())
        asyncio.run(plug.turn_off())
