# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import csv
import os
import shutil
import pandas
import json
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import logging
from robot.api.deco import keyword
from performance_thresholds import *
from output_parser import (
    parse_cyclictest_histogram,
    parse_cyclictest_histogram_overflows,
    parse_cyclictest_results,
    parse_cyclictest_spike_count,
    parse_cyclictest_spikes,
)
from memory_plotting import (
    add_percentage_columns,
    plot_vm_memory_snapshot,
)


class PerformanceDataProcessing:

    def __init__(self, device, build_number, commit, job, perf_data_dir, config_path, plot_dir, low_limit):
        self.device = device
        self.build_number = build_number
        self.commit = commit[:6]
        self.perf_data_dir = perf_data_dir
        self.config_path = config_path
        self.plot_dir = plot_dir
        self.data_dir = self._create_result_dirs()
        if len(job.split(".")) > 1:
            self.build_type = job.split(".")[1]
        else:
            self.build_type = "unknown"
        self.zero_result_flag = -100
        self.low_limit = float(low_limit)
        self.default_low_limit = float(low_limit)

    @staticmethod
    def _format_latency_us(value_us):
        if value_us >= 1000:
            return f"{value_us / 1000.0:.3f} ms"
        return f"{value_us} us"

    @staticmethod
    def _format_thread_counts(counts_per_thread):
        if not counts_per_thread:
            return "none"
        return ', '.join(
            f"t{thread_id}={count}"
            for thread_id, count in enumerate(counts_per_thread)
        )

    @staticmethod
    def _format_thread_cycles(cycles_per_thread, max_cycles_per_thread=5):
        cycle_chunks = []
        for thread_id in sorted(cycles_per_thread):
            cycles = cycles_per_thread[thread_id]
            if not cycles:
                continue
            shown_cycles = ','.join(str(cycle) for cycle in cycles[:max_cycles_per_thread])
            if len(cycles) > max_cycles_per_thread:
                shown_cycles += ',...'
            cycle_chunks.append(f"t{thread_id}=[{shown_cycles}]")
        return ', '.join(cycle_chunks) if cycle_chunks else "none"

    @keyword
    def set_custom_low_limit(self, new_value):
        self.low_limit = float(new_value)

    @keyword
    def set_default_low_limit(self):
        self.low_limit = self.default_low_limit

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

    def write_test_data_to_csv(self, test_name, test_data):
        logging.info("Saving test data to csv")
        data = [self.build_number + "-" + self.commit]
        if type(test_data) == list:
            for value in test_data:
                data.append(value)
        # Assume dictionary if the type is not list
        else:
            for key in test_data:
                data.append(test_data[key])
        data.append(self.device)
        self._write_to_csv(test_name, data)

    def truncate(self, list, significant_figures):
        truncated_list = []
        for item in list:
            truncated_list.append(float(f'{item:.{significant_figures}g}'))
        return truncated_list

    def detect_deviation(
        self,
        data_column,
        baseline_start,
        threshold,
        deviations_in_row,
        deviations=[],
        low_limit=None,
    ):
        # Calculate mean and population standard deviation of the results
        # Check if last value changes more than threshold from
        #   last "normal" measurement result
        #   mean of measurement results since baseline_start, omitting deviated results
        #   first value of the last stable baseline period

        flag = 0
        baseline_end = 0
        last_measurement = data_column[-1]
        if low_limit is None:
            low_limit = self.low_limit

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

            if lower_marginal < low_limit:
                lower_marginal = low_limit

            stats = self.truncate([mean, pstd] + d + [data_column[baseline_end], data_column[baseline_start], upper_marginal, lower_marginal], 5)

        else:
            stats = [0] * 8
            stats[0] = last_measurement
            stats[4] = last_measurement
            stats[5] = last_measurement
            stats[6] = low_limit
            stats[7] = low_limit

        if last_measurement < low_limit:
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

    def _analyze_performance_value(
        self,
        data_column,
        baseline_start,
        threshold,
        deviation_counter,
        deviations,
        new_baseline_start,
        row_index,
        low_limit=None,
    ):
        # Update automatic baseline state and deviation counter for one measurement series.
        statistics_block = self.detect_deviation(
            data_column,
            baseline_start,
            threshold,
            deviation_counter,
            deviations,
            low_limit,
        )

        flag = statistics_block['flag']
        if flag != 0:
            deviations.append(row_index)
            if abs(deviation_counter) < 1:
                # If deviation counter was previously 0 this is potential start point for new baseline
                new_baseline_start = row_index
            elif flag * deviation_counter < 0:
                # Reset deviation counter if sign of deviation has changed
                deviation_counter = 0
                new_baseline_start = row_index

            deviation_counter += flag
            statistics_block['flag'] = flag * abs(deviation_counter)
            if flag != self.zero_result_flag:
                if deviation_counter < self.zero_result_flag:
                    # Reset the deviation counter to -1 in case previous result was "close to zero" (invalid)
                    # --> baseline won't be switched
                    deviation_counter = -1
                    new_baseline_start = row_index
                if abs(deviation_counter) > static_thresholds['wait_until_reset'] - 1:
                    # Repeating deviation trend detected --> Switch to new baseline
                    deviation_counter = 0
                    deviations = []
                    baseline_start = new_baseline_start
            else:
                # Reset the deviation counter to -1 in case current result is "close to zero" (invalid)
                deviation_counter = -1
                statistics_block['flag'] = self.zero_result_flag
        else:
            # Test result is within pass limits
            deviation_counter = 0

        # In case there are not yet valid result history (results below low_limit) and now first valid result
        if low_limit is None:
            low_limit = self.low_limit

        if data_column[baseline_start] < low_limit and data_column[-1] > low_limit:
            deviation_counter = 0
            deviations = []
            baseline_start = row_index

        return statistics_block, baseline_start, new_baseline_start, deviation_counter, deviations

    def calculate_statistics(
        self,
        test_name,
        data,
        monitored_value,
        threshold,
        low_limit_overrides=None,
    ):
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
                        low_limit = self.low_limit
                        if low_limit_overrides and value in low_limit_overrides:
                            low_limit = low_limit_overrides[value]
                        # Select threshold by value name only if there are multiple thresholds
                        if len(threshold) < 2:
                            select_threshold = 0
                        else:
                            select_threshold = value
                        (
                            statistics_block,
                            baseline_start[value],
                            new_baseline_start[value],
                            deviation_counter[monitored_value_index],
                            deviations[value],
                        ) = self._analyze_performance_value(
                            data[value],
                            baseline_start[value],
                            threshold[select_threshold],
                            deviation_counter[monitored_value_index],
                            deviations[value],
                            new_baseline_start[value],
                            row_index,
                            low_limit,
                        )

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

    def plot_marginals_and_deviations(self, x_data, statistics, plot_limit, result_index=''):

        for key in statistics.keys():
            statistics[key] = statistics[key][-plot_limit:]
        plt.plot(x_data, statistics['upper_marginal' + result_index], marker='', linestyle='dotted', color='r')
        plt.plot(x_data, statistics['lower_marginal' + result_index], marker='', linestyle='dotted', color='r')

        # Plot marker 'x' over data under low limit.
        # Plot marker '^' over increased results.
        # Plot marker 'v' over decreased results.
        row = 0
        low_limit_labels = []
        low_limit_data = []
        increase_labels = []
        increase_data = []
        decrease_labels = []
        decrease_data = []
        for result in statistics['measurement' + result_index]:
            flag = statistics['flag' + result_index][row]
            if flag != 0:
                if flag == self.zero_result_flag:
                    low_limit_labels.append(x_data[row])
                    low_limit_data.append(result)
                elif flag > 0:
                    increase_labels.append(x_data[row])
                    increase_data.append(result)
                else:
                    decrease_labels.append(x_data[row])
                    decrease_data.append(result)
            row += 1
        plt.plot(low_limit_labels, low_limit_data, marker='x', markersize=12, linestyle='None', mfc='r', mec='r')
        plt.plot(increase_labels, increase_data, marker='^', markersize=12, linestyle='None', mfc='y', mec='r')
        plt.plot(decrease_labels, decrease_data, marker='v', markersize=12, linestyle='None', mfc='y', mec='r')

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
        self.plot_marginals_and_deviations(data['commit'], statistics, 40)
        plt.yticks(fontsize=14)
        plt.title(f'CPU Events per Second / Threshold: {threshold}', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('CPU Events per Second', fontsize=16)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=10)

        # Plot 2: CPU Events per Thread
        plt.subplot(3, 1, 2)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['cpu_events_per_thread'], marker='o', linestyle='-', color='b')
        plt.yticks(fontsize=14)
        plt.title('CPU Events per Thread', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('CPU Events per Thread', fontsize=16)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=10)
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
        plt.xticks(data['commit'], rotation=90, fontsize=10)
        plt.ylabel('Max/Min Latency (ms)', fontsize=16)
        plt.yticks(fontsize=14)
        plt.twinx()
        plt.plot(data['commit'], data['max_latency'], marker='o', linestyle='-', color='r', label='Max')
        plt.plot(data['commit'], data['min_latency'], marker='o', linestyle='-', color='g', label='Min')
        plt.legend(loc='upper left')
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
                threshold = thresholds['mem']['single']['wr']
            else:
                dictionary_key_name = 'read_1thread'
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
        plt.xticks(data['commit'], rotation=90, fontsize=10)

        # Plot 2: Data Transfer Speed
        plt.subplot(3, 1, 2)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['data_transfer_speed'], marker='o', linestyle='-', color='b')
        self.plot_marginals_and_deviations(data['commit'], statistics, 40)
        plt.yticks(fontsize=14)
        plt.title(f'Data Transfer Speed / Threshold: {threshold}', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('Data Transfer Speed (MiB/sec)', fontsize=16)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=10)

        # Plot 3: Latency
        plt.subplot(3, 1, 3)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['avg_latency'], marker='o', linestyle='-', color='b', label='Avg')
        plt.ylabel('Avg Latency (ms)', fontsize=16)
        plt.legend(loc='upper left')
        plt.grid(True)
        plt.xlabel('Build Number', fontsize=16)
        plt.xticks(data['commit'], rotation=90, fontsize=10)
        plt.ylabel('Max/Min Latency (ms)', fontsize=16)
        plt.yticks(fontsize=14)
        plt.twinx()
        plt.plot(data['commit'], data['max_latency'], marker='o', linestyle='-', color='r', label='Max')
        plt.plot(data['commit'], data['min_latency'], marker='o', linestyle='-', color='g', label='Min')
        plt.legend(loc='upper left')
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
        self.plot_marginals_and_deviations(data['commit'], statistics, 40, '0')
        plt.yticks(fontsize=14)
        plt.title('Transmitting Speed', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('TX Speed (MBytes/sec)', fontsize=16)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=10)

        # Plot 2: RX
        plt.subplot(2, 1, 2)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['rx'], marker='o', linestyle='-', color='b')
        self.plot_marginals_and_deviations(data['commit'], statistics, 40, '1')
        plt.yticks(fontsize=14)
        plt.title('Receiving Speed', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('RX Speed (MBytes/sec)', fontsize=16)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=10)

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
            if "X1" in self.device:
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
        plt.xticks(data['commit'], rotation=90, fontsize=10)

        plt.subplot(3, 1, 2)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['throughput'], marker='o', linestyle='-', color='b')
        self.plot_marginals_and_deviations(data['commit'], statistics, 40)
        plt.yticks(fontsize=14)
        plt.title(f'Throughput / Threshold: {threshold}', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('Throughput, MiB/s', fontsize=16)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=10)

        plt.subplot(3, 1, 3)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['avg_latency'], marker='o', linestyle='-', color='b', label='Avg')
        plt.ylabel('Avg Latency (ms)', fontsize=16)
        plt.legend(loc='upper left')
        plt.xlabel('Build Number', fontsize=16)
        plt.xticks(data['commit'], rotation=90, fontsize=10)
        plt.twinx()
        plt.plot(data['commit'], data['max_latency'], marker='o', linestyle='-', color='r', label='Max')
        plt.plot(data['commit'], data['min_latency'], marker='o', linestyle='-', color='g', label='Min')
        plt.yticks(fontsize=14)
        plt.ylabel('Max/Min Latency (ms)', fontsize=16)
        plt.legend(loc='upper left')
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
        self.plot_marginals_and_deviations(data['commit'], statistics, 40, index)
        plt.yticks(fontsize=14)
        plt.title('Response to ping', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('seconds', fontsize=12)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=10)

        # Omit time_to_desktop for Orin boot tests
        if not 'Orin' in test_name:
            plt.subplot(2, 1, 2)
            plt.ticklabel_format(axis='y', style='plain')
            plt.plot(data['commit'], data['time_to_desktop'], marker='o', linestyle='-', color='b')
            self.plot_marginals_and_deviations(data['commit'], statistics, 40, '0')
            plt.yticks(fontsize=14)
            plt.title('Time from reboot to desktop available', loc='right', fontweight="bold", fontsize=16)
            plt.ylabel('seconds', fontsize=12)
            plt.grid(True)
            plt.xticks(data['commit'], rotation=90, fontsize=10)

        plt.suptitle(f'{test_name}\nBuild type: {self.build_type}, Device: {self.device}\nThreshold {threshold}',
                     fontsize=18, fontweight='bold')

        plt.tight_layout()
        plt.savefig(self.plot_dir + f'{self.device}_{test_name}.png')

        return return_statistics

    @keyword("Read AppLaunch CSV and Plot")
    def read_applaunch_csv_and_plot(self, test_name, threshold):
        threshold = float(threshold)

        with open(f"{self.data_dir}{self.device}_{test_name}.csv", 'r') as csvfile:
            lines = csv.reader(csvfile)
            logging.info("Reading data from csv file..." )

            build_counter = {}  # To keep track of duplicate builds
            data = {"commit": [], "launch_time": []}

            for row in lines:
                build = str(row[0])
                if build in build_counter:
                    build_counter[build] += 1
                    modified_build = f"{build}-{build_counter[build]}"
                else:
                    build_counter[build] = 0
                    modified_build = build
                data['commit'].append(modified_build)
                try:
                    val = float(row[1])
                except (IndexError, ValueError, TypeError):
                    val = float('nan')
                data['launch_time'].append(val)

        plt.figure(figsize=(20, 15))
        plt.set_loglevel('WARNING')
        plt.subplot(1, 1, 1)
        plt.ticklabel_format(axis='y', style='plain')

        for key, value in data.items():
            if key != 'commit':
                plt.plot(range(len(data['commit'])), value, marker='o', linestyle='-', label=key)

        x = range(len(data['commit']))
        plt.plot(x, [threshold] * len(x), color='red', linestyle='dotted', linewidth=2)
        plt.legend(title="App launching time", loc="lower left", ncol=3)
        plt.yticks(fontsize=14)
        plt.title(f'{test_name}', loc='right', fontweight="bold", fontsize=16)
        plt.grid(True)
        plt.xticks(range(len(data['commit'])), data['commit'], rotation=90, fontsize=10)
        plt.tight_layout()
        plt.savefig(self.plot_dir + f'{self.device}_{test_name}.png')
        plt.close()

        return False if data['launch_time'][-1] > threshold else True


    @keyword("Read Isolation Test CSV and Plot")
    def read_isolation_test_csv_and_plot(self, test_name):

        if "CPU" in test_name:
            threshold = thresholds['cpu_isolation']
        if "FileIO" in test_name:
            threshold = thresholds['fileio_isolation']

        data = {
            'commit': [],
            'single_vm_test': [],
            'parallel_test': [],
            'difference': [],
        }

        return_statistics, statistics = self.calculate_statistics(test_name, data, ['difference'], [threshold])

        for key in data.keys():
            data[key] = data[key][-40:]

        plt.figure(figsize=(20, 10))
        plt.set_loglevel('WARNING')

        plt.subplot(2, 1, 1)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['difference'], marker='o', linestyle='-', color='b')

        self.plot_marginals_and_deviations(data['commit'], statistics, 40)
        plt.yticks(fontsize=14)
        plt.title('Effect of resource exhaustion attack from another vm', loc='right', fontweight="bold", fontsize=15)
        plt.ylabel('Decrease of performance in ref vm (%)', fontsize=12)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=10)

        plt.suptitle(f'{test_name}\nBuild type: {self.build_type}, Device: {self.device}\nThreshold {threshold}',
                     fontsize=18, fontweight='bold')

        plt.tight_layout()
        plt.savefig(self.plot_dir + f'{self.device}_{test_name}.png')

        return return_statistics

    def read_vms_data_csv_and_plot(self, test_name, vms_dict):
        tests = ['cpu_1thread', 'memory_read_1thread', 'memory_write_1thread', 'cpu', 'memory_read', 'memory_write']
        data = {test: {} for test in tests}
        plot_builds = []

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
                        # Let's use only net-vm cpu_1thread data for defining which build identifiers are taken into the plot.
                        if vm_name == "net-vm" and test == 'cpu_1thread':
                            for build in [build[0] for build in build_data]:
                                plot_builds.append(build)

        for test in tests:
            plt.figure(figsize=(10, 6))
            for i, (vm_name, vm_data) in enumerate(data[test].items()):
                if vm_data:
                    indices = []
                    plot_values = []
                    for id in plot_builds:
                        if id in vm_data['commit']:
                            indices.append(plot_builds.index(id))
                            plot_values.append(vm_data['values'][vm_data['commit'].index(id)])
                    plt.bar([x + i * 0.1 for x in indices], plot_values, width=0.1,
                            label=f"{vm_name} ({vm_data['threads']} threads)" if "1thread" not in test else vm_name)
            plt.title(f'Comparison of {test} results for VMs\nBuild type: {self.build_type}, Device: {self.device}')
            plt.xlabel('Builds')
            plt.ylabel('Data transfer speed, MB/s' if 'memory' in test else 'Events per second')
            plt.xticks(range(len(plot_builds)), plot_builds, rotation=90, fontsize=10)
            plt.legend(loc='upper left')
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
        plt.xticks(range(start_time, end_time, step), fontsize=10)
        plt.savefig(plot_dir + f'mem_ballooning_{id}.png')
        return

    @keyword
    def parse_cyclictest_results_file(self, file_path):
        with open(file_path, 'r', encoding='utf-8') as file:
            return parse_cyclictest_results(file.read())

    @keyword
    def get_failed_cyclictest_variants(self, statistics_dict):
        failed_variants = []
        suffixes = (
            '_avg_latency_ms',
            '_overflow_count',
        )

        for key, value in statistics_dict.items():
            if value['flag'] <= 0:
                continue
            variant_name = key
            for suffix in suffixes:
                if key.endswith(suffix):
                    variant_name = key[:-len(suffix)]
                    break
            if variant_name not in failed_variants:
                failed_variants.append(variant_name)

        return failed_variants

    @keyword
    def get_cyclictest_histogram_limit(self, target, variant_name):
        return thresholds['cyclictest'][target][f'latency_threshold_us_{variant_name}']

    @keyword
    def generate_cyclictest_histogram_plot(
        self,
        source_file,
        plot_name,
        plot_title,
        overflow_start_us,
    ):
        with open(source_file, 'r', encoding='utf-8') as file:
            output = file.read()

        histogram = parse_cyclictest_histogram(output)
        overflow_data = parse_cyclictest_histogram_overflows(output)
        summary = parse_cyclictest_results(output)
        bucket_width_us = 50
        aggregated_counts = {}

        for bucket_us, count in zip(histogram['buckets_us'], histogram['counts']):
            if bucket_us < 0:
                continue
            range_start_us = (bucket_us // bucket_width_us) * bucket_width_us
            aggregated_counts[range_start_us] = (
                aggregated_counts.get(range_start_us, 0) + count
            )

        overflow_count = overflow_data['total_count']
        if overflow_count > 0:
            aggregated_counts[int(overflow_start_us)] = (
                aggregated_counts.get(int(overflow_start_us), 0) + overflow_count
            )

        x_values = [bucket / 1000.0 for bucket in sorted(aggregated_counts.keys())]
        y_values = [aggregated_counts[bucket] for bucket in sorted(aggregated_counts.keys())]

        plt.figure(figsize=(20, 8))
        plt.set_loglevel('WARNING')
        plt.bar(x_values, y_values, width=bucket_width_us / 1000.0, align='edge', color='b')
        plt.xlabel('Latency bucket start (ms)', fontsize=16)
        plt.ylabel('Samples', fontsize=16)
        plt.title(plot_title, fontsize=18, fontweight='bold')
        plt.yscale('log', base=10)
        plt.xlim(left=0)
        if overflow_count > 0:
            overflow_start_ms = int(overflow_start_us) / 1000.0
            bucket_width_ms = bucket_width_us / 1000.0
            overflow_end_ms = overflow_start_ms + bucket_width_ms
            tick_positions = [
                tick for tick in plt.xticks()[0]
                if tick < overflow_start_ms
            ]
            tick_positions.extend([overflow_start_ms, overflow_end_ms])
            tick_labels = [f"{tick:g}" for tick in tick_positions[:-2]]
            tick_labels.extend([f">={int(overflow_start_us)} us", ""])
            plt.xlim(left=0, right=overflow_end_ms)
            plt.xticks(tick_positions, tick_labels)
        plt.grid(True)
        plt.figtext(
            0.99,
            0.01,
            (
                f"Min {summary['min_latency_ms']:.6f} ms, "
                f"Avg {summary['avg_latency_ms']:.6f} ms, "
                f"Max {summary['max_latency_ms']:.6f} ms, "
                f"Overflows > {self._format_latency_us(int(overflow_start_us))}: {overflow_count}"
            ),
            ha='right',
            fontsize=12,
        )
        plt.tight_layout()
        plt.savefig(self.plot_dir + f'{plot_name}.png')
        plt.close()

    @keyword
    def generate_cyclictest_spike_plot(
        self,
        spike_file,
        plot_name,
        plot_title,
        histogram_limit_us=50000,
    ):
        with open(spike_file, 'r', encoding='utf-8') as file:
            output = file.read()

        spikes = parse_cyclictest_spikes(output)
        if not spikes:
            return False

        bucket_width_us = 50
        aggregated_counts = {}
        for spike in spikes:
            latency_us = spike['latency_us']
            range_start_us = max(
                int(histogram_limit_us),
                (latency_us // bucket_width_us) * bucket_width_us,
            )
            aggregated_counts[range_start_us] = (
                aggregated_counts.get(range_start_us, 0) + 1
            )

        x_values = [bucket / 1000.0 for bucket in sorted(aggregated_counts.keys())]
        y_values = [aggregated_counts[bucket] for bucket in sorted(aggregated_counts.keys())]
        histogram_limit_ms = int(histogram_limit_us) / 1000.0
        bucket_width_ms = bucket_width_us / 1000.0
        min_spike_us = min(spike['latency_us'] for spike in spikes)
        max_spike_us = max(spike['latency_us'] for spike in spikes)
        max_spike_bucket_us = max(aggregated_counts.keys())
        # Keep the spike plot readable even when only one or a few spikes were recorded near the threshold.
        min_plot_end_ms = histogram_limit_ms + bucket_width_ms * 10
        max_spike_end_ms = max_spike_bucket_us / 1000.0 + bucket_width_ms
        plot_end_ms = max(min_plot_end_ms, max_spike_end_ms)

        plt.figure(figsize=(20, 8))
        plt.set_loglevel('WARNING')
        plt.bar(x_values, y_values, width=bucket_width_us / 1000.0, align='edge', color='darkred')
        plt.xlabel('Spike latency bucket start (ms)', fontsize=16)
        plt.ylabel('Samples', fontsize=16)
        plt.title(plot_title, fontsize=18, fontweight='bold')
        plt.yscale('log', base=10)
        plt.xlim(left=histogram_limit_ms, right=plot_end_ms)
        plt.grid(True)
        plt.figtext(
            0.99,
            0.01,
            (
                f"Spike samples {len(spikes)}, "
                f"Min spike {self._format_latency_us(min_spike_us)}, "
                f"Max spike {self._format_latency_us(max_spike_us)}"
            ),
            ha='right',
            fontsize=12,
        )
        plt.tight_layout()
        plt.savefig(self.plot_dir + f'{plot_name}.png')
        plt.close()
        return True

    @keyword
    def get_cyclictest_histogram_overflow_count(self, histogram_file):
        with open(histogram_file, 'r', encoding='utf-8') as file:
            overflow_data = parse_cyclictest_histogram_overflows(file.read())

        return overflow_data['total_count']

    @keyword
    def get_cyclictest_histogram_overflow_report(
        self,
        histogram_file,
        overflow_start_us,
        max_cycles_per_thread=5,
    ):
        with open(histogram_file, 'r', encoding='utf-8') as file:
            overflow_data = parse_cyclictest_histogram_overflows(file.read())

        limit_us = int(overflow_start_us)
        return (
            f"Histogram overflows > {self._format_latency_us(limit_us)}: "
            f"{overflow_data['total_count']}"
            f" | Per-thread: {self._format_thread_counts(overflow_data['counts_per_thread'])}"
            f" | Cycles: {self._format_thread_cycles(overflow_data['cycles_per_thread'], int(max_cycles_per_thread))}"
        )

    @keyword
    def get_cyclictest_spike_report(
        self,
        spike_file,
        overflow_start_us,
        max_spikes_to_show=20,
    ):
        with open(spike_file, 'r', encoding='utf-8') as file:
            output = file.read()

        spikes = parse_cyclictest_spikes(output)
        count = parse_cyclictest_spike_count(output)

        limit_us = int(overflow_start_us)
        if count == 0:
            return (
                "Debug spike run did not report per-spike durations "
                f"above {self._format_latency_us(limit_us)}"
            )

        durations = ', '.join(
            self._format_latency_us(spike['latency_us'])
            for spike in spikes[:int(max_spikes_to_show)]
        )
        if count > int(max_spikes_to_show):
            durations += ', ...'

        return (
            f"Debug spike run reported {count} spike samples"
            f" | Durations: {durations}"
        )

    @keyword
    def read_cyclictest_latency_csv_and_plot(self, test_name):
        data = {'commit': []}
        metrics = ['min_latency_ms', 'avg_latency_ms', 'max_latency_ms', 'overflow_count']
        variants = ['t1_p80', 't1_p95', 'tnproc_p80', 'tnproc_p95']
        target = test_name.rsplit(' on ', 1)[-1]
        monitored_values = []

        for variant in variants:
            for metric in metrics:
                key = f'{variant}_{metric}'
                data[key] = []
                if metric in ('avg_latency_ms', 'overflow_count'):
                    monitored_values.append(key)

        threshold = {}
        low_limit_overrides = {}
        for variant in variants:
            threshold[f'{variant}_avg_latency_ms'] = thresholds['cyclictest'][target][
                f'latency_threshold_us_{variant}'
            ] / 1000.0
            threshold[f'{variant}_overflow_count'] = thresholds['cyclictest']['latency_overflow_count']
            low_limit_overrides[f'{variant}_overflow_count'] = 0
        return_statistics, _statistics = self.calculate_statistics(
            test_name,
            data,
            monitored_values,
            threshold,
            low_limit_overrides,
        )
        for variant in variants:
            return_statistics[f'{variant}_avg_latency_ms']['low_limit'] = self.low_limit
            return_statistics[f'{variant}_overflow_count']['low_limit'] = 0

        for key in data.keys():
            data[key] = data[key][-40:]

        plot_defs = [
            ('min_latency_ms', 'Min latency (ms)', 'Min latency'),
            ('avg_latency_ms', 'Avg latency (ms)', 'Avg latency'),
            ('max_latency_ms', 'Max latency (ms)', 'Max latency'),
            ('overflow_count', 'Overflow samples', 'Histogram overflows'),
        ]
        labels = {
            't1_p80': 't1 p80',
            't1_p95': 't1 p95',
            'tnproc_p80': 't$(nproc) p80',
            'tnproc_p95': 't$(nproc) p95',
        }

        for metric_key, axis_label, title in plot_defs:
            plt.figure(figsize=(20, 10))
            plt.set_loglevel('WARNING')
            for variant in variants:
                key = f'{variant}_{metric_key}'
                plt.plot(
                    data['commit'],
                    data[key],
                    marker='o',
                    linestyle='-',
                    label=labels[variant],
                )
            plt.ylabel(axis_label, fontsize=16)
            plt.xlabel('Build Number', fontsize=16)
            ax = plt.gca()
            ax.tick_params(axis='y', labelsize=14)
            plt.xticks(data['commit'], rotation=90, fontsize=10)
            plt.grid(True)
            plt.legend(loc='upper left')
            if metric_key == 'overflow_count':
                title_threshold = thresholds['cyclictest']['latency_overflow_count']
                ax.yaxis.set_major_locator(mticker.MaxNLocator(integer=True))
                plt.axhline(
                    y=thresholds['cyclictest']['latency_overflow_count'],
                    color='k',
                    linestyle='-.',
                    linewidth=1.5,
                )
            elif metric_key == 'avg_latency_ms':
                title_threshold = 'variant specific latency_threshold_us_*'
            elif metric_key == 'min_latency_ms':
                title_threshold = 'not monitored'
            else:
                title_threshold = 'not monitored'
            plt.title(
                f'{title} / Threshold: {title_threshold}',
                loc='right',
                fontweight='bold',
                fontsize=16,
            )
            plt.suptitle(
                f'{test_name}\nBuild type: {self.build_type}, Device: {self.device}',
                fontsize=18,
                fontweight='bold',
            )
            plt.tight_layout()
            plt.savefig(self.plot_dir + f'{self.device}_{test_name}_{metric_key}.png')
            plt.close()

        return return_statistics

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

    @keyword
    def save_isolation_test_data(self, test_name, cpu_isolation_data):
        self.write_test_data_to_csv(test_name, cpu_isolation_data)
        return self.read_isolation_test_csv_and_plot(test_name)

    @keyword
    def save_app_launch_time_data(self, test_name, data, threshold):
        self.write_test_data_to_csv(test_name, data)
        return self.read_applaunch_csv_and_plot(test_name, threshold)

    @keyword("Save VM Memory Snapshot Data")
    def save_vm_memory_snapshot_data(self, test_name, vm_mem_data):
        """
        Save a snapshot of per-VM memory usage for the current build and plot it across builds.

        Expected input keys:
          - mem_avail_mib__<vmname>: available memory in MiB
          - mem_total_mib__<vmname>: total memory in MiB
          - swap_free_mib__<vmname>: free swap in MiB
          - swap_total_mib__<vmname>: total swap in MiB
        """
        file_path = os.path.join(self.data_dir, f"{self.device}_{test_name}.csv")
        commit_id = self.build_number + "-" + self.commit

        # Keep columns stable across builds, but allow the set of VMs to grow.
        row = {"commit": commit_id, "device": self.device} | dict(vm_mem_data)
        if os.path.exists(file_path):
            df = pandas.read_csv(file_path)
            for col in row.keys():
                if col not in df.columns:
                    df[col] = pandas.NA
            for col in df.columns:
                if col not in row:
                    row[col] = pandas.NA
            df = pandas.concat([df, pandas.DataFrame([row], columns=df.columns)], ignore_index=True)
        else:
            df = pandas.DataFrame([row])

        df.to_csv(file_path, index=False)
        return self.read_vm_memory_snapshot_csv_and_plot(test_name)

    @keyword
    def save_cyclictest_latency_data(self, test_name, latency_data):
        self.write_test_data_to_csv(test_name, latency_data)
        return self.read_cyclictest_latency_csv_and_plot(test_name)

    def read_vm_memory_snapshot_csv_and_plot(self, test_name):
        # Match other read_*_csv_and_plot methods: read CSV, analyze, plot, return last result.
        data = pandas.read_csv(os.path.join(self.data_dir, f"{self.device}_{test_name}.csv"))
        data["build_index"] = list(range(len(data.index)))
        plot_df = self._normalize_vm_memory_snapshot_df(data)
        if plot_df.empty:
            logging.warning("No VM memory snapshot data to process for %s", test_name)
            plot_vm_memory_snapshot(test_name, data, plot_df, self.plot_dir, self.device, self.build_type)
            return {}

        threshold = thresholds["vm_memory_snapshot"]["mem_avail_pct"]
        return_statistics, statistics = self._build_vm_memory_analysis(plot_df, threshold)
        self._write_statistics_to_csv(test_name, statistics)
        plot_vm_memory_snapshot(test_name, data, plot_df, self.plot_dir, self.device, self.build_type)
        return return_statistics

    def _build_vm_memory_analysis(self, plot_df, threshold):
        # Aggregate per-VM mem_avail_pct analysis into Robot return data and statistics CSV rows.
        plot_df["mem_avail_pct_flag"] = 0
        current_build_index = plot_df["build_index"].max()
        return_statistics = {}
        statistics = self._init_vm_memory_stats_dict()

        for vm, vm_df in plot_df.dropna(subset=["mem_avail_pct"]).groupby("vm", sort=False):
            vm_statistics = self._analyze_vm_memory_series(vm, vm_df, threshold, plot_df)
            for key in statistics:
                statistics[key].extend(vm_statistics[key])
            if vm_statistics["build_index"] and vm_statistics["build_index"][-1] == current_build_index:
                return_statistics[vm] = vm_statistics["statistics_block"][-1]

        del statistics["build_index"]
        del statistics["statistics_block"]
        return return_statistics, statistics

    def _init_vm_memory_stats_dict(self):
        # Initialize VM snapshot statistics dictionary layout.
        return {
            "commit": [],
            "vm": [],
            "build_index": [],
            "statistics_block": [],
            "flag": [],
            "threshold": [],
            "d_baseline_start": [],
            "d_mean": [],
            "baseline_start": [],
            "baseline_mean": [],
            "baseline_end": [],
            "baseline_std": [],
            "upper_marginal": [],
            "lower_marginal": [],
            "measurement": [],
        }

    def _analyze_vm_memory_series(self, vm, vm_df, threshold, plot_df):
        # Analyze one VM's mem_avail_pct history and write its flags back to plot_df.
        statistics = self._init_vm_memory_stats_dict()
        vm_df = vm_df.sort_values("build_index")
        baseline_start = 0
        new_baseline_start = 0
        deviation_counter = 0
        deviations = []
        data_column = []

        for row_index, (df_index, row) in enumerate(vm_df.iterrows()):
            data_column.append(float(row["mem_avail_pct"]))
            (
                statistics_block,
                baseline_start,
                new_baseline_start,
                deviation_counter,
                deviations,
            ) = self._analyze_performance_value(
                data_column,
                baseline_start,
                threshold,
                deviation_counter,
                deviations,
                new_baseline_start,
                row_index,
            )

            plot_df.loc[df_index, "mem_avail_pct_flag"] = statistics_block["flag"]
            self._append_vm_memory_stat_row(statistics, row, vm, statistics_block)

        return statistics

    def _append_vm_memory_stat_row(self, statistics, row, vm, statistics_block):
        # Append one analyzed VM measurement to the statistics CSV data structure.
        statistics["commit"].append(row["commit"])
        statistics["vm"].append(vm)
        statistics["build_index"].append(row["build_index"])
        statistics["statistics_block"].append(statistics_block)
        for key in statistics_block:
            statistics[key].append(statistics_block[key])

    def _normalize_vm_memory_snapshot_df(self, df):
        rows = []
        avail_cols = [col for col in df.columns if col.startswith("mem_avail_mib__")]
        for _, row in df.iterrows():
            commit = row["commit"]
            build_index = row["build_index"]
            for avail_col in avail_cols:
                vm = avail_col.split("__", 1)[1]
                mem_total_col = f"mem_total_mib__{vm}"
                swap_free_col = f"swap_free_mib__{vm}"
                swap_total_col = f"swap_total_mib__{vm}"
                if mem_total_col not in df.columns:
                    continue
                rows.append(
                    {
                        "commit": commit,
                        "build_index": build_index,
                        "vm": vm,
                        "mem_avail_mib": row.get(avail_col, pandas.NA),
                        "mem_total_mib": row.get(mem_total_col, pandas.NA),
                        "swap_free_mib": row.get(swap_free_col, pandas.NA),
                        "swap_total_mib": row.get(swap_total_col, pandas.NA),
                    }
                )

        if not rows:
            return pandas.DataFrame()

        plot_df = pandas.DataFrame(rows)
        add_percentage_columns(
            plot_df,
            [
                ("mem_avail_mib", "mem_total_mib", "mem_avail_pct"),
                ("swap_free_mib", "swap_total_mib", "swap_free_pct"),
            ],
        )
        return plot_df


    # ---------------------------------------------------------------------
    # Unused functions

    def extract_numeric_part(self, build_identifier):
        parts = build_identifier.split('-')
        base_number = int(''.join(filter(str.isdigit, parts[0])))
        suffix = int(parts[1]) if len(parts) > 1 and parts[1].isdigit() else -1
        return (base_number, suffix)

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
