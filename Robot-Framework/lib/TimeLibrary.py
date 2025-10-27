# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

from datetime import datetime, timedelta
from dateutil import parser
import pytz
import re


def parse_time_info(output):
    local_time_pattern = r"Local time: (.+)"
    universal_time_pattern = r"Universal time: (.+)"
    rtc_time_pattern = r"RTC time: (.+)"
    time_zone_pattern = r"Time zone: .*\((.+),"
    is_sync_pattern = r"synchronized: (\w+)"

    local_time_match = re.search(local_time_pattern, output)
    universal_time_match = re.search(universal_time_pattern, output)
    rtc_time_match = re.search(rtc_time_pattern, output)
    time_zone_match = re.search(time_zone_pattern, output)
    is_sync_match = re.search(is_sync_pattern, output)

    local_time = local_time_match.group(1) if local_time_match else None
    universal_time = universal_time_match.group(1) if universal_time_match else None
    rtc_time = rtc_time_match.group(1) if rtc_time_match else None
    time_zone = time_zone_match.group(1) if time_zone_match else None

    result = is_sync_match.group(1) if is_sync_match else None
    is_synchronized = True if result == "yes" else False if result == "no" else None

    return local_time, universal_time, rtc_time, time_zone, is_synchronized


def get_current_time(timezone="UTC"):
    tz = pytz.timezone(timezone)
    current_time = datetime.now(tz)
    time_string = current_time.strftime("%a %Y-%m-%d %H:%M:%S") + f" {timezone}"

    return time_string


def parse_time_string(time_string, timezone='UTC'):
    """Parse the time string into a datetime object."""
    # Assuming the format is like "Fri 2023-12-08 15:38:58 UTC"
    format = f"%a %Y-%m-%d %H:%M:%S {timezone}"
    return datetime.strptime(time_string, format)


def is_time_close(time_string1, time_string2, tolerance_seconds=10):
    """Check if two time strings are close within a tolerance in seconds."""

    time1 = parse_time_string(time_string1)
    time2 = parse_time_string(time_string2)
    time_diff = abs(time1 - time2)

    return time_diff <= timedelta(seconds=tolerance_seconds)


def convert_to_utc(time_string):
    parsed_time = parser.parse(time_string)
    utc_time = parsed_time.astimezone(pytz.utc)
    utc_time_string = utc_time.strftime("%a %Y-%m-%d %H:%M:%S UTC")
    return utc_time_string


def extract_timezone(output):
    time_zone_pattern = r"Time zone:\s+([^\s]+)"
    time_zone_match = re.search(time_zone_pattern, output)
    time_zone = time_zone_match.group(1) if time_zone_match else None
    return time_zone