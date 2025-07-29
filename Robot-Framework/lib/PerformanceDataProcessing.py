# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import csv
import os
import shutil
import pandas
import json
import matplotlib.pyplot as plt
import logging
from robot.api.deco import keyword
from performance_thresholds import *
import parse_perfbench


class PerformanceDataProcessing:

    def __init__(self, device, build_number, commit, job, perf_data_dir, config_path, plot_dir, low_limit):
        self.device = device
        self.build_number = build_number
        self.commit = commit[:6]
        self.perf_data_dir = perf_data_dir
        self.config_path = config_path
        self.plot_dir = plot_dir
        self.data_dir = self._create_result_dirs()
        self.build_type = job.split(".")[0]
        self.zero_result_flag = -100
        self.low_limit = float(low_limit)

    def _get_job_name(self):
        if self.config_path != "None":
            f = open(self.config_path + f"/{self.build_number}.json")
            data = json.load(f)
            job_name = data["Job"]
        else:
            job_name = "dummy_job"
        return job_name

    def _create_result_dirs(self):
        job = self._get_job_name()
        data_dir = self.perf_data_dir + f"{job}/"
        logging.info(f"Creating {data_dir}")
        os.makedirs(data_dir, exist_ok=True)
        statistics_dir = f"{data_dir}statistics"
        os.makedirs(statistics_dir, exist_ok=True)
        if self.plot_dir != "./":
            logging.info(f"Creating {self.plot_dir}")
            os.makedirs(self.plot_dir, exist_ok=True)
        return data_dir

    @keyword
    def get_data_dir(self):
        return self.data_dir

    def _write_to_csv(self, test_name, data):
        file_path = os.path.join(self.data_dir, f"{self.device}_{test_name}.csv")
        logging.info(f"Writing data to {file_path}")
        with open(file_path, 'a', newline='') as csvfile:
            csvwriter = csv.writer(csvfile)
            csvwriter.writerow(data)

    def _write_statistics_to_csv(self, test_name, data):
        file_path = os.path.join(self.data_dir, f"statistics/{self.device}_{test_name}_statistics.csv")
        logging.info("Updating statistics for {}".format(test_name))
        with open(file_path, 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(data.keys())
            writer.writerows(zip(*(data.values())))

    @keyword("Parse and Copy Perfbench To Csv")
    def parse_and_copy_perfbench_to_csv(self):
        perf_result_heading, perf_bit_result_heading = parse_perfbench.parse_perfbench_data(self.commit, self.device, self.data_dir)
        return perf_result_heading, perf_bit_result_heading

    def write_test_data_to_csv(self, test_name, test_data):
        data = [self.commit]
        for key in test_data:
            data.append(test_data[key])
        data.append(self.device)
        self._write_to_csv(test_name, data)

    def truncate(self, list, significant_figures):
        truncated_list = []
        for item in list:
            truncated_list.append(float(f'{item:.{significant_figures}g}'))
        return truncated_list

    def detect_deviation(self, data_column, baseline_start, threshold, deviations_in_row, deviations=[]):
        # Calculate mean and population standard deviation of the results
        # Check if last value changes more than threshold from
        #   last "normal" measurement result
        #   mean of measurement results since baseline_start, omitting deviated results
        #   first value of the last stable baseline period

        flag = 0
        baseline_end = 0
        last_measurement = data_column[-1]

        if deviations_in_row < self.zero_result_flag + 1:
            deviations_in_row = 0

        # Slice the list since baseline_start for mean and std calculations
        data_column_cut = data_column[baseline_start:-1]

        if len(data_column_cut) - len(deviations) > 0:

            # Pick the deviations from data_column and calculate their sum
            sum_deviations = sum([data_column[i] for i in deviations])

            # Calculate mean, omitting the values which are labeled deviations
            mean = (sum(data_column_cut) - sum_deviations) / (len(data_column_cut) - len(deviations))

            # Calculate (custom) standard deviation, omitting the values which are too low and potential current row of deviations (potential new baseline).
            # Cannot omit all deviations here. Otherwise there wouldn't be any real variation for std.
            # Find also the last non-deviated measurement result.
            data_sum = 0
            baseline_values = 0
            for i in range(baseline_start, len(data_column) - 1 - abs(deviations_in_row)):
                if not data_column[i] < self.low_limit:
                    baseline_values += 1
                    data_sum = (data_column[i] - mean) ** 2 + data_sum
                    baseline_end = i
            if baseline_values > 0:
                pstd = (data_sum / baseline_values) ** (1 / 2)
            else:
                pstd = 0

            if type(threshold) == str:
                # In case of relative threshold (string type including '%' character) calculate the absolute threshold as percentage from mean value
                if "%" in threshold:
                    threshold_float = mean * float(threshold[:-1]) / 100
                # Threshold given as multiple of standard deviations
                elif "std" in threshold:
                    threshold_float = pstd * float(threshold[:-3])
                    # In certain situations standard deviation can get out of control and grow wildly leading to useless threshold (even greater than mean value)
                    # Limit threshold to 1/3 of the mean value at maximum
                    if threshold_float > mean / 3:
                        threshold_float = mean / 3
                else:
                    logging.info("Incorrect threshold format: ")
                    logging.info(threshold)
                    return
                threshold = self.truncate([threshold_float], 3)[0]

                # If there is not yet enough measurement history mean and std values might be forced to 0.
                # In such case set threshold so that test passes
                if threshold < 0.001:
                   threshold = last_measurement

            d = [0, 0]

            # Monitor deviation from the mean of the last "stable" baseline period
            d[0] = last_measurement - mean

            # Deviation from the first measurement of the baseline period,
            # For simplicity this deviation is not anymore used as another pass/fail criteria.
            # So slow monotonic change will pass. However, the deviation will still be logged.
            d[1] = last_measurement - data_column[baseline_start]

            # Flag indicating significant change in performance value
            flag = 0

            # Check if performance has either decreased or increased significantly
            if d[0] < -threshold:
                flag = -1

            if d[0] > threshold:
                flag = 1

            upper_marginal = mean + threshold
            lower_marginal = mean - threshold

            if lower_marginal < self.low_limit:
                lower_marginal = self.low_limit

            stats = self.truncate([mean, pstd] + d + [data_column[baseline_end], data_column[baseline_start], upper_marginal, lower_marginal], 5)

        else:
            stats = [0] * 8
            stats[0] = last_measurement
            stats[4] = last_measurement
            stats[5] = last_measurement
            stats[6] = 2 * last_measurement
            stats[7] = 0

        if last_measurement < self.low_limit:
            flag = self.zero_result_flag

        statistics_dict = {
            'flag': flag,
            'threshold': threshold,
            'd_baseline_start': stats[3],
            'd_mean': stats[2],
            'baseline_start': stats[5],
            'baseline_mean': stats[0],
            'baseline_end': stats[4],
            'baseline_std': stats[1],
            'upper_marginal': stats[6],
            'lower_marginal': stats[7],
            'measurement': last_measurement
        }

        return statistics_dict

    def calculate_statistics(self, test_name, data, monitored_value, threshold):
        # monitored_value: list of labels
        # threshold: dictionary or list of single value

        # For function return
        new_statistics_row = None

        # All statistics of all monitored values are gathered into this dictionary for csv file output
        statistics = {}

        data_key_list = list(data.keys())
        value_count = len(monitored_value)

        with open(f"{self.data_dir}{self.device}_{test_name}.csv", 'r') as csvfile:
            csvreader = csv.reader(csvfile)
            logging.info("Reading data from csv file...")
            build_counter = {}  # To keep track of duplicate builds

            # Separate deviation counter and baseline for each monitored value
            baseline_start = {}
            for value in monitored_value:
                baseline_start.update({value: 0})
            new_baseline_start = {}
            for value in monitored_value:
                new_baseline_start.update({value: 0})
            deviation_counter = [0] * value_count
            deviations = {}
            for value in monitored_value:
                deviations.update({value: []})

            row_index = 0
            for row in csvreader:
                if row[-1] == self.device:
                    build = str(row[0])
                    if build in build_counter:
                        build_counter[build] += 1
                        modified_build = f"{build}-{build_counter[build]}"
                    else:
                        build_counter[build] = 0
                        modified_build = build
                    data['commit'].append(modified_build)

                    for key_index in range(1, len(row) - 1):
                        data[data_key_list[key_index]].append(float(row[key_index]))

                    new_statistics_row = {}
                    indexed_statistics_row = {}
                    monitored_value_index = 0
                    for value in monitored_value:
                        # Select threshold by value name only if there are multiple thresholds
                        if len(threshold) < 2:
                            select_threshold = 0
                        else:
                            select_threshold = value
                        statistics_block = self.detect_deviation(data[value], baseline_start[value], threshold[select_threshold], deviation_counter[monitored_value_index], deviations[value])

                        # Monitor deviations of monitored_value(s)
                        flag = statistics_block['flag']
                        if flag != 0:

                            # Keep track on deviated results to be able to omit random odd result from baseline
                            deviations[value].append(row_index)
                            if abs(deviation_counter[monitored_value_index]) < 1:
                                # Set potential start for new baseline
                                new_baseline_start[value] = row_index
                            else:
                                # Check if new deviation is to opposite direction than previously
                                if flag * deviation_counter[monitored_value_index] < 0:
                                    deviation_counter[monitored_value_index] = 0
                                    new_baseline_start[value] = row_index

                            # Track of number of successive deviations
                            deviation_counter[monitored_value_index] += flag
                            # Save direction (+/-) and number of successive deviations to statistics
                            statistics_block['flag'] = flag * abs(deviation_counter[monitored_value_index])
                            # Don't change baseline for invalid (zero) results
                            if flag != self.zero_result_flag:
                                # If there is zero label in the deviation_counter from the previous measurements reset deviation_counter to -1
                                if deviation_counter[monitored_value_index] < self.zero_result_flag:
                                    deviation_counter[monitored_value_index] = -1
                                    new_baseline_start[value] = row_index
                                # Trigger baseline change if number of successive deviations exceeds the defined limit
                                if abs(deviation_counter[monitored_value_index]) > thresholds['wait_until_reset'] - 1:
                                    deviation_counter[monitored_value_index] = 0
                                    deviations[value] = []
                                    baseline_start[value] = new_baseline_start[value]
                            else:
                                # Keep the deviation_counter at -1 if the result is zero
                                deviation_counter[monitored_value_index] = -1
                                statistics_block['flag'] = self.zero_result_flag
                        else:
                            deviation_counter[monitored_value_index] = 0

                        new_statistics_row.update({value: statistics_block})

                        # Create indexed statistics row in case of multiple monitored_value
                        indexed_statistics_block = {}
                        for key in list(statistics_block.keys()):
                            if value_count < 2:
                                indexed_key = key
                            else:
                                indexed_key = key + str(monitored_value_index)
                            indexed_statistics_block.update({indexed_key: [statistics_block[key]]})
                        indexed_statistics_row.update(indexed_statistics_block)

                        # Switch baseline_start index to a non-zero measurement result as soon as one is available
                        if data[value][baseline_start[value]] < self.low_limit and data[value][-1] > self.low_limit:
                            deviation_counter[monitored_value_index] = 0
                            deviations[value] = []
                            baseline_start[value] = row_index

                        monitored_value_index += 1

                    if row_index < 1:
                        # On the first loop add the dictionary keys
                        statistics = indexed_statistics_row
                    else:
                        # On the following loops append only lists
                        for key in list(statistics.keys()):
                            statistics[key].append(indexed_statistics_row[key][0])

                    row_index = row_index + 1

        # Write all statistics into csv file
        self._write_statistics_to_csv(test_name,{'commit': data['commit']} | statistics)
        # In case of debugging can have also raw data side by side with statistics:
        # self._write_statistics_to_csv(test_name, data | statistics)

        # Return the statistics of the last measurement
        return new_statistics_row, statistics

    def plot_marginals(self, x_data, statistics, plot_limit, result_index=''):
        for key in statistics.keys():
            statistics[key] = statistics[key][-plot_limit:]
        plt.plot(x_data, statistics['upper_marginal' + result_index], marker='', linestyle='dotted', color='r')
        plt.plot(x_data, statistics['lower_marginal'+ result_index], marker='', linestyle='dotted', color='r')
        return

    @keyword
    def read_cpu_csv_and_plot(self, test_name):
        data = {
            'commit': [],
            'cpu_events_per_second': [],
            'min_latency': [],
            'avg_latency': [],
            'max_latency': [],
            'cpu_events_per_thread': [],
            'cpu_events_per_thread_stddev': []
        }

        # Set threshold for fail depending on test type: single/multi thread
        if "One thread" in test_name or "1thread" in test_name:
            if "NUC" in self.device:
                threshold = thresholds['cpu']['single_nuc']
            else:
               threshold = thresholds['cpu']['single']
        else:
            threshold = thresholds['cpu']['multi']

        return_statistics, statistics = self.calculate_statistics(test_name, data, ['cpu_events_per_second'], [threshold])

        if "VMs" in test_name:
            return return_statistics

        for key in data.keys():
            data[key] = data[key][-40:]

        plt.figure(figsize=(20, 10))
        plt.set_loglevel('WARNING')

        # Plot 1: CPU Events per Second
        plt.subplot(3, 1, 1)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['cpu_events_per_second'], marker='o', linestyle='-', color='b')
        self.plot_marginals(data['commit'], statistics, 40)
        plt.yticks(fontsize=14)
        plt.title(f'CPU Events per Second / Threshold: {threshold}', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('CPU Events per Second', fontsize=16)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=14)

        # Plot 2: CPU Events per Thread
        plt.subplot(3, 1, 2)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['cpu_events_per_thread'], marker='o', linestyle='-', color='b')
        plt.yticks(fontsize=14)
        plt.title('CPU Events per Thread', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('CPU Events per Thread', fontsize=16)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=14)
        # Create line chart with error bars on the same subplot
        plt.errorbar(data['commit'], data['cpu_events_per_thread'],
                     yerr=data['cpu_events_per_thread_stddev'],
                     capsize=4)

        # Plot 3: Latency
        plt.subplot(3, 1, 3)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['avg_latency'], marker='o', linestyle='-', color='b', label='Avg')
        plt.ylabel('Avg Latency (ms)', fontsize=16)
        plt.legend(loc='upper left')
        plt.xlabel('Build Number', fontsize=16)
        plt.xticks(data['commit'], rotation=90, fontsize=14)
        plt.ylabel('Max/Min Latency (ms)', fontsize=16)
        plt.yticks(fontsize=14)
        plt.twinx()
        plt.plot(data['commit'], data['max_latency'], marker='o', linestyle='-', color='r', label='Max')
        plt.plot(data['commit'], data['min_latency'], marker='o', linestyle='-', color='g', label='Min')
        plt.legend(loc='upper right')
        plt.title('Latency', loc='right', fontweight="bold", fontsize=16)
        plt.grid(True)

        plt.suptitle(f'{test_name}\nBuild type: {self.build_type}, Device: {self.device}', fontsize=18, fontweight='bold')

        plt.tight_layout()
        plt.savefig(self.plot_dir + f'{self.device}_{test_name}.png')
        return return_statistics

    @keyword
    def change_dictionary_key(self, dict, key, new_key):
        dict[new_key] = dict[key]
        del dict[key]
        return dict

    @keyword
    def read_mem_csv_and_plot(self, test_name):
        data = {
            'commit': [],
            'operations_per_second': [],
            'data_transfer_speed': [],
            'min_latency': [],
            'avg_latency': [],
            'max_latency': [],
            'avg_events_per_thread': [],
            'events_per_thread_stddev': []
        }

        dictionary_key_name = None
        # Set threshold for fail depending on test type: single/multi thread, write/read
        if "One thread" in test_name or "1thread" in test_name:
            if "rite" in test_name:
                dictionary_key_name = 'write_1thread'
                if "NUC" in self.device:
                    threshold = thresholds['mem']['single']['wr_nuc']
                else:
                    threshold = thresholds['mem']['single']['wr']
            else:
                dictionary_key_name = 'read_1thread'
                if "NUC" in self.device:
                    threshold = thresholds['mem']['single']['rd_nuc']
                else:
                    threshold = thresholds['mem']['single']['rd']
        else:
            if "rite" in test_name:
                dictionary_key_name = 'write_multi-thread'
                threshold = thresholds['mem']['multi']['wr']
            else:
                dictionary_key_name = 'read_multi-thread'
                threshold = thresholds['mem']['multi']['rd']

        return_statistics, statistics = self.calculate_statistics(test_name, data, ['data_transfer_speed'], [threshold])
        return_statistics = self.change_dictionary_key(return_statistics, 'data_transfer_speed', dictionary_key_name)

        if "VMs" in test_name:
            return return_statistics

        for key in data.keys():
            data[key] = data[key][-40:]

        plt.figure(figsize=(20, 10))
        plt.set_loglevel('WARNING')

        # Plot 1: Operations Per Second
        plt.subplot(3, 1, 1)
        plt.ticklabel_format(axis='y', style='sci', useMathText=True)
        plt.plot(data['commit'], data['operations_per_second'], marker='o', linestyle='-', color='b')
        plt.yticks(fontsize=14)
        plt.title('Operations per Second', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('Operations per Second', fontsize=16)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=14)

        # Plot 2: Data Transfer Speed
        plt.subplot(3, 1, 2)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['data_transfer_speed'], marker='o', linestyle='-', color='b')
        self.plot_marginals(data['commit'], statistics, 40)
        plt.yticks(fontsize=14)
        plt.title(f'Data Transfer Speed / Threshold: {threshold}', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('Data Transfer Speed (MiB/sec)', fontsize=16)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=14)

        # Plot 3: Latency
        plt.subplot(3, 1, 3)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['avg_latency'], marker='o', linestyle='-', color='b', label='Avg')
        plt.ylabel('Avg Latency (ms)', fontsize=16)
        plt.legend(loc='upper left')
        plt.grid(True)
        plt.xlabel('Build Number', fontsize=16)
        plt.xticks(data['commit'], rotation=90, fontsize=14)
        plt.ylabel('Max/Min Latency (ms)', fontsize=16)
        plt.yticks(fontsize=14)
        plt.twinx()
        plt.plot(data['commit'], data['max_latency'], marker='o', linestyle='-', color='r', label='Max')
        plt.plot(data['commit'], data['min_latency'], marker='o', linestyle='-', color='g', label='Min')
        plt.legend(loc='upper right')
        plt.title('Latency', loc='right', fontweight="bold", fontsize=16)

        plt.suptitle(f'{test_name}\nBuild type: {self.build_type}, Device: {self.device}', fontsize=18, fontweight='bold')

        plt.tight_layout()
        plt.savefig(self.plot_dir + f'{self.device}_{test_name}.png')
        return return_statistics

    @keyword
    def read_speed_csv_and_plot(self, test_name):
        data = {
            'commit': [],
            'tx': [],
            'rx': []
        }
        threshold = thresholds['iperf']

        return_statistics, statistics = self.calculate_statistics(test_name, data, ['tx', 'rx'], [threshold])

        for key in data.keys():
            data[key] = data[key][-40:]

        plt.figure(figsize=(20, 10))
        plt.set_loglevel('WARNING')

        # Plot 1: TX
        plt.subplot(2, 1, 1)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['tx'], marker='o', linestyle='-', color='b')
        self.plot_marginals(data['commit'], statistics, 40, '0')
        plt.yticks(fontsize=14)
        plt.title('Transmitting Speed', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('TX Speed (MBytes/sec)', fontsize=16)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=14)

        # Plot 2: RX
        plt.subplot(2, 1, 2)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['rx'], marker='o', linestyle='-', color='b')
        self.plot_marginals(data['commit'], statistics, 40, '1')
        plt.yticks(fontsize=14)
        plt.title('Receiving Speed', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('RX Speed (MBytes/sec)', fontsize=16)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=14)

        plt.xlabel('Build Number', fontsize=16)

        plt.suptitle(f'{test_name}\nBuild type: {self.build_type}, Device: {self.device}\nThreshold: {threshold}', fontsize=18, fontweight='bold')

        plt.tight_layout()
        plt.savefig(self.plot_dir + f'{self.device}_{test_name}.png')
        return return_statistics

    @keyword
    def read_fileio_data_csv_and_plot(self, test_name):
        data = {
            'commit': [],
            'file_operations': [],
            'throughput': [],
            'min_latency': [],
            'avg_latency': [],
            'max_latency': [],
            'avg_events_per_thread': [],
            'events_per_thread_stddev': []
        }

        # Set threshold for fail depending on test type: write/read
        if "write" in test_name:
            threshold = thresholds['fileio']['wr']
        else:
            if "Lenovo" in self.device:
                threshold = thresholds['fileio']['rd_lenovo-x1']
            else:
                threshold = thresholds['fileio']['rd']

        return_statistics, statistics = self.calculate_statistics(test_name, data, ['throughput'], [threshold])

        for key in data.keys():
            data[key] = data[key][-40:]

        plt.figure(figsize=(20, 10))
        plt.set_loglevel('WARNING')

        plt.subplot(3, 1, 1)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['file_operations'], marker='o', linestyle='-', color='b')
        plt.yticks(fontsize=14)
        plt.title('File operation', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('File operation per second', fontsize=16)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=14)

        plt.subplot(3, 1, 2)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['throughput'], marker='o', linestyle='-', color='b')
        self.plot_marginals(data['commit'], statistics, 40)
        plt.yticks(fontsize=14)
        plt.title(f'Throughput / Threshold: {threshold}', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('Throughput, MiB/s', fontsize=16)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=14)

        plt.subplot(3, 1, 3)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['avg_latency'], marker='o', linestyle='-', color='b', label='Avg')
        plt.ylabel('Avg Latency (ms)', fontsize=16)
        plt.legend(loc='upper left')
        plt.xlabel('Build Number', fontsize=16)
        plt.xticks(data['commit'], rotation=90, fontsize=14)
        plt.twinx()
        plt.plot(data['commit'], data['max_latency'], marker='o', linestyle='-', color='r', label='Max')
        plt.plot(data['commit'], data['min_latency'], marker='o', linestyle='-', color='g', label='Min')
        plt.yticks(fontsize=14)
        plt.ylabel('Max/Min Latency (ms)', fontsize=16)
        plt.legend(loc='upper right')
        plt.title('Latency', loc='right', fontweight="bold", fontsize=16)
        plt.grid(True)

        plt.suptitle(f'{test_name}\nBuild type: {self.build_type}, device: {self.device}', fontsize=18, fontweight='bold')

        plt.tight_layout()
        plt.savefig(self.plot_dir + f'{self.device}_{test_name}.png')
        return return_statistics

    @keyword("Read Bootime CSV and Plot")
    def read_bootime_csv_and_plot(self, test_name):

        # Omit time_to_desktop for Orin boot tests
        threshold = {'time_to_desktop': thresholds['boot_time']['time_to_desktop'],
                     'response_to_ping': thresholds['boot_time']['response_to_ping']}
        monitored_values = ['time_to_desktop', 'response_to_ping']
        if 'Orin' in test_name:
            threshold = [thresholds['boot_time']['response_to_ping']]
            monitored_values = ['response_to_ping']
            data = {
                    'commit': [],
                    'response_to_ping':[],
                    }
        else:
            data = {
                'commit': [],
                'time_to_desktop': [],
                'response_to_ping': [],
            }

        return_statistics, statistics = self.calculate_statistics(test_name, data, monitored_values, threshold)

        for key in data.keys():
            data[key] = data[key][-40:]

        plt.figure(figsize=(20, 10))
        plt.set_loglevel('WARNING')

        plt.subplot(2, 1, 1)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['response_to_ping'], marker='o', linestyle='-', color='b')
        if 'Orin' in test_name:
            index = ''
        else:
            index = '1'
        self.plot_marginals(data['commit'], statistics, 40, index)
        plt.yticks(fontsize=14)
        plt.title('Response to ping', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('seconds', fontsize=12)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=14)

        # Omit time_to_desktop for Orin boot tests
        if not 'Orin' in test_name:
            plt.subplot(2, 1, 2)
            plt.ticklabel_format(axis='y', style='plain')
            plt.plot(data['commit'], data['time_to_desktop'], marker='o', linestyle='-', color='b')
            self.plot_marginals(data['commit'], statistics, 40, '0')
            plt.yticks(fontsize=14)
            plt.title('Time from reboot to desktop available', loc='right', fontweight="bold", fontsize=16)
            plt.ylabel('seconds', fontsize=12)
            plt.grid(True)
            plt.xticks(data['commit'], rotation=90, fontsize=14)

        plt.suptitle(f'{test_name}\nBuild type: {self.build_type}, Device: {self.device}\nThreshold {threshold}',
                     fontsize=18, fontweight='bold')

        plt.tight_layout()
        plt.savefig(self.plot_dir + f'{self.device}_{test_name}.png')

        return return_statistics

    def extract_numeric_part(self, build_identifier):
        parts = build_identifier.split('-')
        base_number = int(''.join(filter(str.isdigit, parts[0])))
        suffix = int(parts[1]) if len(parts) > 1 and parts[1].isdigit() else -1
        return (base_number, suffix)

    def read_vms_data_csv_and_plot(self, test_name, vms_dict):
        tests = ['cpu_1thread', 'memory_read_1thread', 'memory_write_1thread', 'cpu', 'memory_read', 'memory_write']
        data = {test: {} for test in tests}

        all_builds = {test: [] for test in tests}

        for vm_name, threads in vms_dict.items():
            for test in tests:
                if "1thread" not in test and int(threads) == 1:
                    continue

                file_name = f"{self.data_dir}/{self.device}_{vm_name}_{test_name}_{test}.csv"
                if not os.path.exists(file_name):
                    continue

                with open(file_name, 'r') as file:
                    csvreader = csv.reader(file)
                    build_counter = {}
                    build_data = []
                    for row in csvreader:
                        if not row:
                            continue
                        build = row[0]
                        build_counter[build] = build_counter.get(build, -1) + 1
                        modified_build = f"{build}-{build_counter[build]}" if build_counter[build] > 0 else build
                        build_data.append((modified_build, float(row[1 if 'cpu' in test else 2])))

                    if build_data:
                        build_data = build_data[-10:]  # Keep only the last 10 builds
                        data[test][vm_name] = {
                            'commit': [build[0] for build in build_data],
                            'values': [build[1] for build in build_data],
                            'threads': threads
                        }
                        for build in [build[0] for build in build_data]:
                            if build not in all_builds[test]:
                                all_builds[test].append(build)

        for test in tests:
            plt.figure(figsize=(10, 6))

            for i, (vm_name, vm_data) in enumerate(data[test].items()):
                if vm_data:
                    indices = [all_builds[test].index(build) for build in vm_data['commit']]
                    plt.bar([x + i * 0.1 for x in indices], vm_data['values'], width=0.1,
                            label=f"{vm_name} ({vm_data['threads']} threads)" if "1thread" not in test else vm_name)

            plt.title(f'Comparison of {test} results for VMs\nBuild type: {self.build_type}, Device: {self.device}')
            plt.xlabel('Builds')
            plt.ylabel('Data transfer speed, MB/s' if 'memory' in test else 'Events per second')
            plt.xticks(range(len(all_builds[test])), all_builds[test], rotation=90)
            plt.legend()
            plt.tight_layout()
            plt.savefig(self.plot_dir + f'{self.device}_{test_name}_{test}.png')
            plt.close()

    @keyword
    def generate_ballooning_graph(self, plot_dir, id, test_name):
        data = pandas.read_csv(self.data_dir + "ballooning_" + id + ".csv")
        start_time = 0
        end_time = int(data['time'].values[data.index.max()])
        step = int((end_time - start_time) / 20)
        if step < 1:
            step = 1
        plt.figure(figsize=(20, 10))
        plt.set_loglevel('WARNING')
        plt.ticklabel_format(axis='y', style='plain')
        plt.yticks(fontsize=14)
        plt.plot(data['time'], data['total_mem'], marker='o', linestyle='-', color='b', label='total_mem')
        plt.plot(data['time'], data['used_mem'], marker='o', linestyle='-', color='g', label='used_mem')
        plt.plot(data['time'], data['available_mem'], marker='o', linestyle='-', color='r', label='avail_mem')
        plt.title(self.device + " - " + test_name, loc='center', fontweight="bold", fontsize=16)
        plt.ylabel('MegaBytes', fontsize=16)
        plt.grid(True)
        plt.xlabel('Time (s)', fontsize=16)
        plt.legend(loc='upper left', fontsize=20)
        plt.xticks(range(start_time, end_time, step), fontsize=14)
        plt.savefig(plot_dir + f'mem_ballooning_{id}.png')
        return

    @keyword
    def save_cpu_data(self, test_name, cpu_data):
        self.write_test_data_to_csv(test_name, cpu_data)
        return self.read_cpu_csv_and_plot(test_name)

    @keyword("Save Boot time Data")
    def save_boot_time_data(self, test_name, boot_data):
        self.write_test_data_to_csv(test_name, boot_data)
        return self.read_bootime_csv_and_plot(test_name)

    @keyword
    def save_memory_data(self, test_name, memory_data):
        self.write_test_data_to_csv(test_name, memory_data)
        return self.read_mem_csv_and_plot(test_name)

    @keyword
    def save_speed_data(self, test_name, speed_data):
        self.write_test_data_to_csv(test_name, speed_data)
        return self.read_speed_csv_and_plot(test_name)

    @keyword
    def save_fileio_data(self, test_name, fileio_data):
        self.write_test_data_to_csv(test_name, fileio_data)
        return self.read_fileio_data_csv_and_plot(test_name)


    # ---------------------------------------------------------------------
    # Unused functions and functions related to riscv perf analysis

    @keyword("Read Perfbench Csv And Plot")
    def read_perfbench_csv_and_plot(self, test_name, file_name, headers):
        self.normalize_columns(file_name, 100)
        fname = "normalized_" + file_name
        data = {}
        file_path = os.path.join(self.data_dir, f"{self.device}_{fname}")
        with open(file_path ,'r') as csvfile:
            lines = csv.reader(csvfile)
            heading = next(lines)
            logging.info("Reading data from csv file..." )
            logging.info(file_path)

            data_lines = []
            for row in lines:
                data_lines.append(row)

            build_counter = {}  # To keep track of duplicate builds
            index = 0
            data = {"commit":[]}

            for header in headers:
                data.update({
                header:[]})
                for row in data_lines:
                    if header == "commit":
                        build = str(row[0])
                        if build in build_counter:
                            build_counter[build] += 1
                            modified_build = f"{build}-{build_counter[build]}"
                        else:
                            build_counter[build] = 0
                            modified_build = build
                        data['commit'].append(modified_build)
                    else:
                        data[header].append(float(row[index]))
                index +=1

        plt.figure(figsize=(20, 15))
        plt.set_loglevel('WARNING')
        plt.subplot(1, 1, 1)
        plt.ticklabel_format(axis='y', style='plain')

        for key, value in data.items():
            if key not in ['commit']:
                plt.plot(data['commit'], value, marker='o', linestyle='-', label=key)
        plt.legend(title="Perfbench measurements", loc="lower left", ncol=3)
        plt.yticks(fontsize=14)
        plt.title(f'Perfbench results: {file_name}', loc='right', fontweight="bold", fontsize=16)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=14)
        plt.tight_layout()
        plt.savefig(self.plot_dir + f'{self.device}_{test_name}_{file_name}.png')

    def normalize_columns(self, csv_file_name, normalize_to):
        # Set the various results to the same range.
        # This makes it easier to notice significant change in any of the result parameters with one glimpse
        # If columns are plotted later on the whole picture is well displayed
        build_info_size = 1 # First columns containing buildata
        file_path = os.path.join(self.data_dir, f"{self.device}_{csv_file_name}")
        print("Normalizing results from file: ", file_path)
        data = pandas.read_csv(file_path)
        column_max = data.max(numeric_only=True)
        # Cut away the index column which is numeric but not measurement data to be normalized
        max_values = column_max[1:]
        data_rows = len(data.axes[0])
        data_columns = len(max_values)
        # Normalize all columns between 0...normalize_to
        for i in range(build_info_size, (build_info_size + data_columns)):
            for j in range(data_rows):
                normalized = data.iat[j, i] / max_values[i - build_info_size]
                data.iloc[[j],[i]] = normalized * normalize_to
        data.to_csv(self.data_dir + "/" + f"{self.device}_normalized_{csv_file_name}", index=False)

    def calc_statistics(self, csv_file_name):
        build_info_size = 1 # First columns containing buildata
        data = pandas.read_csv(self.data_dir + "/" + csv_file_name)

        # Calculate column averages
        column_avgs = data.mean(numeric_only=True)
        column_stds = data.std(numeric_only=True)
        column_min = data.min(numeric_only=True)
        column_max = data.max(numeric_only=True)

        # Cut away the index column which is numeric but not measurement data to be included in calculations
        avgs = column_avgs.tolist()[1:]
        stds = column_stds.tolist()[1:]
        min_values = column_min.tolist()[1:]
        max_values = column_max.tolist()[1:]

        data_rows = len(data.axes[0])
        data_columns = len(avgs)

        # Detect significant deviations from column mean
        # Find the result which is furthest away from the column mean.
        # Not taking into account those results which are within 1 std from column mean.
        max_deviations = ['-'] * (data_columns + build_info_size)
        for i in range(build_info_size, (build_info_size + data_columns)):
            for j in range(data_rows):
                if abs(data.iat[j, i] - avgs[i - build_info_size]) > stds[i - build_info_size]:
                    distance = abs(data.iat[j, i] - avgs[i - build_info_size]) / stds[i - build_info_size]
                    if max_deviations[i] == '-':
                        max_deviations[i] = distance
                    elif distance > max_deviations[i]:
                        max_deviations[i] = distance

        # Check if values of the last data row are 1 std away from their column mean.
        last_row_deviations = ['-'] * (data_columns + build_info_size)
        last_row_deviations[build_info_size - 1] = "LRD"
        for i in range(build_info_size, build_info_size + data_columns):
            if abs(data.iat[data_rows - 1, i] - avgs[i - build_info_size]) > stds[i - build_info_size]:
                distance = (data.iat[data_rows - 1, i] - avgs[i - build_info_size]) / stds[i - build_info_size]
                last_row_deviations[i] = distance

        shutil.copyfile(self.data_dir + "/" + csv_file_name, self.data_dir + "/raw_" + csv_file_name)

        with open(self.data_dir + "/" + csv_file_name, 'a') as f:

            writer_object = csv.writer(f)

            writer_object.writerow([])
            writer_object.writerow(last_row_deviations)
            writer_object.writerow(self.create_stats_row(build_info_size - 1, "average", avgs))
            writer_object.writerow(self.create_stats_row(build_info_size - 1, "std", stds))
            writer_object.writerow([])
            writer_object.writerow(self.create_stats_row(build_info_size - 1, "max", max_values))
            writer_object.writerow(self.create_stats_row(build_info_size - 1, "min", min_values))

            f.close()

    def create_stats_row(self, shift, label, value_list):
        row = ['-'] * shift
        row.append(label)
        row = row + value_list
        return row

    @keyword("Combine Normalized Data")
    def combine_normalized_data(self, test_name, src):
        """ Copy latest normalized perfbench results to combined result file. """
        file_path = os.path.join(self.data_dir, f"{self.device}_{test_name}.csv")
        with open(src, 'r') as src_f:
            src_lines = csv.reader(src_f)
            src_heading = next(src_lines)
            with open(file_path, 'a+', newline='') as dst_f:
                writer_object = csv.writer(dst_f)
                try:
                    data = pandas.read_csv(file_path)
                except:
                    writer_object.writerow(src_heading)
                for row in src_lines:
                    writer_object.writerow(row)
                dst_f.close()
            src_f.close()
