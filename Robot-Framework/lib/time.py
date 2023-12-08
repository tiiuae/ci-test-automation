from datetime import datetime, timedelta
import pytz
import re

def parse_time_info(output):
    local_time_pattern = r"Local time: (.+)"
    rtc_time_pattern = r"RTC time: (.+)"
    time_zone_pattern = r"Time zone: .*\((.+),"

    local_time_match = re.search(local_time_pattern, output)
    rtc_time_match = re.search(rtc_time_pattern, output)
    time_zone_match = re.search(time_zone_pattern, output)

    local_time = local_time_match.group(1) if local_time_match else None
    rtc_time = rtc_time_match.group(1) if rtc_time_match else None
    time_zone = time_zone_match.group(1) if time_zone_match else None

    return local_time, rtc_time, time_zone

def get_current_time(timezone="Asia/Dubai"):
    tz = pytz.timezone(timezone)
    current_time = datetime.now(tz)
    time_string = current_time.strftime("%a %Y-%m-%d %H:%M:%S %z")

    return time_string

def parse_time_string(time_string):
    """Parse the time string into a datetime object."""
    # Assuming the format is like "Fri 2023-12-08 15:38:58 +04"
    format = "%a %Y-%m-%d %H:%M:%S %z"
    return datetime.strptime(time_string, format)

def is_time_close(time_string1, time_string2, tolerance_seconds=10):
    """Check if two time strings are close within a tolerance in seconds."""
    # Parse the time strings into datetime objects
    time1 = parse_time_string(time_string1)
    time2 = parse_time_string(time_string2)

    # Calculate the difference
    time_diff = abs(time1 - time2)

    # Check if the difference is within the tolerance
    return time_diff <= timedelta(seconds=tolerance_seconds)

def convert_to_timezone(input_time_str, output_timezone_str):
    # Parsing the input time string (assumed to be in UTC)
    input_format = "%d/%m/%y %H:%M:%S"
    input_time = datetime.strptime(input_time_str, input_format)

    # Setting the timezone to UTC
    utc_time = pytz.utc.localize(input_time)

    # Converting to the desired timezone
    output_timezone = pytz.timezone(output_timezone_str)
    output_time = utc_time.astimezone(output_timezone)

    # Formatting the output time string
    output_format = "%a %Y-%m-%d %H:%M:%S %z"
    return output_time.strftime(output_format)