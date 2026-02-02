# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

from robot.libraries.BuiltIn import BuiltIn

def set_variable_by_name(name, value):
    var_name = '${' + name + '}'
    BuiltIn().set_global_variable(var_name, value)

def count_lines(output):
    lines = [line for line in output.splitlines()]
    return len(lines)

def get_matching_lines(output, match):
    return [line for line in output.splitlines() if match in line]
