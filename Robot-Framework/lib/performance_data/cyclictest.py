import csv

import matplotlib.pyplot as plt
import matplotlib.ticker as mticker

from output_parser import (
    parse_cyclictest_histogram,
    parse_cyclictest_histogram_overflows,
    parse_cyclictest_results,
    parse_cyclictest_spike_count,
    parse_cyclictest_spikes,
)
from performance_thresholds import static_thresholds


class CyclictestProcessor:
    CYCLICTEST_VARIANTS = ["t1_p80", "t1_p95", "tnproc_p80", "tnproc_p95"]
    CYCLICTEST_METRICS = [
        "min_latency_ms",
        "avg_latency_ms",
        "max_latency_ms",
        "overflow_count",
    ]
    CYCLICTEST_LABELS = {
        "t1_p80": "t1 p80",
        "t1_p95": "t1 p95",
        "tnproc_p80": "t$(nproc) p80",
        "tnproc_p95": "t$(nproc) p95",
    }
    CYCLICTEST_PLOT_DEFS = [
        ("min_latency_ms", "Min latency (ms)", "Min latency"),
        ("avg_latency_ms", "Avg latency (ms)", "Avg latency"),
        ("max_latency_ms", "Max latency (ms)", "Max latency"),
        ("overflow_count", "Overflow samples", "Histogram overflows"),
    ]

    def __init__(self, processing):
        self.processing = processing

    @staticmethod
    def _format_latency_us(value_us):
        if value_us >= 1000:
            return f"{value_us / 1000.0:.3f} ms"
        return f"{value_us} us"

    @staticmethod
    def _format_thread_counts(counts_per_thread):
        if not counts_per_thread:
            return "none"
        return ", ".join(
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
            shown_cycles = ",".join(
                str(cycle) for cycle in cycles[:max_cycles_per_thread]
            )
            if len(cycles) > max_cycles_per_thread:
                shown_cycles += ",..."
            cycle_chunks.append(f"t{thread_id}=[{shown_cycles}]")
        return ", ".join(cycle_chunks) if cycle_chunks else "none"

    def parse_cyclictest_results_file(self, file_path):
        with open(file_path, "r", encoding="utf-8") as file:
            return parse_cyclictest_results(file.read())

    def get_failed_cyclictest_variants(self, statistics_dict):
        failed_variants = []
        suffixes = ("_avg_latency_ms", "_overflow_count")

        for key, value in statistics_dict.items():
            if value["flag"] <= 0:
                continue
            variant_name = key
            for suffix in suffixes:
                if key.endswith(suffix):
                    variant_name = key[:-len(suffix)]
                    break
            if variant_name not in failed_variants:
                failed_variants.append(variant_name)

        return failed_variants

    def get_cyclictest_threshold_target(self, target):
        if "orin" in self.processing.device.lower():
            return f"orin-{target}"
        return target

    def get_cyclictest_latency_threshold_us(self, target, variant_name):
        threshold_target = self.get_cyclictest_threshold_target(target)
        return static_thresholds["cyclictest"][threshold_target][
            f"latency_threshold_us_{variant_name}"
        ]

    def get_cyclictest_histogram_limit(self, target, variant_name):
        return self.get_cyclictest_latency_threshold_us(target, variant_name)

    def generate_cyclictest_histogram_plot(
        self,
        source_file,
        plot_name,
        plot_title,
        overflow_start_us,
    ):
        with open(source_file, "r", encoding="utf-8") as file:
            output = file.read()

        histogram = parse_cyclictest_histogram(output)
        overflow_data = parse_cyclictest_histogram_overflows(output)
        summary = parse_cyclictest_results(output)
        bucket_width_us = 50
        aggregated_counts = {}

        for bucket_us, count in zip(histogram["buckets_us"], histogram["counts"]):
            if bucket_us < 0:
                continue
            range_start_us = (bucket_us // bucket_width_us) * bucket_width_us
            aggregated_counts[range_start_us] = (
                aggregated_counts.get(range_start_us, 0) + count
            )

        overflow_count = overflow_data["total_count"]
        if overflow_count > 0:
            aggregated_counts[int(overflow_start_us)] = (
                aggregated_counts.get(int(overflow_start_us), 0) + overflow_count
            )

        x_values = [bucket / 1000.0 for bucket in sorted(aggregated_counts.keys())]
        y_values = [aggregated_counts[bucket] for bucket in sorted(aggregated_counts.keys())]

        plt.figure(figsize=(20, 8))
        plt.set_loglevel("WARNING")
        plt.bar(
            x_values,
            y_values,
            width=bucket_width_us / 1000.0,
            align="edge",
            color="b",
        )
        plt.xlabel("Latency bucket start (ms)", fontsize=16)
        plt.ylabel("Samples", fontsize=16)
        plt.title(plot_title, fontsize=18, fontweight="bold")
        plt.yscale("log", base=10)
        plt.xlim(left=0)
        if overflow_count > 0:
            overflow_start_ms = int(overflow_start_us) / 1000.0
            bucket_width_ms = bucket_width_us / 1000.0
            overflow_end_ms = overflow_start_ms + bucket_width_ms
            tick_positions = [tick for tick in plt.xticks()[0] if tick < overflow_start_ms]
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
                f"Overflows > {self._format_latency_us(int(overflow_start_us))}: "
                f"{overflow_count}"
            ),
            ha="right",
            fontsize=12,
        )
        plt.tight_layout()
        plt.savefig(self.processing.plot_dir + f"{plot_name}.png")
        plt.close()

    def generate_cyclictest_spike_plot(
        self,
        spike_file,
        plot_name,
        plot_title,
        histogram_limit_us=50000,
    ):
        with open(spike_file, "r", encoding="utf-8") as file:
            output = file.read()

        spikes = parse_cyclictest_spikes(output)
        if not spikes:
            return False

        bucket_width_us = 50
        aggregated_counts = {}
        for spike in spikes:
            latency_us = spike["latency_us"]
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
        min_spike_us = min(spike["latency_us"] for spike in spikes)
        max_spike_us = max(spike["latency_us"] for spike in spikes)
        max_spike_bucket_us = max(aggregated_counts.keys())
        min_plot_end_ms = histogram_limit_ms + bucket_width_ms * 10
        max_spike_end_ms = max_spike_bucket_us / 1000.0 + bucket_width_ms
        plot_end_ms = max(min_plot_end_ms, max_spike_end_ms)

        plt.figure(figsize=(20, 8))
        plt.set_loglevel("WARNING")
        plt.bar(
            x_values,
            y_values,
            width=bucket_width_us / 1000.0,
            align="edge",
            color="darkred",
        )
        plt.xlabel("Spike latency bucket start (ms)", fontsize=16)
        plt.ylabel("Samples", fontsize=16)
        plt.title(plot_title, fontsize=18, fontweight="bold")
        plt.yscale("log", base=10)
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
            ha="right",
            fontsize=12,
        )
        plt.tight_layout()
        plt.savefig(self.processing.plot_dir + f"{plot_name}.png")
        plt.close()
        return True

    def get_cyclictest_histogram_overflow_count(self, histogram_file):
        with open(histogram_file, "r", encoding="utf-8") as file:
            overflow_data = parse_cyclictest_histogram_overflows(file.read())

        return overflow_data["total_count"]

    def get_cyclictest_histogram_overflow_report(
        self,
        histogram_file,
        overflow_start_us,
        max_cycles_per_thread=5,
    ):
        with open(histogram_file, "r", encoding="utf-8") as file:
            overflow_data = parse_cyclictest_histogram_overflows(file.read())

        limit_us = int(overflow_start_us)
        return (
            f"Histogram overflows > {self._format_latency_us(limit_us)}: "
            f"{overflow_data['total_count']}"
            f" | Per-thread: "
            f"{self._format_thread_counts(overflow_data['counts_per_thread'])}"
            f" | Cycles: "
            f"{self._format_thread_cycles(overflow_data['cycles_per_thread'], int(max_cycles_per_thread))}"
        )

    def get_cyclictest_spike_report(
        self,
        spike_file,
        overflow_start_us,
        max_spikes_to_show=20,
    ):
        with open(spike_file, "r", encoding="utf-8") as file:
            output = file.read()

        spikes = parse_cyclictest_spikes(output)
        count = parse_cyclictest_spike_count(output)

        limit_us = int(overflow_start_us)
        if count == 0:
            return (
                "Debug spike run did not report per-spike durations "
                f"above {self._format_latency_us(limit_us)}"
            )

        durations = ", ".join(
            self._format_latency_us(spike["latency_us"])
            for spike in spikes[:int(max_spikes_to_show)]
        )
        if count > int(max_spikes_to_show):
            durations += ", ..."

        return f"Debug spike run reported {count} spike samples | Durations: {durations}"

    def read_cyclictest_latency_csv(self, test_name, data):
        data_key_list = list(data.keys())
        build_counter = {}

        with open(
            f"{self.processing.data_dir}{self.processing.device}_{test_name}.csv",
            "r",
        ) as csvfile:
            csvreader = csv.reader(csvfile)
            for row in csvreader:
                if row[-1] != self.processing.device:
                    continue

                build = str(row[0])
                if build in build_counter:
                    build_counter[build] += 1
                    modified_build = f"{build}-{build_counter[build]}"
                else:
                    build_counter[build] = 0
                    modified_build = build
                data["commit"].append(modified_build)

                # Maintain reader backward compatibility with data rows which don't include threshold values
                value_count = min(len(row) - 1, len(data_key_list))
                for key_index in range(1, value_count):
                    data[data_key_list[key_index]].append(float(row[key_index]))
                for key in data_key_list[value_count:]:
                    data[key].append(None)

    @staticmethod
    def find_cyclictest_threshold_change_indexes(data, variants):
        change_indexes = []
        result_count = len(data["commit"])

        for result_index in range(1, result_count):
            for variant in variants:
                threshold_key = f"{variant}_latency_threshold_us"
                previous_threshold = data[threshold_key][result_index - 1]
                current_threshold = data[threshold_key][result_index]
                if previous_threshold is None or current_threshold is None:
                    continue
                if previous_threshold != current_threshold:
                    change_indexes.append(result_index)
                    break

        return change_indexes

    @staticmethod
    def get_saved_cyclictest_latency_threshold_us(data, variant):
        threshold_key = f"{variant}_latency_threshold_us"
        threshold = data[threshold_key][-1]
        if threshold is None:
            raise ValueError(f"Missing {threshold_key} from latest cyclictest result")
        return threshold

    @classmethod
    def init_cyclictest_latency_data(cls):
        data = {"commit": []}

        for variant in cls.CYCLICTEST_VARIANTS:
            for metric in cls.CYCLICTEST_METRICS:
                data[f"{variant}_{metric}"] = []

        for variant in cls.CYCLICTEST_VARIANTS:
            data[f"{variant}_latency_threshold_us"] = []

        return data

    def build_cyclictest_limit_checks(self, data):
        limit_checks = {}
        overflow_count_limit = static_thresholds["cyclictest"]["latency_overflow_count"]

        for variant in self.CYCLICTEST_VARIANTS:
            avg_latency_key = f"{variant}_avg_latency_ms"
            overflow_count_key = f"{variant}_overflow_count"
            avg_latency_limit = (
                self.get_saved_cyclictest_latency_threshold_us(
                    data,
                    variant,
                )
                / 1000.0
            )
            limit_checks[avg_latency_key] = self.processing.stats.build_static_limit_check(
                data[avg_latency_key][-1],
                avg_latency_limit,
                self.processing.low_limit,
            )
            limit_checks[overflow_count_key] = self.processing.stats.build_static_limit_check(
                data[overflow_count_key][-1],
                overflow_count_limit,
                0,
            )

        return limit_checks

    @staticmethod
    def draw_cyclictest_threshold_change_lines(threshold_change_indexes):
        for change_index in threshold_change_indexes:
            plt.axvline(
                x=change_index - 0.5,
                color="k",
                linestyle="-.",
                linewidth=3,
            )

    def plot_cyclictest_latency_metric(
        self,
        test_name,
        data,
        metric_key,
        axis_label,
        title,
        threshold_change_indexes,
    ):
        plt.figure(figsize=(20, 10))
        plt.set_loglevel("WARNING")
        for variant in self.CYCLICTEST_VARIANTS:
            key = f"{variant}_{metric_key}"
            plt.plot(
                data["commit"],
                data[key],
                marker="o",
                linestyle="-",
                label=self.CYCLICTEST_LABELS[variant],
            )
        plt.ylabel(axis_label, fontsize=16)
        plt.xlabel("Build Number", fontsize=16)
        ax = plt.gca()
        ax.tick_params(axis="y", labelsize=14)
        plt.xticks(data["commit"], rotation=90, fontsize=10)
        plt.grid(True)
        plt.legend(loc="upper left")

        if metric_key == "overflow_count":
            title_threshold = static_thresholds["cyclictest"]["latency_overflow_count"]
            ax.yaxis.set_major_locator(mticker.MaxNLocator(integer=True))
            plt.axhline(
                y=title_threshold,
                color="k",
                linestyle="-.",
                linewidth=1.5,
            )
            self.draw_cyclictest_threshold_change_lines(threshold_change_indexes)
        elif metric_key == "avg_latency_ms":
            title_threshold = "variant specific latency_threshold_us_*"
        else:
            title_threshold = "not monitored"

        plt.title(
            f"{title} / Threshold: {title_threshold}",
            loc="right",
            fontweight="bold",
            fontsize=16,
        )
        plt.suptitle(
            f"{test_name}\nBuild type: {self.processing.build_type}, "
            f"Device: {self.processing.device}",
            fontsize=18,
            fontweight="bold",
        )
        plt.tight_layout()
        plt.savefig(
            self.processing.plot_dir
            + f"{self.processing.device}_{test_name}_{metric_key}.png"
        )
        plt.close()

    def read_cyclictest_latency_csv_and_plot(self, test_name):
        data = self.init_cyclictest_latency_data()

        self.read_cyclictest_latency_csv(test_name, data)
        limit_checks = self.build_cyclictest_limit_checks(data)
        self.processing.stats.trim_plot_data(data)
        threshold_change_indexes = self.find_cyclictest_threshold_change_indexes(
            data,
            self.CYCLICTEST_VARIANTS,
        )

        for metric_key, axis_label, title in self.CYCLICTEST_PLOT_DEFS:
            self.plot_cyclictest_latency_metric(
                test_name,
                data,
                metric_key,
                axis_label,
                title,
                threshold_change_indexes,
            )

        return limit_checks
