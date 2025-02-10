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

    def __init__(self, device, build_number, commit, job, perf_data_dir, config_path, plot_dir):
        self.device = device
        self.build_number = build_number
        self.commit = commit[:6]
        self.perf_data_dir = perf_data_dir
        self.config_path = config_path
        self.plot_dir = plot_dir
        self.data_dir = self._create_result_dirs()
        self.build_type = job.split(".")[0]

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

    @keyword
    def write_cpu_to_csv(self, test_name, cpu_data):
        data = [self.commit,
                cpu_data['cpu_events_per_second'],
                cpu_data['min_latency'],
                cpu_data['avg_latency'],
                cpu_data['max_latency'],
                cpu_data['cpu_events_per_thread'],
                cpu_data['cpu_events_per_thread_stddev'],
                self.device]
        self._write_to_csv(test_name, data)

    @keyword("Parse and Copy Perfbench To Csv")
    def parse_and_copy_perfbench_to_csv(self):

        perf_result_heading, perf_bit_result_heading = parse_perfbench.parse_perfbench_data(self.commit, self.device, self.data_dir)
        return perf_result_heading, perf_bit_result_heading

    @keyword
    def write_mem_to_csv(self, test_name, mem_data):
        data = [self.commit,
                mem_data['operations_per_second'],
                mem_data['data_transfer_speed'],
                mem_data['min_latency'],
                mem_data['avg_latency'],
                mem_data['max_latency'],
                mem_data['avg_events_per_thread'],
                mem_data['events_per_thread_stddev'],
                self.device]
        self._write_to_csv(test_name, data)

    @keyword
    def write_speed_to_csv(self, test_name, speed_data):
        data = [self.commit]
        for key in speed_data.keys():
                data.append(speed_data[key])
        data.append(self.device)
        self._write_to_csv(test_name, data)

    def write_fileio_data_to_csv(self, test_name, data):
        data = [self.commit,
                data['file_operations'],
                data['throughput'],
                data['min_latency'],
                data['avg_latency'],
                data['max_latency'],
                data['avg_events_per_thread'],
                data['events_per_thread_stddev'],
                self.device]
        self._write_to_csv(test_name, data)

    @keyword("Write Boot time to csv")
    def write_boot_time_to_csv(self, test_name, boot_data):
        data = [self.commit,
                boot_data['time_from_nixos_menu_tos_ssh'],
                boot_data['time_from_reboot_to_desktop_available'],
                boot_data['response_to_ping'],
                boot_data['response_to_ssh'],
                self.device]
        self._write_to_csv(test_name, data)

    def truncate(self, list, significant_figures):
        truncated_list = []
        for item in list:
            truncated_list.append(float(f'{item:.{significant_figures}g}'))
        return truncated_list

    def detect_deviation(self, data_column, baseline_start, threshold):
        # Calculate mean and population standard deviation of the results
        # Check if last value changes more than threshold from
        #   mean
        #   the second last value
        #   first value of the baseline period

        flag = 0

        # Slice the list to obtain "stable" baseline for mean and std calculations
        data_column_cut = data_column[baseline_start:-1]

        if len(data_column_cut) > 0:

            mean = sum(data_column_cut) / len(data_column_cut)

            data_sum = 0
            for value in data_column_cut:
               data_sum = (value - mean) ** 2 + data_sum
            pstd = (data_sum / len(data_column_cut)) ** (1/2)

            # Automatically calculated pstd can vary wildly in case of multiple successive major changes in results.
            # So this is not a good idea although looks nice:
            # if pstd > 0:
            #     distance = abs(data_column[-1] - mean) / pstd
            #     if distance > 3 * std:
            #         return [distance, mean, pstd]
            # Instead it is better to set some threshold manually (based on calculated pstd history of "stable" periods)

            d = [0] * 3

            # Monitor change from previous measurement. This will catch multiple successive changes
            d[0] = data_column[-1] - data_column[-2]

            # Monitor deviation from the mean of the last "stable" baseline period
            d[1] = data_column[-1] - mean

            # Change from the first measurement of the last stable period,
            # meaning there are no deviations detected within that period.
            # This will catch slow monotonic change over time.
            d[2] = data_column[-1] - data_column[baseline_start]

            # Flag indicating significant change in performance value
            flag = 0

            # Check if performance has either decreased or increased significantly
            for i in range(len(d)):
                if d[i] < -threshold:
                    flag = -1
                if d[i] > threshold:
                    flag = 1

            stats = self.truncate([mean, pstd] + d + [data_column[-1], data_column[-2], data_column[baseline_start]], 5)

        else:
            stats = [0] * 8

        statistics_dictionary = {
            'flag': flag,
            'threshold': threshold,
            'mean': stats[0],
            'pstd': stats[1],
            'd_previous': stats[2],
            'd_mean': stats[3],
            'd_baseline1': stats[4],
            'measurement': stats[5],
            'prev_meas': stats[6],
            'baseline1': stats[7]
        }
        return statistics_dictionary

    @keyword
    def read_cpu_csv_and_plot(self, test_name):
        data = {
            'commit': [],
            'cpu_events_per_second': [],
            'min_latency': [],
            'avg_latency': [],
            'max_latency': [],
            'cpu_events_per_thread': [],
            'cpu_events_per_thread_stddev': [],
            'statistics': []
        }

        # Set threshold for fail depending on test type: single/multi thread
        if "One thread" in test_name or "1thread" in test_name:
            if "NUC" in self.device:
                threshold = thresholds['cpu']['single_nuc']
            else:
               threshold = thresholds['cpu']['single']
        else:
            threshold = thresholds['cpu']['multi']

        statistics = None

        with open(f"{self.data_dir}{self.device}_{test_name}.csv", 'r') as csvfile:
            csvreader = csv.reader(csvfile)
            logging.info("Reading data from csv file...")
            build_counter = {}  # To keep track of duplicate builds
            baseline_start = 0
            row_index = 0
            for row in csvreader:
                if row[7] == self.device:
                    build = str(row[0])
                    if build in build_counter:
                        build_counter[build] += 1
                        modified_build = f"{build}-{build_counter[build]}"
                    else:
                        build_counter[build] = 0
                        modified_build = build
                    data['commit'].append(modified_build)
                    data['cpu_events_per_second'].append(float(row[1]))
                    data['min_latency'].append(float(row[2]))
                    data['avg_latency'].append(float(row[3]))
                    data['max_latency'].append(float(row[4]))
                    data['cpu_events_per_thread'].append(float(row[5]))
                    data['cpu_events_per_thread_stddev'].append(float(row[6]))

                    statistics = self.detect_deviation(data['cpu_events_per_second'], baseline_start, threshold)

                    if statistics['flag'] != 0:
                        baseline_start = row_index

                    data['statistics'].append(statistics)
                    row_index = row_index + 1

            self._write_statistics_to_csv(test_name, data)

        if "VMs" in test_name:
            return statistics

        for key in data.keys():
            data[key] = data[key][-40:]

        plt.figure(figsize=(20, 10))
        plt.set_loglevel('WARNING')

        # Plot 1: CPU Events per Second
        plt.subplot(3, 1, 1)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['cpu_events_per_second'], marker='o', linestyle='-', color='b')
        plt.yticks(fontsize=14)
        plt.title('CPU Events per Second', loc='right', fontweight="bold", fontsize=16)
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

        plt.suptitle(f'{test_name}\n(build type: {self.build_type}, device: {self.device})', fontsize=18, fontweight='bold')

        plt.tight_layout()
        plt.savefig(self.plot_dir + f'{self.device}_{test_name}.png')
        return statistics

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
            'events_per_thread_stddev': [],
            'statistics': []
        }

        statistics = None

        # Set threshold for fail depending on test type: single/multi thread, write/read
        if "One thread" in test_name or "1thread" in test_name:
            if "rite" in test_name:
                if "NUC" in self.device:
                    threshold = thresholds['mem']['single']['wr_nuc']
                else:
                    threshold = thresholds['mem']['single']['wr']
            else:
                if "NUC" in self.device:
                    threshold = thresholds['mem']['single']['rd_nuc']
                else:
                    threshold = thresholds['mem']['single']['rd']
        else:
            if "rite" in test_name:
                threshold = thresholds['mem']['multi']['wr']
            else:
                threshold = thresholds['mem']['multi']['rd']

        with open(f"{self.data_dir}{self.device}_{test_name}.csv", 'r') as csvfile:
            csvreader = csv.reader(csvfile)
            logging.info("Reading data from csv file...")
            build_counter = {}  # To keep track of duplicate builds
            baseline_start = 0
            row_index = 0
            for row in csvreader:
                if row[8] == self.device:
                    build = str(row[0])
                    if build in build_counter:
                        build_counter[build] += 1
                        modified_build = f"{build}-{build_counter[build]}"
                    else:
                        build_counter[build] = 0
                        modified_build = build
                    data['commit'].append(modified_build)
                    data['operations_per_second'].append(float(row[1]))
                    data['data_transfer_speed'].append(float(row[2]))
                    data['min_latency'].append(float(row[3]))
                    data['avg_latency'].append(float(row[4]))
                    data['max_latency'].append(float(row[5]))
                    data['avg_events_per_thread'].append(float(row[6]))
                    data['events_per_thread_stddev'].append(float(row[7]))

                    statistics = self.detect_deviation(data['data_transfer_speed'], baseline_start, threshold)

                    if statistics['flag'] != 0:
                        baseline_start = row_index

                    data['statistics'].append(statistics)
                    row_index = row_index + 1

            self._write_statistics_to_csv(test_name, data)

        if "VMs" in test_name:
            return statistics

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
        plt.yticks(fontsize=14)
        plt.title('Data Transfer Speed', loc='right', fontweight="bold", fontsize=16)
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

        plt.suptitle(f'{test_name}\n(build type: {self.build_type}, device: {self.device})', fontsize=18, fontweight='bold')

        plt.tight_layout()
        plt.savefig(self.plot_dir + f'{self.device}_{test_name}.png')
        return statistics

    @keyword
    def read_speed_csv_and_plot(self, test_name):
        data = {
            'commit': [],
            'tx': [],
            'rx': [],
            'statistics_tx': [],
            'statistics_rx': []
        }
        threshold = thresholds['iperf']
        statistics_tx = None
        statistics_rx = None

        with open(f"{self.data_dir}{self.device}_{test_name}.csv", 'r') as csvfile:
            csvreader = csv.reader(csvfile)
            logging.info("Reading data from csv file...")
            build_counter = {}  # To keep track of duplicate builds
            baseline_start = 0
            row_index = 0
            for row in csvreader:
                if row[3] == self.device:
                    build = str(row[0])
                    if build in build_counter:
                        build_counter[build] += 1
                        modified_build = f"{build}-{build_counter[build]}"
                    else:
                        build_counter[build] = 0
                        modified_build = build
                    data['commit'].append(modified_build)
                    data['tx'].append(float(row[1]))
                    data['rx'].append(float(row[2]))

                    statistics_tx = self.detect_deviation(data['tx'], baseline_start, threshold)
                    statistics_rx = self.detect_deviation(data['rx'], baseline_start, threshold)

                    if statistics_tx['flag'] != 0 or statistics_rx['flag'] != 0:
                        baseline_start = row_index

                    data['statistics_tx'].append(statistics_tx)
                    data['statistics_rx'].append(statistics_rx)
                    row_index = row_index + 1

            self._write_statistics_to_csv(test_name, data)

        statistics = {'tx': statistics_tx, 'rx': statistics_rx}

        for key in data.keys():
            data[key] = data[key][-40:]

        plt.figure(figsize=(20, 10))
        plt.set_loglevel('WARNING')

        # Plot 1: TX
        plt.subplot(2, 1, 1)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['tx'], marker='o', linestyle='-', color='b')
        plt.yticks(fontsize=14)
        plt.title('Transmitting Speed', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('TX Speed (MBytes/sec)', fontsize=16)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=14)

        # Plot 2: RX
        plt.subplot(2, 1, 2)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['rx'], marker='o', linestyle='-', color='b')
        plt.yticks(fontsize=14)
        plt.title('Receiving Speed', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('RX Speed (MBytes/sec)', fontsize=16)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=14)

        plt.xlabel('Build Number', fontsize=16)

        plt.suptitle(f'{test_name}\n(build type: {self.build_type}, device: {self.device})', fontsize=18, fontweight='bold')

        plt.tight_layout()
        plt.savefig(self.plot_dir + f'{self.device}_{test_name}.png')
        return statistics

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
            'events_per_thread_stddev': [],
            'statistics': []
        }
        statistics = None

        # Set threshold for fail depending on test type: write/read
        if "write" in test_name:
            threshold = thresholds['fileio']['wr']
        else:
            if "Lenovo" in self.device:
                threshold = thresholds['fileio']['rd_lenovo-x1']
            else:
                threshold = thresholds['fileio']['rd']

        with open(f"{self.data_dir}{self.device}_{test_name}.csv", 'r') as csvfile:
            csvreader = csv.reader(csvfile)
            logging.info("Reading data from csv file...")
            build_counter = {}  # To keep track of duplicate builds
            baseline_start = 0
            row_index = 0
            for row in csvreader:
                if row[8] == self.device:
                    build = str(row[0])
                    if build in build_counter:
                        build_counter[build] += 1
                        modified_build = f"{build}-{build_counter[build]}"
                    else:
                        build_counter[build] = 0
                        modified_build = build
                    data['commit'].append(modified_build)
                    data['file_operations'].append(float(row[1]))
                    data['throughput'].append(float(row[2]))
                    data['min_latency'].append(float(row[3]))
                    data['avg_latency'].append(float(row[4]))
                    data['max_latency'].append(float(row[5]))
                    data['avg_events_per_thread'].append(float(row[6]))
                    data['events_per_thread_stddev'].append(float(row[7]))

                    statistics = self.detect_deviation(data['throughput'], baseline_start, threshold)

                    if statistics['flag'] != 0:
                        baseline_start = row_index

                    data['statistics'].append(statistics)
                    row_index = row_index + 1

            self._write_statistics_to_csv(test_name, data)

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
        plt.yticks(fontsize=14)
        plt.title('Throughput', loc='right', fontweight="bold", fontsize=16)
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

        plt.suptitle(f'{test_name}\n(build type: {self.build_type}, device: {self.device})', fontsize=18, fontweight='bold')

        plt.tight_layout()
        plt.savefig(self.plot_dir + f'{self.device}_{test_name}.png')
        return statistics

    @keyword("Read Bootime CSV and Plot")
    def read_bootime_csv_and_plot(self, test_name):
        data = {
                'commit': [],
                'time_from_nixos_menu_tos_ssh':[],
                'time_from_reboot_to_desktop_available':[],
                'response_to_ping':[],
                'response_to_ssh':[],
                }
        with open(f"{self.data_dir}{self.device}_{test_name}.csv", 'r') as csvfile:
            csvreader = csv.reader(csvfile)
            logging.info("Reading data from csv file..." )
            logging.info(f"{self.data_dir}{self.device}_{test_name}.csv")
            build_counter = {}  # To keep track of duplicate builds
            for row in csvreader:
                print("row on", row)
                if row[-1] == self.device:
                    build = str(row[0])
                    if build in build_counter:
                        build_counter[build] += 1
                        modified_build = f"{build}-{build_counter[build]}"
                    else:
                        build_counter[build] = 0
                        modified_build = build
                    data['commit'].append(modified_build)
                    data['time_from_nixos_menu_tos_ssh'].append(float(row[1]))
                    data['time_from_reboot_to_desktop_available'].append(float(row[2]))
                    data['response_to_ping'].append(float(row[3]))
                    data['response_to_ssh'].append(float(row[4]))

        plt.figure(figsize=(20, 10))
        plt.set_loglevel('WARNING')
        plt.subplot(4, 1, 1)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['time_from_nixos_menu_tos_ssh'], marker='o', linestyle='-', color='b')
        plt.yticks(fontsize=14)
        plt.title('Time from nixos menu to ssh', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('seconds', fontsize=12)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=14)

        plt.subplot(4, 1, 2)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['time_from_reboot_to_desktop_available'], marker='o', linestyle='-', color='b')
        plt.yticks(fontsize=14)
        plt.title('Time since reboot to desktop avaialble', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('seconds', fontsize=12)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=14)

        plt.subplot(4, 1, 3)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['response_to_ping'], marker='o', linestyle='-', color='b')
        plt.yticks(fontsize=14)
        plt.title('Response to ping', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('seconds', fontsize=12)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=14)

        plt.subplot(4, 1, 4)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['response_to_ssh'], marker='o', linestyle='-', color='b')
        plt.yticks(fontsize=14)
        plt.title('Response to ssh', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('seconds', fontsize=12)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=14)
        plt.suptitle(f'{test_name}\n(build type: {self.build_type}, device: {self.device})', fontsize=18, fontweight='bold')

        plt.tight_layout()
        plt.savefig(self.plot_dir + f'{self.device}_{test_name}.png')

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

            plt.title(f'Comparison of {test} results for VMs\n(build type: {self.build_type}, device: {self.device})')
            plt.xlabel('Builds')
            plt.ylabel('Data transfer speed, MB/s' if 'memory' in test else 'Events per second')
            plt.xticks(range(len(all_builds[test])), all_builds[test], rotation=90)
            plt.legend()
            plt.tight_layout()
            plt.savefig(self.plot_dir + f'{self.device}_{test_name}_{test}.png')
            plt.close()

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

    @keyword
    def save_cpu_data(self, test_name, cpu_data):

        self.write_cpu_to_csv(test_name, cpu_data)
        return self.read_cpu_csv_and_plot(test_name)

    @keyword("Save Boot time Data")
    def save_boot_time_data(self, test_name, boot_data):

        self.write_boot_time_to_csv(test_name, boot_data)
        return self.read_bootime_csv_and_plot(test_name)

    @keyword
    def save_memory_data(self, test_name, memory_data):

        self.write_mem_to_csv(test_name, memory_data)
        return self.read_mem_csv_and_plot(test_name)

    @keyword
    def save_speed_data(self, test_name, speed_data):

        self.write_speed_to_csv(test_name, speed_data)
        return self.read_speed_csv_and_plot(test_name)

    @keyword
    def save_fileio_data(self, test_name, fileio_data):

        self.write_fileio_data_to_csv(test_name, fileio_data)
        return self.read_fileio_data_csv_and_plot(test_name)
