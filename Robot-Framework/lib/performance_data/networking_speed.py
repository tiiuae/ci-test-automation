import matplotlib.pyplot as plt

from performance_data.plotting_helpers import plot_standard_history_series, save_plot, start_plot
from performance_thresholds import thresholds


class NetworkingSpeedProcessor:
    def __init__(self, processing):
        self.processing = processing

    def read_networking_speed_csv_and_plot(self, test_name):
        data = {
            'commit': [],
            'tx': [],
            'rx': [],
        }
        threshold = thresholds['iperf']

        return_statistics, statistics = self.processing.stats.prepare_plot_statistics(
            test_name,
            data,
            ['tx', 'rx'],
            [threshold],
        )

        start_plot()

        plot_standard_history_series(
            data['commit'],
            data['tx'],
            'Transmitting Speed',
            'TX Speed (MBytes/sec)',
            subplot=1,
            total_subplots=2,
            statistics=statistics,
            result_index='0',
            deviation_plotter=self.processing.stats.plot_marginals_and_deviations,
        )
        plot_standard_history_series(
            data['commit'],
            data['rx'],
            'Receiving Speed',
            'RX Speed (MBytes/sec)',
            subplot=2,
            total_subplots=2,
            statistics=statistics,
            result_index='1',
            xlabel='Build Number',
            deviation_plotter=self.processing.stats.plot_marginals_and_deviations,
        )
        plt.suptitle(
            f'{test_name}\nBuild type: {self.processing.build_type}, Device: {self.processing.device}\n'
            f'Threshold: {threshold}',
            fontsize=18,
            fontweight='bold',
        )

        save_plot(self.processing.plot_dir, self.processing.device, test_name)
        return return_statistics
