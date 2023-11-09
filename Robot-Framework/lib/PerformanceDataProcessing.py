# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import csv
import os
import json
import matplotlib.pyplot as plt
import logging
from robot.api.deco import keyword


class PerformanceDataProcessing:

    def __init__(self, device, build_number):
        self.device = device
        self.build_number = build_number
        self.data_dir = self._create_result_dir()

    def _get_job_name(self):
        f = open(f"../config/{self.build_number}.json")
        data = json.load(f)
        job_name = data["Job"]
        return job_name

    def _create_result_dir(self):
        job = self._get_job_name()
        data_dir = f"../../../Performance_test_results/{job}/"
        os.makedirs(data_dir, exist_ok=True)
        return data_dir

    def _write_to_csv(self, test_name, data):
        file_path = os.path.join(self.data_dir, f"{self.device}_{test_name}.csv")
        logging.info(f"Writing data to {file_path}")
        with open(file_path, 'a', newline='') as csvfile:
            csvwriter = csv.writer(csvfile)
            csvwriter.writerow(data)

    @keyword
    def write_cpu_to_csv(self, test_name, cpu_data):
        data = [self.build_number,
                cpu_data['cpu_events_per_second'],
                cpu_data['min_latency'],
                cpu_data['avg_latency'],
                cpu_data['max_latency'],
                cpu_data['cpu_events_per_thread'],
                cpu_data['cpu_events_per_thread_stddev'],
                self.device]
        self._write_to_csv(test_name, data)

    @keyword
    def write_mem_to_csv(self, test_name, mem_data):
        data = [self.build_number,
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
        data = [self.build_number,
                speed_data['tx'],
                speed_data['rx'],
                self.device]
        self._write_to_csv(test_name, data)

    @keyword
    def read_cpu_csv_and_plot(self, test_name):
        build_numbers = []
        cpu_events_per_second = []
        min_latency = []
        avg_latency = []
        max_latency = []
        cpu_events_per_thread = []
        cpu_events_per_thread_stddev = []

        with open(f"{self.data_dir}{self.device}_{test_name}.csv", 'r') as csvfile:
            csvreader = csv.reader(csvfile)
            logging.info("Reading data from csv file...")
            for row in csvreader:
                if row[7] == self.device:
                    build_numbers.append(str(row[0]))
                    cpu_events_per_second.append(float(row[1]))
                    min_latency.append(float(row[2]))
                    avg_latency.append(float(row[3]))
                    max_latency.append(float(row[4]))
                    cpu_events_per_thread.append(float(row[5]))
                    cpu_events_per_thread_stddev.append(float(row[6]))

        plt.figure(figsize=(20, 10))
        plt.set_loglevel('WARNING')

        # Plot 1: CPU Events per Second
        plt.subplot(3, 1, 1)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(build_numbers, cpu_events_per_second, marker='o', linestyle='-', color='b')
        plt.yticks(fontsize=14)
        plt.title('CPU Events per Second', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('CPU Events per Second', fontsize=16)
        plt.grid(True)
        plt.xticks(build_numbers, fontsize=14)

        # Plot 2: CPU Events per Thread
        plt.subplot(3, 1, 2)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(build_numbers, cpu_events_per_thread, marker='o', linestyle='-', color='b')
        plt.yticks(fontsize=14)
        plt.title('CPU Events per Thread', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('CPU Events per Thread', fontsize=16)
        plt.grid(True)
        plt.xticks(build_numbers, fontsize=14)
        # Create line chart with error bars on the same subplot
        plt.errorbar(build_numbers, cpu_events_per_thread,
                     yerr=cpu_events_per_thread_stddev,
                     capsize=4)

        # Plot 3: Latency
        plt.subplot(3, 1, 3)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(build_numbers, avg_latency, marker='o', linestyle='-', color='b', label='Avg')
        plt.ylabel('Avg Latency (ms)', fontsize=16)
        plt.legend(loc='upper left')
        plt.xlabel('Build Number', fontsize=16)
        plt.twinx()
        plt.plot(build_numbers, max_latency, marker='o', linestyle='-', color='r', label='Max')
        plt.plot(build_numbers, min_latency, marker='o', linestyle='-', color='g', label='Min')
        plt.yticks(fontsize=14)
        plt.ylabel('Max/Min Latency (ms)', fontsize=16)
        plt.legend(loc='upper right')
        plt.title('Latency', loc='right', fontweight="bold", fontsize=16)
        plt.grid(True)
        plt.xticks(build_numbers, fontsize=14)

        plt.suptitle(f'{test_name} ({self.device})', fontsize=18, fontweight='bold')

        plt.tight_layout()
        plt.savefig(f'../test-suites/{self.device}_{test_name}.png')  # Save the plot as an image file

    @keyword
    def read_mem_csv_and_plot(self, test_name):
        build_numbers = []
        operations_per_second = []
        data_transfer_speed = []
        min_latency = []
        avg_latency = []
        max_latency = []
        avg_events_per_thread = []
        events_per_thread_stddev = []

        with open(f"{self.data_dir}{self.device}_{test_name}.csv", 'r') as csvfile:
            csvreader = csv.reader(csvfile)
            logging.info("Reading data from csv file...")
            for row in csvreader:
                if row[8] == self.device:
                    build_numbers.append(str(row[0]))
                    operations_per_second.append(float(row[1]))
                    data_transfer_speed.append(float(row[2]))
                    min_latency.append(float(row[3]))
                    avg_latency.append(float(row[4]))
                    max_latency.append(float(row[5]))
                    avg_events_per_thread.append(float(row[6]))
                    events_per_thread_stddev.append(float(row[7]))

        plt.figure(figsize=(20, 10))
        plt.set_loglevel('WARNING')

        # Plot 1: Operations Per Second
        plt.subplot(3, 1, 1)
        plt.ticklabel_format(axis='y', style='sci', useMathText=True)
        plt.plot(build_numbers, operations_per_second, marker='o', linestyle='-', color='b')
        plt.yticks(fontsize=14)
        plt.title('Operations per Second', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('Operations per Second', fontsize=16)
        plt.grid(True)
        plt.xticks(build_numbers, fontsize=14)

        # Plot 2: Data Transfer Speed
        plt.subplot(3, 1, 2)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(build_numbers, data_transfer_speed, marker='o', linestyle='-', color='b')
        plt.yticks(fontsize=14)
        plt.title('Data Transfer Speed', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('Data Transfer Speed (MiB/sec)', fontsize=16)
        plt.grid(True)
        plt.xticks(build_numbers, fontsize=14)

        # Plot 3: Latency
        plt.subplot(3, 1, 3)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(build_numbers, avg_latency, marker='o', linestyle='-', color='b', label='Avg')
        plt.ylabel('Avg Latency (ms)', fontsize=16)
        plt.legend(loc='upper left')
        plt.grid(True)
        plt.xlabel('Build Number', fontsize=16)
        plt.twinx()
        plt.plot(build_numbers, max_latency, marker='o', linestyle='-', color='r', label='Max')
        plt.plot(build_numbers, min_latency, marker='o', linestyle='-', color='g', label='Min')
        plt.yticks(fontsize=14)
        plt.ylabel('Max/Min Latency (ms)', fontsize=16)
        plt.legend(loc='upper right')
        plt.title('Latency', loc='right', fontweight="bold", fontsize=16)
        plt.xticks(build_numbers, fontsize=14)

        plt.suptitle(f'{test_name} ({self.device})', fontsize=18, fontweight='bold')

        plt.tight_layout()
        plt.savefig(f'../test-suites/{self.device}_{test_name}.png')  # Save the plot as an image file

    @keyword
    def read_speed_csv_and_plot(self, test_name):
        build_numbers = []
        tx = []
        rx = []

        with open(f"{self.data_dir}{self.device}_{test_name}.csv", 'r') as csvfile:
            csvreader = csv.reader(csvfile)
            logging.info("Reading data from csv file...")
            for row in csvreader:
                if row[3] == self.device:
                    build_numbers.append(str(row[0]))
                    tx.append(float(row[1]))
                    rx.append(float(row[2]))

        plt.figure(figsize=(20, 10))
        plt.set_loglevel('WARNING')

        # Plot 1: TX
        plt.subplot(2, 1, 1)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(build_numbers, tx, marker='o', linestyle='-', color='b')
        plt.yticks(fontsize=14)
        plt.title('Transmitting Speed', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('TX Speed (MBytes/sec)', fontsize=16)
        plt.grid(True)
        plt.xticks(build_numbers, fontsize=14)

        # Plot 2: RX
        plt.subplot(2, 1, 2)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(build_numbers, rx, marker='o', linestyle='-', color='b')
        plt.yticks(fontsize=14)
        plt.title('Receiving Speed', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('RX Speed (MBytes/sec)', fontsize=16)
        plt.grid(True)
        plt.xticks(build_numbers, fontsize=14)

        plt.xlabel('Build Number', fontsize=16)

        plt.suptitle(f'{test_name} ({self.device})', fontsize=18, fontweight='bold')

        plt.tight_layout()
        plt.savefig(f'../test-suites/{self.device}_{test_name}.png')  # Save the plot as an image file

    @keyword
    def save_cpu_data(self, test_name, cpu_data):

        self.write_cpu_to_csv(test_name, cpu_data)
        self.read_cpu_csv_and_plot(test_name)

    @keyword
    def save_memory_data(self, test_name, cpu_data):

        self.write_mem_to_csv(test_name, cpu_data)
        self.read_mem_csv_and_plot(test_name)

    @keyword
    def save_speed_data(self, test_name, cpu_data):

        self.write_speed_to_csv(test_name, cpu_data)
        self.read_speed_csv_and_plot(test_name)
