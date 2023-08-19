# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import asyncio
from kasa import SmartPlug
from robot.libraries.BuiltIn import BuiltIn


def get_plug_address():
    return BuiltIn().get_variable_value("${SOCKET_IP_ADDRESS}")


def turn_plug_on():
    plug = SmartPlug(get_plug_address())
    asyncio.run(plug.turn_on())


def turn_plug_off():
    plug = SmartPlug(get_plug_address())
    asyncio.run(plug.turn_off())
