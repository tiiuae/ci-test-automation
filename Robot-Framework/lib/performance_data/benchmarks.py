import csv
import os

import matplotlib.pyplot as plt

from performance_data.plotting_helpers import (
    plot_standard_history_series,
    plot_standard_latency_panel,
    save_plot,
    start_plot,
)
from performance_thresholds import thresholds


class BenchmarkProcessor:
    def __init__(self, processing):
        self.processing = processing

    def read_cpu_csv_and_plot(self, test_name):
        data = {
            'commit': [],
            'cpu_events_per_second': [],
            'min_latency': [],
            'avg_latency': [],
            'max_latency': [],
            'cpu_events_per_thread': [],
            'cpu_events_per_thread_stddev': [],
        }

        if "One thread" in test_name or "1thread" in test_name:
            threshold = thresholds['cpu']['single']
        else:
            threshold = thresholds['cpu']['multi']

        return_statistics, statistics = self.processing.stats.prepare_plot_statistics(
            test_name,
            data,
            ['cpu_events_per_second'],
            [threshold],
        )

        if "VMs" in test_name:
            return return_statistics

        start_plot()

        plot_standard_history_series(
            data['commit'],
            data['cpu_events_per_second'],
            f'CPU Events per Second / Threshold: {threshold}',
            'CPU Events per Second',
            subplot=1,
            total_subplots=3,
            statistics=statistics,
            deviation_plotter=self.processing.stats.plot_marginals_and_deviations,
        )

        plot_standard_history_series(
            data['commit'],
            data['cpu_events_per_thread'],
            'CPU Events per Thread',
            'CPU Events per Thread',
            subplot=2,
            total_subplots=3,
        )
        plt.errorbar(
            data['commit'],
            data['cpu_events_per_thread'],
            yerr=data['cpu_events_per_thread_stddev'],
            capsize=4,
        )
        plot_standard_latency_panel(
            data['commit'],
            data['avg_latency'],
            data['max_latency'],
            data['min_latency'],
            subplot=3,
            total_subplots=3,
        )

        plt.suptitle(
            f'{test_name}\nBuild type: {self.processing.build_type}, Device: {self.processing.device}',
            fontsize=18,
            fontweight='bold',
        )

        save_plot(self.processing.plot_dir, self.processing.device, test_name)
        return return_statistics

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
        }

        dictionary_key_name = None
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

        return_statistics, statistics = self.processing.stats.prepare_plot_statistics(
            test_name,
            data,
            ['data_transfer_speed'],
            [threshold],
            result_key_changes={'data_transfer_speed': dictionary_key_name},
        )

        if "VMs" in test_name:
            return return_statistics

        start_plot()

        plot_standard_history_series(
            data['commit'],
            data['operations_per_second'],
            'Operations per Second',
            'Operations per Second',
            subplot=1,
            total_subplots=3,
            ticklabel_style='sci',
            use_math_text=True,
        )
        plot_standard_history_series(
            data['commit'],
            data['data_transfer_speed'],
            f'Data Transfer Speed / Threshold: {threshold}',
            'Data Transfer Speed (MiB/sec)',
            subplot=2,
            total_subplots=3,
            statistics=statistics,
            deviation_plotter=self.processing.stats.plot_marginals_and_deviations,
        )
        plot_standard_latency_panel(
            data['commit'],
            data['avg_latency'],
            data['max_latency'],
            data['min_latency'],
            subplot=3,
            total_subplots=3,
        )

        plt.suptitle(
            f'{test_name}\nBuild type: {self.processing.build_type}, Device: {self.processing.device}',
            fontsize=18,
            fontweight='bold',
        )

        save_plot(self.processing.plot_dir, self.processing.device, test_name)
        return return_statistics

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
        }

        if "write" in test_name:
            threshold = thresholds['fileio']['wr']
        else:
            if "X1" in self.processing.device:
                threshold = thresholds['fileio']['rd_lenovo-x1']
            else:
                threshold = thresholds['fileio']['rd']

        return_statistics, statistics = self.processing.stats.prepare_plot_statistics(
            test_name,
            data,
            ['throughput'],
            [threshold],
        )

        start_plot()

        plot_standard_history_series(
            data['commit'],
            data['file_operations'],
            'File operation',
            'File operation per second',
            subplot=1,
            total_subplots=3,
        )
        plot_standard_history_series(
            data['commit'],
            data['throughput'],
            f'Throughput / Threshold: {threshold}',
            'Throughput, MiB/s',
            subplot=2,
            total_subplots=3,
            statistics=statistics,
            deviation_plotter=self.processing.stats.plot_marginals_and_deviations,
        )
        plot_standard_latency_panel(
            data['commit'],
            data['avg_latency'],
            data['max_latency'],
            data['min_latency'],
            subplot=3,
            total_subplots=3,
        )

        plt.suptitle(
            f'{test_name}\nBuild type: {self.processing.build_type}, device: {self.processing.device}',
            fontsize=18,
            fontweight='bold',
        )

        save_plot(self.processing.plot_dir, self.processing.device, test_name)
        return return_statistics

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

        return_statistics, statistics = self.processing.stats.prepare_plot_statistics(
            test_name,
            data,
            ['difference'],
            [threshold],
        )

        start_plot()

        plot_standard_history_series(
            data['commit'],
            data['difference'],
            'Effect of resource exhaustion attack from another vm',
            'Decrease of performance in ref vm (%)',
            subplot=1,
            total_subplots=2,
            statistics=statistics,
            deviation_plotter=self.processing.stats.plot_marginals_and_deviations,
        )

        plt.suptitle(
            f'{test_name}\nBuild type: {self.processing.build_type}, Device: {self.processing.device}\n'
            f'Threshold {threshold}',
            fontsize=18,
            fontweight='bold',
        )

        save_plot(self.processing.plot_dir, self.processing.device, test_name)
        return return_statistics


class VmBenchmarkProcessor:
    def __init__(self, processing):
        self.processing = processing

    def read_vms_data_csv_and_plot(self, test_name, vms_dict):
        tests = [
            'cpu_1thread',
            'memory_read_1thread',
            'memory_write_1thread',
            'cpu',
            'memory_read',
            'memory_write',
        ]
        data = {test: {} for test in tests}
        plot_builds = []

        for vm_name, threads in vms_dict.items():
            for test in tests:
                if "1thread" not in test and int(threads) == 1:
                    continue

                file_name = (
                    f"{self.processing.data_dir}/{self.processing.device}_{vm_name}_{test_name}_{test}.csv"
                )
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
                        modified_build = (
                            f"{build}-{build_counter[build]}"
                            if build_counter[build] > 0 else build
                        )
                        build_data.append((modified_build, float(row[1 if 'cpu' in test else 2])))

                    if build_data:
                        build_data = build_data[-10:]
                        data[test][vm_name] = {
                            'commit': [build[0] for build in build_data],
                            'values': [build[1] for build in build_data],
                            'threads': threads,
                        }
                        if vm_name == "net-vm" and test == 'cpu_1thread':
                            for build in [build[0] for build in build_data]:
                                plot_builds.append(build)

        for test in tests:
            plt.figure(figsize=(10, 6))
            for i, (vm_name, vm_data) in enumerate(data[test].items()):
                if vm_data:
                    indices = []
                    plot_values = []
                    for build_id in plot_builds:
                        if build_id in vm_data['commit']:
                            indices.append(plot_builds.index(build_id))
                            plot_values.append(vm_data['values'][vm_data['commit'].index(build_id)])
                    plt.bar(
                        [x + i * 0.1 for x in indices],
                        plot_values,
                        width=0.1,
                        label=(
                            f"{vm_name} ({vm_data['threads']} threads)"
                            if "1thread" not in test else vm_name
                        ),
                    )
            plt.title(
                f'Comparison of {test} results for VMs\n'
                f'Build type: {self.processing.build_type}, Device: {self.processing.device}'
            )
            plt.xlabel('Builds')
            plt.ylabel('Data transfer speed, MB/s' if 'memory' in test else 'Events per second')
            plt.xticks(range(len(plot_builds)), plot_builds, rotation=90, fontsize=10)
            plt.legend(loc='upper left')
            plt.tight_layout()
            plt.savefig(
                self.processing.plot_dir
                + f'{self.processing.device}_{test_name}_{test}.png'
            )
            plt.close()
