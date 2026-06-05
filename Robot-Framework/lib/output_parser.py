# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import json
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
    
def get_service_state(output):
    match = re.search(r'^ActiveState=(\w+)', output, re.MULTILINE)
    if match:
        return match.group(1)
    raise Exception(f"Couldn't parse ActiveState from systemctl show output")

def get_service_substate(output):
    match = re.search(r'^SubState=(\w+)', output, re.MULTILINE)
    if match:
        return match.group(1)
    raise Exception(f"Couldn't parse SubState from systemctl show output")


def verify_shutdown_status(output):
    output = re.sub(r'\033\[.*?m', '', output)   # remove colors from serial console output
    match = re.search(r'ExecStop=.*\(code=(\w+), status=(.*)\)', output)
    if match:
        return match.group(1), match.group(2)
    else:
        raise Exception("Couldn't parse shutdown status")


def parse_ghaf_version(output):
    major, minor = output.split(".")
    return major, minor


def parse_nixos_version(output):
    versions = output.split(' ')
    name = versions[1][1:-1] if len(versions) > 1 else None
    major, minor, date, commit = versions[0].split(".")
    return major, minor, date, commit, name


def verify_date_format(date_string):
    try:
        datetime.strptime(date_string, '%Y%m%d')
    except ValueError:
        raise Exception("Wrong date format in version date field")


def parse_cpu_results(output):
    def extract_value(pattern, output):
        match = re.search(pattern, output)
        if match:
            return match.group(1)
        else:
            raise Exception(f"Couldn't parse result of the test with pattern: {pattern}")

    output = re.sub(r'\033\[.*?m', '', output)  # remove colors from serial console output

    cpu_events_per_second = extract_value(r'events per second:\s*([.\d]+)', output)
    min_latency = extract_value(r'min:\s+([.\d]+)', output)
    max_latency = extract_value(r'max:\s+([.\d]+)', output)
    avg_latency = extract_value(r'avg:\s+([.\d]+)', output)
    cpu_events_per_thread = extract_value(r'events \(avg\/stddev\):\s+([.\d]+)', output)
    cpu_events_per_thread_stddev = extract_value(r'events \(avg\/stddev\):\s+[.\d]+\/([.\d]+)', output)

    cpu_data = {
        'cpu_events_per_second': cpu_events_per_second,
        'min_latency': min_latency,
        'max_latency': max_latency,
        'avg_latency': avg_latency,
        'cpu_events_per_thread': cpu_events_per_thread,
        'cpu_events_per_thread_stddev': cpu_events_per_thread_stddev
    }

    return cpu_data


def parse_memory_results(output):
    def extract_value(pattern, output):
        match = re.search(pattern, output)
        if match:
            return match.group(1)
        else:
            raise Exception(f"Couldn't parse result of the test with pattern: {pattern}")

    output = re.sub(r'\033\[.*?m', '', output)  # remove colors from serial console output

    operations_per_second = extract_value(r'Total operations:\s*\d+ \(([.\d]+) per second', output)
    data_transfer_speed = extract_value(r'\(([.\d]+) MiB\/sec\)', output)
    min_latency = extract_value(r'min:\s+([.\d]+)', output)
    max_latency = extract_value(r'max:\s+([.\d]+)', output)
    avg_latency = extract_value(r'avg:\s+([.\d]+)', output)
    avg_events_per_thread = extract_value(r'events \(avg\/stddev\):\s+([.\d]+)', output)
    events_per_thread_stddev = extract_value(r'events \(avg\/stddev\):\s+[.\d]+\/([.\d]+)', output)

    mem_data = {
        'operations_per_second': operations_per_second,
        'data_transfer_speed': data_transfer_speed,
        'min_latency': min_latency,
        'max_latency': max_latency,
        'avg_latency': avg_latency,
        'avg_events_per_thread': avg_events_per_thread,
        'events_per_thread_stddev': events_per_thread_stddev
    }

    return mem_data


def parse_fileio_read_results(output):
    def extract_value(pattern, output):
        match = re.search(pattern, output)
        if match:
            return match.group(1)
        else:
            raise Exception(f"Couldn't parse result of the test with pattern: {pattern}")

    output = re.sub(r'\033\[.*?m', '', output)  # remove colors from serial console output

    file_operations = extract_value(r'File operations:\s*reads\/s:\s*([.\d]+)', output)
    throughput = extract_value(r'Throughput:\s*read, MiB\/s:\s*([.\d]+)', output)
    min_latency = extract_value(r'min:\s+([.\d]+)', output)
    max_latency = extract_value(r'max:\s+([.\d]+)', output)
    avg_latency = extract_value(r'avg:\s+([.\d]+)', output)
    avg_events_per_thread = extract_value(r'events \(avg\/stddev\):\s+([.\d]+)', output)
    events_per_thread_stddev = extract_value(r'events \(avg\/stddev\):\s+[.\d]+\/([.\d]+)', output)

    fileio_read_data = {
        'file_operations': file_operations,
        'throughput': throughput,
        'min_latency': min_latency,
        'max_latency': max_latency,
        'avg_latency': avg_latency,
        'avg_events_per_thread': avg_events_per_thread,
        'events_per_thread_stddev': events_per_thread_stddev
    }

    return fileio_read_data


def parse_fileio_write_results(output):
    def extract_value(pattern, output):
        match = re.search(pattern, output)
        if match:
            return match.group(1)
        else:
            raise Exception(f"Couldn't parse result of the test with pattern: {pattern}")

    output = re.sub(r'\033\[.*?m', '', output)  # remove colors from serial console output

    file_operations = extract_value(r'writes\/s:\s*([.\d]+)', output)
    throughput = extract_value(r'written, MiB\/s:\s*([.\d]+)', output)
    min_latency = extract_value(r'min:\s+([.\d]+)', output)
    max_latency = extract_value(r'max:\s+([.\d]+)', output)
    avg_latency = extract_value(r'avg:\s+([.\d]+)', output)
    avg_events_per_thread = extract_value(r'events \(avg\/stddev\):\s+([.\d]+)', output)
    events_per_thread_stddev = extract_value(r'events \(avg\/stddev\):\s+[.\d]+\/([.\d]+)', output)

    fileio_write_data = {
        'file_operations': file_operations,
        'throughput': throughput,
        'min_latency': min_latency,
        'max_latency': max_latency,
        'avg_latency': avg_latency,
        'avg_events_per_thread': avg_events_per_thread,
        'events_per_thread_stddev': events_per_thread_stddev
    }

    return fileio_write_data


def _parse_cyclictest_summary_line(output, label):
    # Summary lines look like: "# Max Latencies: 00026 00031 ..."
    match = re.search(rf'^# {label}:\s+(.+)$', output, re.MULTILINE)
    if not match:
        return None
    values = [int(value) for value in re.findall(r'\d+', match.group(1))]
    if not values:
        raise Exception(f"Couldn't parse cyclictest {label.lower()}")
    return values


def parse_cyclictest_results(output):
    # Return cyclictest latencies in milliseconds from the final summary:
    # - absolute minimum across threads
    # - mean of per-thread averages
    # - absolute maximum across threads
    output = re.sub(r'\033\[.*?m', '', output)

    min_values = _parse_cyclictest_summary_line(output, 'Min Latencies')
    avg_values = _parse_cyclictest_summary_line(output, 'Avg Latencies')
    max_values = _parse_cyclictest_summary_line(output, 'Max Latencies')

    if not (min_values and avg_values and max_values):
        raise Exception("Couldn't parse cyclictest results")

    return {
        'min_latency_ms': min(min_values) / 1000.0,
        'avg_latency_ms': sum(avg_values) / len(avg_values) / 1000.0,
        'max_latency_ms': max(max_values) / 1000.0,
    }


def parse_cyclictest_histogram(output):
    output = re.sub(r'\033\[.*?m', '', output)
    histogram_started = False
    buckets_us = []
    counts = []

    for line in output.splitlines():
        stripped = line.strip()
        if stripped == '# Histogram':
            histogram_started = True
            continue
        if not histogram_started:
            continue
        if stripped.startswith('# Total:'):
            break
        if not stripped or stripped.startswith('#'):
            continue

        parts = stripped.split()
        if len(parts) < 2 or not all(part.isdigit() for part in parts):
            continue

        buckets_us.append(int(parts[0]))
        counts.append(sum(int(part) for part in parts[1:]))

    if not buckets_us:
        raise Exception("Couldn't parse cyclictest histogram")

    return {
        'buckets_us': buckets_us,
        'counts': counts,
    }


def parse_cyclictest_histogram_overflows(output):
    output = re.sub(r'\033\[.*?m', '', output)
    overflow_counts = []
    overflow_cycles = {}

    # Example: "# Histogram Overflows: 00000 00002 00001"
    match = re.search(r'^# Histogram Overflows:\s+(.+)$', output, re.MULTILINE)
    if match:
        overflow_counts = [int(value) for value in re.findall(r'\d+', match.group(1))]

    in_cycle_section = False
    for line in output.splitlines():
        stripped = line.strip()
        if stripped == '# Histogram Overflow at cycle number:':
            in_cycle_section = True
            continue
        if not in_cycle_section:
            continue

        # Example: "# Thread 2: 12345 23456"
        thread_match = re.match(r'^# Thread\s+(\d+):\s*(.*)$', stripped)
        if not thread_match:
            continue

        thread_id = int(thread_match.group(1))
        overflow_cycles[thread_id] = [
            int(value) for value in re.findall(r'\d+', thread_match.group(2))
        ]

    return {
        'counts_per_thread': overflow_counts,
        'total_count': sum(overflow_counts),
        'cycles_per_thread': overflow_cycles,
    }


def parse_cyclictest_spikes(output):
    output = re.sub(r'\033\[.*?m', '', output)
    spikes = []
    # Example: "T: 5 Spike:     424: TS:   6433102503"
    spike_pattern = re.compile(
        r'^T:\s*(\d+)\s+Spike:\s*(\d+):\s+TS:\s*(\d+)$',
        re.MULTILINE,
    )

    for match in spike_pattern.finditer(output):
        spikes.append({
            'thread': int(match.group(1)),
            'latency_us': int(match.group(2)),
            'timestamp': int(match.group(3)),
        })

    return spikes


def parse_cyclictest_spike_count(output):
    output = re.sub(r'\033\[.*?m', '', output)
    # Prefer the explicit summary count when available: "spikes = 9"
    match = re.search(r'^spikes\s*=\s*(\d+)$', output, re.MULTILINE)
    if match:
        return int(match.group(1))
    return len(parse_cyclictest_spikes(output))


def parse_iperf_output(output):
    tx_pattern = r'\s(\d+(\.\d+)?) MBytes\/sec.*sender'
    rx_pattern = r'\s(\d+(\.\d+)?) MBytes\/sec.*receiver'

    match = re.search(tx_pattern, output)
    if match:
        tx = match.group(1)
    else:
        raise Exception(f"Couldn't parse TX, pattern: {tx_pattern}")

    match = re.search(rx_pattern, output)
    if match:
        rx = match.group(1)
    else:
        raise Exception(f"Couldn't parse RX, pattern: {rx_pattern}")

    return {
        "tx": tx,
        "rx": rx
    }


def get_ip_from_ifconfig(output, if_name):
    pattern = if_name + r'.*?\n.*?inet addr:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'
    match = re.search(pattern, output)
    if match:
        return match.group(1)
    else:
        print(f"Couldn't find ip with pattern {pattern}")
        return None


def get_qspi_versions(output):
    fw_pattern = r"Current firmware version is\s*: (\d*.\d*.\d*)"
    sw_pattern = r"Expected firmware version is: (\d*.\d*.\d*)"

    match = re.search(fw_pattern, output)
    if match:
        fw_version = match.group(1)
    else:
        raise Exception(f"Couldn't parse current firmware version, pattern: {fw_pattern}")

    match = re.search(sw_pattern, output)
    if match:
        sw_version = match.group(1)
    else:
        raise Exception(f"Couldn't parse current software version, pattern: {sw_pattern}")

    return fw_version, sw_version

def get_failed_units(output):
    pattern = re.compile(r"^\s*●?\s*([\w@.-]+\.service)\b", re.MULTILINE)
    services = pattern.findall(output)
    return services

def parse_services_to_list(output):
    match = re.search(r"\[([^\]]+)\]", output)
    if not match:
        print("No list of failed services found in the output.")
        return []
    raw_items = match.group(1).split(',')
    parsed_list = [item.strip(" '\"") for item in raw_items if item.strip()]
    return parsed_list

def parse_known_issue(output):
    parts = output.split('|')
    if len(parts) != 4:
        raise ValueError(f"Invalid known issue format: {output}")
    return parts[0].strip(), parts[1].strip(), parts[2].strip(), parts[3].strip()

def parse_keyboard_layout(layout_row):
    if not "layout" in layout_row:
        return False
    current_layout = layout_row.split("\"")[1].split(",")
    for i in range(len(current_layout)):
        if current_layout[i] == "us":
            # Return the current order of layouts and the placement of 'us' in the list
            return [current_layout, i]
    return False

def extract_device_hint(text):
    pattern = r'Device name \[e\.g\. ([^\]]+)\]:'
    match = re.search(pattern, text)
    if match:
        return match.group(1)
    else:
        raise Exception("Could not extract device name from input text")

def get_kill_switch_status(status_list, device):
    # Parse the status list into a dictionary
    statuses = {}
    for line in status_list.splitlines():
        if ":" in line:
            key, value = line.split(":", 1)
            statuses[key.strip()] = value.strip()
    return statuses.get(device)
    
def clean_login_output(output):
    if not output:
        return ""
    clean_output = re.sub(r'\x1B\[[0-?]*[ -/]*[@-~]', '', output)
    clean_output = clean_output.strip().splitlines()[-1]
    return clean_output

def get_cpu_thread_count(output):
    threads_per_core = int(re.search(r"Thread\(s\) per core:\s+(\d+)", output).group(1))
    cores_per_socket = int(re.search(r"Core\(s\) per socket:\s+(\d+)", output).group(1))

    return threads_per_core * cores_per_socket

def get_monitor_microphone_source(output):
    for line in output.splitlines():
        if "monitor" in line:
            match = re.match(r"(\d+)", line)
            if match:
                return int(match.group(1))
    raise ValueError("Monitor microphone source not found")

def extract_mean_volume(output):
    match = re.search(r"mean_volume:\s*([-\d.]+)\s*dB", output)
    if not match:
        raise ValueError("mean_volume not found in ffmpeg output")
    return float(match.group(1))

def get_audio_duration_in_seconds(output):
    if re.search(r"Duration:\s*N/A", output):
        return 0
    match = re.search(r"Duration:\s*(\d+):(\d+):(\d+\.\d+)", output)
    if not match:
        raise RuntimeError("Could not determine duration")
    hours, minutes, seconds = match.groups()
    return int(hours) * 3600 + int(minutes) * 60 + float(seconds)

def remove_colors(output):
    return re.sub(r'\033\[.*?m', '', output)   # remove colors from console output

def get_source_ip_for_route(route_output):
    # Parse `ip route get` output and return the source IP used for the route.
    match = re.search(r'\bsrc\s+([0-9a-fA-F:.]+)', route_output)
    if match:
        return match.group(1)
    raise Exception("Couldn't parse source IP from route output")

def get_backing_disk_from_lsblk(lsblk_output):
    devices = json.loads(lsblk_output).get("blockdevices", [])
    while devices:
        device = devices[0]
        if device["type"] == "disk":
            return device["name"]
        devices = device.get("children") or []

    raise Exception("Couldn't find backing disk in lsblk output")
