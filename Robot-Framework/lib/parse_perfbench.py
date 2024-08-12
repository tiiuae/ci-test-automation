# SPDX-FileCopyrightText: 2022-2024 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import os
import csv
import json
from robot.api.deco import keyword

# How many columns are reserved for information extracted from the file name
build_info_size = 1

def list_files(path):
    file_list = []
    for path, subdirs, files in os.walk(path):
        for name in files:
            if name.find("perf_results") != -1 and name.find("csv") == -1:
                file_list.append(os.path.join(path, name))

    # The file creation time may differ from actual build date.
    # Let's sort according to file name (perf_results_YYYY-MM-DD_BuildMachine-BuildID) simply in ascending order.
    ordered_file_list = sorted(file_list)

    return ordered_file_list


def extract_value(file, detect_str, offset, str1, str2):

    with open(file, 'r') as f:

        # read all lines using readline()
        lines = f.readlines()

        row_index = 0
        match_index = -1

        for row in lines:
            # find() method returns -1 if the value is not found,
            # if found it returns index of the first occurrence of the substring
            if row.find(detect_str) != -1:
                match_index = row_index
            row_index += 1

        if match_index < 0:
            print("Error in extracting '{}': Result value not found.".format(detect_str))
            return ''

        line = lines[match_index + offset]
        res = ''

        try:
            # getting index of substrings
            idx1 = line.index(str1)
            idx2 = line.index(str2)

            # getting elements in between
            for idx in range(idx1 + len(str1), idx2):
                res = res + line[idx]
            res = float(res)
            return res
        except:
            print("Error in extracting '{}': Result value not found.".format(detect_str))
            return res



def save_to_csv(build, path_to_data, file, config, csv_file_name):

    results = [build]
    with open(path_to_data + "/" + csv_file_name, 'a') as f:
        writer_object = csv.writer(f)
        for i in range(len(config)):
            results.append(
                extract_value(file, config[i][0], config[i][1], config[i][2], config[i][3])
            )
        writer_object.writerow(results)
        f.close()


def create_csv_file(path_to_data, config, csv_file_name):

    header = []
    for i in range(len(config)):
        header.append(config[i][0])

    with open(path_to_data + "/" + csv_file_name, 'w') as f:
        writer = csv.writer(f, delimiter=',', lineterminator='\n')
        writer.writerow(header)
        f.close()


def parse_perfbench_data(build, device, path_to_data):

    # Dictionary defining locations where to extract each result value.
    parse_config = [
        ('sched/pipe', 5, ' ', 'usecs/op'),
        ('syscall/basic', 4, ' ', 'usecs/op'),
        ('mem/memcpy', 4, ' ', 'MB/sec'),
        ('mem/memset', 4, ' ', 'MB/sec'),
        ('numa-mem', 8, ' ', ' GB/sec/thread'),
        ('futex/hash', 8, 'Averaged', ' operations/sec'),
        ('futex/wake ', 13, 'threads in ', ' ms '),
        ('futex/wake-parallel', 13, '(waking 1/4 threads) in ', ' ms '),
        ('futex/requeue', 13, 'threads in ', ' ms '),
        ('futex/lock-pi', 8, 'Averaged ', ' operations/sec'),
        ('epoll/wait', 7, 'Averaged ', ' operations/sec'),
        ('ADD operations', 0, 'Averaged ', ' ADD operations'),
        ('MOD operations', 0, 'Averaged ', ' MOD operations'),
        ('DEL operations', 0, 'Averaged ', ' DEL operations'),
        ('internals/synthesize', 5, 'time per event ', ' usec'),
        ('internals/kallsyms-parse', 1, 'took: ', ' ms ')
    ]

    # Separate config for the test 'mem/find_bit' which has multiple output values.
    find_bit_parse_config = []
    bits = 1
    while bits < 2050:
        bits_set = 1
        while bits_set < bits + 1:
            find_bit_parse_config.append(
                ('{} bits set of {} bits'.format(bits_set, bits), 1, 'Average for_each_set_bit took:', ' usec (+-')
            )
            bits_set *= 2
        bits *= 2

    print("Extracting " + str(len(find_bit_parse_config)) + " separate results from find bit tests.")
    print("Extracting " + str(len(parse_config)) + " separate results from other tests.")


    file_list = list_files(os.getcwd())
    print("Going to extract result values from these files: ")
    print(file_list)

    perf_results = ["build_numbers"]
    for i in range(len(parse_config)):
        perf_results.append(parse_config[i][0])

    perf_bit_results = ["build_numbers"]
    for i in range(len(find_bit_parse_config)):
        perf_bit_results.append(find_bit_parse_config[i][0])

    file_index = 0
    for f in file_list:
        save_to_csv(build, path_to_data, f, parse_config, device + "_perf_results.csv")
        save_to_csv(build, path_to_data, f, find_bit_parse_config, device + "_perf_find_bit_results.csv")
        file_index += 1
    return perf_results, perf_bit_results

@keyword("Convert Output To Json")
def convert_output_to_json(output):
    """Convert given output to json format
    """
    json_output = json.loads(output)
    json.dumps(json_output)
    return(json_output)
