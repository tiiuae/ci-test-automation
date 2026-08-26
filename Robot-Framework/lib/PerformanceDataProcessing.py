# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

from robot.api.deco import keyword
from performance_data.app_launch import AppLaunchProcessor
from performance_data.benchmarks import BenchmarkProcessor, VmBenchmarkProcessor
from performance_data.boot_time import BootTimeProcessor
from performance_data.csv_store import PerformanceCsvStore
from performance_data.cyclictest import CyclictestProcessor
from performance_data.networking_speed import NetworkingSpeedProcessor
from performance_data.plotting_helpers import generate_ballooning_graph_plot
from performance_data.stats import PerformanceStatistics
from performance_data.vm_memory import VmMemoryProcessor


class PerformanceDataProcessing:

    def __init__(self, device, build_number, commit, job, perf_data_dir, config_path, plot_dir, low_limit):
        self.device = device
        self.build_number = build_number
        self.commit = commit[:6]
        self.perf_data_dir = perf_data_dir
        self.config_path = config_path
        self.plot_dir = plot_dir
        self.app_launch = AppLaunchProcessor(self)
        self.benchmarks = BenchmarkProcessor(self)
        self.vm_benchmarks = VmBenchmarkProcessor(self)
        self.boot_time = BootTimeProcessor(self)
        self.csv_store = PerformanceCsvStore(self)
        self.stats = PerformanceStatistics(self)
        self.cyclictest = CyclictestProcessor(self)
        self.networking_speed = NetworkingSpeedProcessor(self)
        self.vm_memory = VmMemoryProcessor(self)
        self.data_dir = self.csv_store.create_result_dirs()
        if len(job.split(".")) > 1:
            self.build_type = job.split(".")[1]
        else:
            self.build_type = "unknown"
        self.zero_result_flag = -100
        self.low_limit = float(low_limit)
        self.default_low_limit = float(low_limit)

    # --- Configuration keywords ---

    @keyword
    def set_custom_low_limit(self, new_value):
        self.low_limit = float(new_value)

    @keyword
    def set_default_low_limit(self):
        self.low_limit = self.default_low_limit

    @keyword
    def get_data_dir(self):
        return self.data_dir

    @keyword
    def get_app_launch_threshold(self, app_thresholds, default_threshold, job, device_type):
        # Allow a single app-specific threshold value when it does not vary by target.
        if not isinstance(app_thresholds, dict):
            return app_thresholds

        for target in (device_type, job):
            if target in app_thresholds:
                return app_thresholds[target]

        return default_threshold

    # --- Ballooning keywords ---

    @keyword
    def generate_ballooning_graph(self, plot_dir, id, test_name):
        generate_ballooning_graph_plot(
            self.data_dir,
            plot_dir,
            self.device,
            id,
            test_name,
        )

    # --- Cyclictest keywords ---

    @keyword
    def parse_cyclictest_results_file(self, file_path):
        return self.cyclictest.parse_cyclictest_results_file(file_path)

    @keyword
    def get_failed_cyclictest_variants(self, statistics_dict):
        return self.cyclictest.get_failed_cyclictest_variants(statistics_dict)

    @keyword
    def get_cyclictest_histogram_limit(self, target, variant_name):
        return self.cyclictest.get_cyclictest_histogram_limit(target, variant_name)

    @keyword
    def generate_cyclictest_histogram_plot(
        self,
        source_file,
        plot_name,
        plot_title,
        overflow_start_us,
    ):
        self.cyclictest.generate_cyclictest_histogram_plot(
            source_file,
            plot_name,
            plot_title,
            overflow_start_us,
        )

    @keyword
    def generate_cyclictest_spike_plot(
        self,
        spike_file,
        plot_name,
        plot_title,
        histogram_limit_us=50000,
    ):
        return self.cyclictest.generate_cyclictest_spike_plot(
            spike_file,
            plot_name,
            plot_title,
            histogram_limit_us,
        )

    @keyword
    def get_cyclictest_histogram_overflow_count(self, histogram_file):
        return self.cyclictest.get_cyclictest_histogram_overflow_count(histogram_file)

    @keyword
    def get_cyclictest_histogram_overflow_report(
        self,
        histogram_file,
        overflow_start_us,
        max_cycles_per_thread=5,
    ):
        return self.cyclictest.get_cyclictest_histogram_overflow_report(
            histogram_file,
            overflow_start_us,
            max_cycles_per_thread,
        )

    @keyword
    def get_cyclictest_spike_report(
        self,
        spike_file,
        overflow_start_us,
        max_spikes_to_show=20,
    ):
        return self.cyclictest.get_cyclictest_spike_report(
            spike_file,
            overflow_start_us,
            max_spikes_to_show,
        )

    @keyword
    def save_cyclictest_latency_data(self, test_name, latency_data):
        return self.csv_store.write_test_data_and_read(
            test_name,
            latency_data,
            self.cyclictest.read_cyclictest_latency_csv_and_plot,
        )

    # --- Performance data keywords ---

    @keyword
    def read_cpu_csv_and_plot(self, test_name):
        return self.benchmarks.read_cpu_csv_and_plot(test_name)

    @keyword
    def read_mem_csv_and_plot(self, test_name):
        return self.benchmarks.read_mem_csv_and_plot(test_name)

    @keyword("Read VMs data CSV and plot")
    def read_vms_data_csv_and_plot(self, test_name, vms_dict):
        return self.vm_benchmarks.read_vms_data_csv_and_plot(test_name, vms_dict)

    @keyword
    def save_cpu_data(self, test_name, cpu_data):
        return self.csv_store.write_test_data_and_read(
            test_name,
            cpu_data,
            self.benchmarks.read_cpu_csv_and_plot,
        )

    @keyword("Save Boot time Data")
    def save_boot_time_data(self, test_name, boot_data):
        return self.csv_store.write_test_data_and_read(
            test_name,
            boot_data,
            self.boot_time.read_bootime_csv_and_plot,
        )

    @keyword
    def save_memory_data(self, test_name, memory_data):
        return self.csv_store.write_test_data_and_read(
            test_name,
            memory_data,
            self.benchmarks.read_mem_csv_and_plot,
        )

    @keyword
    def save_networking_speed_data(self, test_name, networking_speed_data):
        return self.csv_store.write_test_data_and_read(
            test_name,
            networking_speed_data,
            self.networking_speed.read_networking_speed_csv_and_plot,
        )

    @keyword
    def save_fileio_data(self, test_name, fileio_data):
        return self.csv_store.write_test_data_and_read(
            test_name,
            fileio_data,
            self.benchmarks.read_fileio_data_csv_and_plot,
        )

    @keyword
    def save_isolation_test_data(self, test_name, cpu_isolation_data):
        return self.csv_store.write_test_data_and_read(
            test_name,
            cpu_isolation_data,
            self.benchmarks.read_isolation_test_csv_and_plot,
        )

    @keyword
    def save_app_launch_time_data(self, test_name, data, threshold):
        return self.csv_store.write_test_data_and_read(
            test_name,
            data,
            self.app_launch.read_applaunch_csv_and_plot,
            threshold,
        )

    @keyword("Save VM Memory Snapshot Data")
    def save_vm_memory_snapshot_data(self, test_name, vm_mem_data):
        return self.vm_memory.save_vm_memory_snapshot_data(test_name, vm_mem_data)
