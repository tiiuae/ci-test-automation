# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import pandas as pd
import logging
import matplotlib.pyplot as plt
import csv
import os


class ParseMeasurementData:

    def __init__(self, csv_dir, plot_dir):
        self.csv_dir = csv_dir
        self.plot_dir = plot_dir
        self._create_csv_dir()
        self._create_plot_dir()

    def _create_plot_dir(self):
        if self.plot_dir != "./":
            logging.info(f"Creating {self.plot_dir}")
            os.makedirs(self.plot_dir, exist_ok=True)
        return

    def _create_csv_dir(self):
        if self.csv_dir != "./":
            logging.info(f"Creating {self.csv_dir}")
            os.makedirs(self.csv_dir, exist_ok=True)
        return

    def extract_time_interval(self, csv_file, start_time, end_time, output_filename, check_freq, divider=1):
        data = pd.read_csv(self.csv_dir + csv_file, header=0)
        interval = data.query("{} < time < {}".format(start_time, end_time))
        if divider != 1:
            for i in range(0, len(interval.index)):
                interval.iloc[i, -1] = interval.iloc[i, -1] / divider
        interval.to_csv(self.csv_dir + output_filename, index=False)
        if check_freq:
            self.check_measurement_frequency(data)
        return 0

    def check_measurement_frequency(self, data):
        # Check if measurement frequency was within normal limits
        # Reset the flag file
        with open(self.csv_dir + "low_frequency_flag", 'w'):
            pass

        normal_meas_frequency = 312
        tolerance = 50
        low_frequency = data[data.iloc[:, -2] < normal_meas_frequency - tolerance]
        if not low_frequency.empty:
            logging.info("Low measurement frequency detected:")
            logging.info(low_frequency)
            with open(self.csv_dir + "low_frequency_timestamps.csv", 'a', newline='') as csvfile:
                csvwriter = csv.writer(csvfile)
                for index, row in low_frequency.iterrows():
                    csvwriter.writerow(row)
            with open(self.csv_dir + "low_frequency_flag", 'w', newline='') as flag:
                flag.write("Warning: unusually low measurement frequency detected")
            return False
        return True

    def generate_power_graph(self, csv_file, test_name):
        data = pd.read_csv(self.csv_dir + csv_file)
        start_time = data['time'].values[0]
        end_time = data['time'].values[data.index.max()]
        plt.figure(figsize=(20, 10))
        plt.set_loglevel('WARNING')

        # Show only hh-mm-ss part of the time at x-axis ticks
        data['time'] = data['time'].str[11:19]

        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['time'], data['power'], marker='o', linestyle='-', color='b')
        plt.yticks(fontsize=14)

        # Show full timestamps of the beginning and the end of the plotted time interval
        plt.suptitle(f'Device power consumption {start_time} - {end_time}', fontsize=18, fontweight='bold')

        # Add note to plot in case of issues in measurement frequency
        try:
            with open(self.csv_dir + "low_frequency_flag", 'r') as flag:
                low_frequency_note = flag.readline().strip()
        except FileNotFoundError:
            low_frequency_note = ""

        title_text = f'During "{test_name}"'
        if low_frequency_note:
            title_text += f'\n{low_frequency_note}'

        plt.title(title_text, loc='center', fontweight="bold", fontsize=16)
        plt.ylabel('Power (mW)', fontsize=16)
        plt.grid(True)
        plt.xticks(data['time'], rotation=45, fontsize=14)

        # Set maximum for tick number
        plt.locator_params(axis='x', nbins=40)

        plt.savefig(self.plot_dir + f'power_{test_name}.png')
        return

    def measured_max_power(self, csv_file):
        data = pd.read_csv(self.csv_dir + csv_file)
        max_value = 0
        for value in data['power']:
            if value > max_value:
                max_value = value
        return max_value

    def mean_power(self, csv_file):
        data = pd.read_csv(self.csv_dir + csv_file)
        mean_value = data['power'].mean()
        return mean_value

    def generate_param_graph(self, csv_file, param_label, param_unit, build_id):
        data = pd.read_csv(self.csv_dir + csv_file)
        start_time = data['time'].values[0]
        end_time = data['time'].values[data.index.max()]
        plt.figure(figsize=(20, 10))
        plt.set_loglevel('WARNING')

        # Show only hh-mm-ss part of the time at x-axis ticks
        data['time'] = data['time'].str[11:19]

        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['time'], data[param_label], marker='o', linestyle='-', color='b')
        plt.yticks(fontsize=14)

        # Show full timestamps of the beginning and the end of the plotted time interval
        title_text = f'Logged parameter {param_label} {start_time} - {end_time}'

        plt.title(title_text, loc='center', fontweight="bold", fontsize=16)
        plt.ylabel(param_unit, fontsize=16)
        plt.grid(True)
        plt.xticks(data['time'], rotation=45, fontsize=14)

        # Set maximum for tick number
        plt.locator_params(axis='x', nbins=40)

        plt.savefig(self.plot_dir + f'{param_label}_{build_id}.png')
        return
