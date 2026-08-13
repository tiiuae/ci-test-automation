import csv
import logging

import matplotlib.pyplot as plt

from performance_data.plotting_helpers import save_plot, start_plot


class AppLaunchProcessor:
    def __init__(self, processing):
        self.processing = processing

    def _read_indexed_metric_csv(self, test_name, metric_index):
        with open(
            f"{self.processing.data_dir}{self.processing.device}_{test_name}.csv",
            'r',
        ) as csvfile:
            lines = csv.reader(csvfile)
            logging.info("Reading data from csv file...")

            build_counter = {}
            data = {"commit": [], "metric": []}

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
                    val = float(row[metric_index])
                except (IndexError, ValueError, TypeError):
                    val = float('nan')
                data['metric'].append(val)

        return data

    def read_applaunch_csv_and_plot(self, test_name, threshold):
        threshold = float(threshold)
        raw_data = self._read_indexed_metric_csv(test_name, 1)
        data = {
            'commit': raw_data['commit'],
            'launch_time': raw_data['metric'],
        }

        start_plot((20, 15))
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
        save_plot(
            self.processing.plot_dir,
            self.processing.device,
            test_name,
            close=True,
        )

        return False if data['launch_time'][-1] > threshold else True
