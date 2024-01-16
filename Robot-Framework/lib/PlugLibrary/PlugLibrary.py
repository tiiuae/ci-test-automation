# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import asyncio
from KasaPlug import KasaPlug
from TapoP100 import TapoP100
from TapoP100v2 import TapoP100v2
from robot.libraries.BuiltIn import BuiltIn
import json
import os


class PlugLibrary:
    def __init__(self):
        self._plug = None
        self._config = "../../config/test_config.json"
        self._plug_type = self._get_plug_type()

    def _get_plug_type(self):
        device_name = BuiltIn().get_variable_value("${DEVICE}")
        current_file_path = os.path.abspath(__file__)
        current_dir_path = os.path.dirname(current_file_path)
        config_file_path = os.path.join(current_dir_path, self._config)
        with open(config_file_path, 'r') as file:
            config = json.load(file)
        plug_type = config['addresses'][device_name]['plug_type']
        return plug_type

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
