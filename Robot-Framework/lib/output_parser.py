# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import re
from datetime import datetime


def get_systemctl_status(output):
    output = re.sub(r'\033\[.*?m', '', output)   # remove colors from serial console output
    match = re.search(r'State: (\w+)', output)

    if match:
        return match.group(1)
    else:
        raise Exception("Couldn't parse systemctl status")

def get_service_status(output):
    output = re.sub(r'\033\[.*?m', '', output)   # remove colors from serial console output
    match = re.search(r'Active: (\w+) \((\w+)', output)

    if match:
        return match.group(1), match.group(2)
    else:
        raise Exception("Couldn't parse systemctl status")


def find_pid(output, proc_name):
    output = output.split('\n')
    pids = [line.split()[1] for line in output if proc_name in line]
    return pids

def verify_shutdown_status(output):
    output = re.sub(r'\033\[.*?m', '', output)   # remove colors from serial console output
    match = re.search(r'ExecStop=.*\(code=(\w+), status=(.*)\)', output)
    if match:
        return match.group(1), match.group(2)
    else:
        raise Exception("Couldn't parse shutdown status")

def parse_version(output):
    versions = output.split(' ')
    name = versions[1][1:-1] if len(versions) > 1 else None
    major, minor, date, commit = versions[0].split(".")
    return major, minor, date, commit, name

def verify_date_format(date_string):
    try:
        datetime.strptime(date_string, '%Y%m%d')
    except ValueError:
        raise Exception("Wrong date format in version date field")
