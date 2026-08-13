import math

import matplotlib.pyplot as plt

from performance_data.plotting_helpers import save_plot, start_plot
from performance_thresholds import thresholds


class BootTimeProcessor:
    def __init__(self, processing):
        self.processing = processing

    def read_bootime_csv_and_plot(self, test_name):
        if 'Shutdown' in test_name:
            threshold = [thresholds['shutdown_time']]
            monitored_values = ['shutdown_time']
            data = {
                'commit': [],
                'shutdown_time': [],
                'shutdown_time_power': [],
            }
        elif 'Orin' in test_name:
            threshold = [thresholds['boot_time']['response_to_ping']]
            monitored_values = ['response_to_ping']
            data = {
                'commit': [],
                'response_to_ping': [],
            }
        else:
            threshold = {
                'time_to_desktop': thresholds['boot_time']['time_to_desktop'],
                'response_to_ping': thresholds['boot_time']['response_to_ping'],
            }
            monitored_values = ['time_to_desktop', 'response_to_ping']
            data = {
                'commit': [],
                'time_to_desktop': [],
                'response_to_ping': [],
            }

        return_statistics, statistics = self.processing.stats.prepare_plot_statistics(
            test_name,
            data,
            monitored_values,
            threshold,
        )

        start_plot()

        if 'Shutdown' in test_name:
            return self._plot_shutdown_time(
                test_name,
                data,
                statistics,
                threshold,
                return_statistics,
            )

        plt.subplot(2, 1, 1)
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['response_to_ping'], marker='o', linestyle='-', color='b')
        if 'Orin' in test_name:
            index = ''
        else:
            index = '1'
        self.processing.stats.plot_marginals_and_deviations(
            data['commit'],
            statistics,
            40,
            index,
        )
        plt.yticks(fontsize=14)
        plt.title('Response to ping', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('seconds', fontsize=12)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=10)

        if 'Orin' not in test_name:
            plt.subplot(2, 1, 2)
            plt.ticklabel_format(axis='y', style='plain')
            plt.plot(data['commit'], data['time_to_desktop'], marker='o', linestyle='-', color='b')
            self.processing.stats.plot_marginals_and_deviations(
                data['commit'],
                statistics,
                40,
                '0',
            )
            plt.yticks(fontsize=14)
            plt.title('Time from reboot to desktop available', loc='right', fontweight="bold", fontsize=16)
            plt.ylabel('seconds', fontsize=12)
            plt.grid(True)
            plt.xticks(data['commit'], rotation=90, fontsize=10)

        plt.suptitle(
            f'{test_name}\nBuild type: {self.processing.build_type}, Device: {self.processing.device}\n'
            f'Threshold {threshold}',
            fontsize=18,
            fontweight='bold',
        )

        save_plot(self.processing.plot_dir, self.processing.device, test_name)
        return return_statistics

    def _plot_shutdown_time(
        self,
        test_name,
        data,
        statistics,
        threshold,
        return_statistics,
    ):
        while len(data['shutdown_time_power']) < len(data['commit']):
            data['shutdown_time_power'].append(float('nan'))
        plt.ticklabel_format(axis='y', style='plain')
        plt.plot(data['commit'], data['shutdown_time'], marker='o', linestyle='-', color='b', label='Serial')
        self.processing.stats.plot_marginals_and_deviations(
            data['commit'],
            statistics,
            40,
        )
        if any(not math.isnan(value) for value in data['shutdown_time_power']):
            plt.plot(
                data['commit'],
                data['shutdown_time_power'],
                marker='o',
                linestyle='-',
                color='g',
                label='Power',
            )
        plt.yticks(fontsize=14)
        plt.title('Shutdown time', loc='right', fontweight="bold", fontsize=16)
        plt.ylabel('seconds', fontsize=12)
        plt.grid(True)
        plt.xticks(data['commit'], rotation=90, fontsize=10)
        plt.legend()
        plt.suptitle(
            f'{test_name}\nBuild type: {self.processing.build_type}, Device: {self.processing.device}\n'
            f'Threshold {threshold}',
            fontsize=18,
            fontweight='bold',
        )
        save_plot(self.processing.plot_dir, self.processing.device, test_name)
        return return_statistics
