import logging
import os

import pandas

from memory_plotting import add_percentage_columns, plot_vm_memory_snapshot
from performance_thresholds import thresholds


class VmMemoryProcessor:
    def __init__(self, processing):
        self.processing = processing

    def save_vm_memory_snapshot_data(self, test_name, vm_mem_data):
        file_path = os.path.join(
            self.processing.data_dir,
            f"{self.processing.device}_{test_name}.csv",
        )
        commit_id = self.processing.build_number + "-" + self.processing.commit

        row = {"commit": commit_id, "device": self.processing.device} | dict(vm_mem_data)
        if os.path.exists(file_path):
            df = pandas.read_csv(file_path)
            for col in row.keys():
                if col not in df.columns:
                    df[col] = pandas.NA
            for col in df.columns:
                if col not in row:
                    row[col] = pandas.NA
            df = pandas.concat(
                [df, pandas.DataFrame([row], columns=df.columns)],
                ignore_index=True,
            )
        else:
            df = pandas.DataFrame([row])

        df.to_csv(file_path, index=False)
        return self.read_vm_memory_snapshot_csv_and_plot(test_name)

    def read_vm_memory_snapshot_csv_and_plot(self, test_name):
        data = pandas.read_csv(
            os.path.join(
                self.processing.data_dir,
                f"{self.processing.device}_{test_name}.csv",
            )
        )
        data["build_index"] = list(range(len(data.index)))
        plot_df = self.normalize_vm_memory_snapshot_df(data)
        if plot_df.empty:
            logging.warning("No VM memory snapshot data to process for %s", test_name)
            plot_vm_memory_snapshot(
                test_name,
                data,
                plot_df,
                self.processing.plot_dir,
                self.processing.device,
                self.processing.build_type,
            )
            return {}

        threshold = thresholds["vm_memory_snapshot"]["mem_avail_pct"]
        return_statistics, statistics = self.build_vm_memory_analysis(plot_df, threshold)
        self.processing.csv_store.write_statistics_to_csv(test_name, statistics)
        plot_vm_memory_snapshot(
            test_name,
            data,
            plot_df,
            self.processing.plot_dir,
            self.processing.device,
            self.processing.build_type,
        )
        return return_statistics

    def build_vm_memory_analysis(self, plot_df, threshold):
        plot_df["mem_avail_pct_flag"] = 0
        current_build_index = plot_df["build_index"].max()
        return_statistics = {}
        statistics = self.init_vm_memory_stats_dict()

        for vm, vm_df in plot_df.dropna(subset=["mem_avail_pct"]).groupby("vm", sort=False):
            vm_statistics = self.analyze_vm_memory_series(vm, vm_df, threshold, plot_df)
            for key in statistics:
                statistics[key].extend(vm_statistics[key])
            if (
                vm_statistics["build_index"]
                and vm_statistics["build_index"][-1] == current_build_index
            ):
                return_statistics[vm] = vm_statistics["statistics_block"][-1]

        del statistics["build_index"]
        del statistics["statistics_block"]
        return return_statistics, statistics

    @staticmethod
    def init_vm_memory_stats_dict():
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

    def analyze_vm_memory_series(self, vm, vm_df, threshold, plot_df):
        statistics = self.init_vm_memory_stats_dict()
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
            ) = self.processing.stats.analyze_performance_value(
                data_column,
                baseline_start,
                threshold,
                deviation_counter,
                deviations,
                new_baseline_start,
                row_index,
            )

            plot_df.loc[df_index, "mem_avail_pct_flag"] = statistics_block["flag"]
            self.append_vm_memory_stat_row(statistics, row, vm, statistics_block)

        return statistics

    @staticmethod
    def append_vm_memory_stat_row(statistics, row, vm, statistics_block):
        statistics["commit"].append(row["commit"])
        statistics["vm"].append(vm)
        statistics["build_index"].append(row["build_index"])
        statistics["statistics_block"].append(statistics_block)
        for key in statistics_block:
            statistics[key].append(statistics_block[key])

    @staticmethod
    def normalize_vm_memory_snapshot_df(df):
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
