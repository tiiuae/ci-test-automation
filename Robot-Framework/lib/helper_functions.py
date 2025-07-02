# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

from robot.libraries.BuiltIn import BuiltIn

def set_variable_by_name(name, value):
    var_name = '${' + name + '}'
    BuiltIn().set_global_variable(var_name, value)
