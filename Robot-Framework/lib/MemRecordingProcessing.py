# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import os
import pandas
import logging
from robot.api.deco import keyword
from memory_plotting import add_percentage_columns, plot_grouped_metric, plot_grouped_metric_pair


class MemRecordingProcessing:
    """
    Utilities for merging per-VM memory recordings and plotting them.

    Input CSVs are expected to have the format:
      datetime,mem_total_kb,mem_avail_kb,swap_total_kb,swap_free_kb
    """

    def __init__(self, out_dir, plot_dir):
        self.out_dir = out_dir
        self.plot_dir = plot_dir
        os.makedirs(self.out_dir, exist_ok=True)
        os.makedirs(self.plot_dir, exist_ok=True)

    @keyword("Merge Mem Recordings And Plot")
    def merge_mem_recordings_and_plot(self, input_files, output_basename):
        """
        Merge per-VM recordings into one CSV and generate a plot.

        Args:
          input_files: Robot list of file paths (local) like [".../admin-vm.csv", ".../chrome-vm.csv"].
                       The VM name is taken from the filename stem after the last "__".
          output_basename: File base name (without extension) for outputs.

        Outputs:
          - <out_dir>/<output_basename>.csv
          - <plot_dir>/<output_basename>.png
        """
        if not input_files:
            raise AssertionError("No input mem recording files to merge")

        frames = []
        for path in input_files:
            path = str(path)
            if not os.path.exists(path):
                raise AssertionError(f"Mem recording file not found: {path}")

            vm = os.path.splitext(os.path.basename(path))[0]
            # Common naming is "memrec__<id>__<vm>.csv" but keep fallback.
            if "__" in vm:
                vm = vm.split("__")[-1]

            df = pandas.read_csv(path)
            required = {"datetime", "mem_total_kb", "mem_avail_kb", "swap_total_kb", "swap_free_kb"}
            missing = required - set(df.columns)
            if missing:
                raise AssertionError(f"{path} missing columns: {sorted(missing)}")

            df["vm"] = vm
            frames.append(df)

        plot_df = self._prepare_plot_df(pandas.concat(frames, ignore_index=True))

        out_csv = os.path.join(self.out_dir, f"{output_basename}.csv")
        plot_df.drop(columns=["datetime_dt"]).to_csv(out_csv, index=False)
        logging.info("Wrote merged mem recording to %s", out_csv)

        self._plot(plot_df, os.path.join(self.plot_dir, output_basename))
        for path in input_files:
            path = str(path)
            try:
                os.remove(path)
            except FileNotFoundError:
                logging.warning("Mem recording file already removed: %s", path)
            except OSError as exc:
                logging.warning("Failed to remove mem recording file %s: %s", path, exc)
        return out_csv

    def _add_usage_columns(self, df):
        df["mem_avail_mib"] = pandas.to_numeric(df["mem_avail_kb"], errors="coerce") / 1024.0
        df["mem_total_mib"] = pandas.to_numeric(df["mem_total_kb"], errors="coerce") / 1024.0
        df["swap_free_mib"] = pandas.to_numeric(df["swap_free_kb"], errors="coerce") / 1024.0
        df["swap_total_mib"] = pandas.to_numeric(df["swap_total_kb"], errors="coerce") / 1024.0
        add_percentage_columns(
            df,
            [
                ("mem_avail_mib", "mem_total_mib", "mem_avail_pct"),
                ("swap_free_mib", "swap_total_mib", "swap_free_pct"),
            ],
        )

    def _prepare_plot_df(self, df):
        plot_df = df.copy()
        plot_df["datetime_dt"] = pandas.to_datetime(plot_df["datetime"], errors="coerce")
        invalid_datetime_rows = int(plot_df["datetime_dt"].isna().sum())
        if invalid_datetime_rows:
            logging.warning(
                "Dropping %d mem recording row(s) with invalid datetime values",
                invalid_datetime_rows,
            )
        plot_df = plot_df.dropna(subset=["datetime_dt"])
        plot_df["datetime"] = plot_df["datetime_dt"].dt.strftime("%Y-%m-%d %H:%M:%S")
        self._add_usage_columns(plot_df)
        return plot_df

    def _plot(self, df, out_base):
        pair_plots = [
            ("mem_avail_mib", "mem_total_mib", "mem_avail", "Mem Available/Total (MiB)", "avail"),
            ("swap_free_mib", "swap_total_mib", "swap_free", "Swap Free/Total (MiB)", "free"),
        ]
        for value_col, total_col, file_suffix, title, value_label in pair_plots:
            plot_grouped_metric_pair(
                df,
                "datetime_dt",
                value_col,
                total_col,
                f"{out_base}__{file_suffix}.png",
                title,
                "Time",
                value_label=value_label,
            )

        pct_plots = [
            ("mem_avail_pct", "mem_avail_pct", "Mem Available (%)"),
            ("swap_free_pct", "swap_free_pct", "Swap Free (%)"),
        ]
        for value_col, file_suffix, title in pct_plots:
            plot_grouped_metric(
                df,
                "datetime_dt",
                value_col,
                f"{out_base}__{file_suffix}.png",
                title,
                "Time",
                y_limits=(0, 100),
            )
