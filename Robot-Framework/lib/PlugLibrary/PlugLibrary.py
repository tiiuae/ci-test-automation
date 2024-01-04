# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import asyncio
from KasaPlug import KasaPlug
from TapoP100 import TapoP100
from TapoP100v2 import TapoP100v2
from robot.libraries.BuiltIn import BuiltIn


class PlugLibrary:
    def __init__(self, plug_type, *args, **kwargs):
        self._plug = None
        self._plug_type = plug_type

    def _get_plug(self):
        if not self._plug:
            # Setting self._plug for the first time
            if self._plug_type == "TAPOP100":
                self._plug = TapoP100()
            elif self._plug_type == "KASAPLUG":
                self._plug = KasaPlug()
            elif self._plug_type == "TAPOP100v2":
                self._plug = TapoP100v2()
            else:
                raise Exception('Unknown plug type or there is no plug for this device')
        print(f"plug type: {self._plug_type}")
        return self._plug

    def turn_plug_on(self):
        if self._plug_type == "TAPOP100v2":
            asyncio.run(self._get_plug().turn_plug_on())
        else:
            self._get_plug().turn_plug_on()

    def turn_plug_off(self):
        if self._plug_type == "TAPOP100v2":
            asyncio.run(self._get_plug().turn_plug_off())
        else:
            self._get_plug().turn_plug_off()
