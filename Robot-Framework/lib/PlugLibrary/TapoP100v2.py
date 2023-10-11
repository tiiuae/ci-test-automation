# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

from robot.libraries.BuiltIn import BuiltIn
from plugp100.api.tapo_client import TapoClient
from plugp100.common.credentials import AuthCredential
from plugp100.api.plug_device import PlugDevice


class TapoP100v2:

    def __init__(self):
        self._p100 = None

    async def _get_p100(self):
        ip_address = BuiltIn().get_variable_value("${SOCKET_IP_ADDRESS}")
        username = BuiltIn().get_variable_value("${PLUG_USERNAME}")
        password = BuiltIn().get_variable_value("${PLUG_PASSWORD}")
        credentials = AuthCredential(username, password)

        tapo_client = TapoClient(credentials, ip_address)
        await tapo_client.initialize()
        self._p100 = PlugDevice(tapo_client)

        return self._p100

    async def turn_plug_on(self):
        p100 = await self._get_p100()
        await p100.on()
        print("Smart plug turned ON")

    async def turn_plug_off(self):
        p100 = await self._get_p100()
        await p100.off()
        print("Smart plug turned OFF")
