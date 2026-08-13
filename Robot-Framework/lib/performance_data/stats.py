import csv
import logging

import matplotlib.pyplot as plt

from performance_thresholds import static_thresholds


class PerformanceStatistics:
    def __init__(self, processing):
        self.processing = processing

    @staticmethod
    def trim_plot_data(data, plot_limit=40):
        for key in data.keys():
            data[key] = data[key][-plot_limit:]

    def truncate(self, values, significant_figures):
        truncated_list = []
        for item in values:
            truncated_list.append(float(f"{item:.{significant_figures}g}"))
        return truncated_list

    def prepare_plot_statistics(
        self,
        test_name,
        data,
        monitored_values,
        threshold,
        low_limit_overrides=None,
        result_key_changes=None,
        plot_limit=40,
    ):
        return_statistics, statistics = self.calculate_statistics(
            test_name,
            data,
            monitored_values,
            threshold,
            low_limit_overrides,
        )
        if result_key_changes:
            for key, new_key in result_key_changes.items():
                return_statistics[new_key] = return_statistics[key]
                del return_statistics[key]
        self.trim_plot_data(data, plot_limit)
        return return_statistics, statistics

    def detect_deviation(
        self,
        data_column,
        baseline_start,
        threshold,
        deviations_in_row,
        deviations=None,
        low_limit=None,
    ):
        if deviations is None:
            deviations = []

        flag = 0
        baseline_end = 0
        last_measurement = data_column[-1]
        if low_limit is None:
            low_limit = self.processing.low_limit

        if deviations_in_row < self.processing.zero_result_flag + 1:
            deviations_in_row = 0

        data_column_cut = data_column[baseline_start:-1]

        if len(data_column_cut) - len(deviations) > 0:
            sum_deviations = sum([data_column[i] for i in deviations])
            mean = (sum(data_column_cut) - sum_deviations) / (
                len(data_column_cut) - len(deviations)
            )

            data_sum = 0
            baseline_values = 0
            for i in range(baseline_start, len(data_column) - 1 - abs(deviations_in_row)):
                if not data_column[i] < self.processing.low_limit:
                    baseline_values += 1
                    data_sum = (data_column[i] - mean) ** 2 + data_sum
                    baseline_end = i
            if baseline_values > 0:
                pstd = (data_sum / baseline_values) ** (1 / 2)
            else:
                pstd = 0

            if type(threshold) == str:
                if "%" in threshold:
                    threshold_float = mean * float(threshold[:-1]) / 100
                elif "std" in threshold:
                    threshold_float = pstd * float(threshold[:-3])
                    if threshold_float > mean / 3:
                        threshold_float = mean / 3
                else:
                    logging.info("Incorrect threshold format: ")
                    logging.info(threshold)
                    return
                threshold = self.truncate([threshold_float], 3)[0]

                if threshold < 0.001:
                    threshold = last_measurement

            d = [0, 0]
            d[0] = last_measurement - mean
            d[1] = last_measurement - data_column[baseline_start]

            if d[0] < -threshold:
                flag = -1

            if d[0] > threshold:
                flag = 1

            upper_marginal = mean + threshold
            lower_marginal = mean - threshold

            if lower_marginal < low_limit:
                lower_marginal = low_limit

            stats = self.truncate(
                [mean, pstd] + d
                + [
                    data_column[baseline_end],
                    data_column[baseline_start],
                    upper_marginal,
                    lower_marginal,
                ],
                5,
            )
        else:
            stats = [0] * 8
            stats[0] = last_measurement
            stats[4] = last_measurement
            stats[5] = last_measurement
            stats[6] = low_limit
            stats[7] = low_limit

        if last_measurement < low_limit:
            flag = self.processing.zero_result_flag

        return {
            "flag": flag,
            "threshold": threshold,
            "d_baseline_start": stats[3],
            "d_mean": stats[2],
            "baseline_start": stats[5],
            "baseline_mean": stats[0],
            "baseline_end": stats[4],
            "baseline_std": stats[1],
            "upper_marginal": stats[6],
            "lower_marginal": stats[7],
            "measurement": last_measurement,
        }

    def analyze_performance_value(
        self,
        data_column,
        baseline_start,
        threshold,
        deviation_counter,
        deviations,
        new_baseline_start,
        row_index,
        low_limit=None,
    ):
        statistics_block = self.detect_deviation(
            data_column,
            baseline_start,
            threshold,
            deviation_counter,
            deviations,
            low_limit,
        )

        flag = statistics_block["flag"]
        if flag != 0:
            deviations.append(row_index)
            if abs(deviation_counter) < 1:
                new_baseline_start = row_index
            elif flag * deviation_counter < 0:
                deviation_counter = 0
                new_baseline_start = row_index

            deviation_counter += flag
            statistics_block["flag"] = flag * abs(deviation_counter)
            if flag != self.processing.zero_result_flag:
                if deviation_counter < self.processing.zero_result_flag:
                    deviation_counter = -1
                    new_baseline_start = row_index
                if abs(deviation_counter) > static_thresholds["wait_until_reset"] - 1:
                    deviation_counter = 0
                    deviations = []
                    baseline_start = new_baseline_start
            else:
                deviation_counter = -1
                statistics_block["flag"] = self.processing.zero_result_flag
        else:
            deviation_counter = 0

        if low_limit is None:
            low_limit = self.processing.low_limit

        if data_column[baseline_start] < low_limit and data_column[-1] > low_limit:
            deviation_counter = 0
            deviations = []
            baseline_start = row_index

        return (
            statistics_block,
            baseline_start,
            new_baseline_start,
            deviation_counter,
            deviations,
        )

    def calculate_statistics(
        self,
        test_name,
        data,
        monitored_value,
        threshold,
        low_limit_overrides=None,
    ):
        new_statistics_row = None
        statistics = {}
        data_key_list = list(data.keys())
        value_count = len(monitored_value)

        with open(
            f"{self.processing.data_dir}{self.processing.device}_{test_name}.csv",
            "r",
        ) as csvfile:
            csvreader = csv.reader(csvfile)
            logging.info("Reading data from csv file...")
            build_counter = {}

            baseline_start = {}
            for value in monitored_value:
                baseline_start.update({value: 0})
            new_baseline_start = {}
            for value in monitored_value:
                new_baseline_start.update({value: 0})
            deviation_counter = [0] * value_count
            deviations = {}
            for value in monitored_value:
                deviations.update({value: []})

            row_index = 0
            for row in csvreader:
                if row[-1] == self.processing.device:
                    build = str(row[0])
                    if build in build_counter:
                        build_counter[build] += 1
                        modified_build = f"{build}-{build_counter[build]}"
                    else:
                        build_counter[build] = 0
                        modified_build = build
                    data["commit"].append(modified_build)

                    for key_index in range(1, len(row) - 1):
                        data[data_key_list[key_index]].append(float(row[key_index]))

                    new_statistics_row = {}
                    indexed_statistics_row = {}
                    monitored_value_index = 0
                    for value in monitored_value:
                        low_limit = self.processing.low_limit
                        if low_limit_overrides and value in low_limit_overrides:
                            low_limit = low_limit_overrides[value]
                        if len(threshold) < 2:
                            select_threshold = 0
                        else:
                            select_threshold = value
                        (
                            statistics_block,
                            baseline_start[value],
                            new_baseline_start[value],
                            deviation_counter[monitored_value_index],
                            deviations[value],
                        ) = self.analyze_performance_value(
                            data[value],
                            baseline_start[value],
                            threshold[select_threshold],
                            deviation_counter[monitored_value_index],
                            deviations[value],
                            new_baseline_start[value],
                            row_index,
                            low_limit,
                        )

                        new_statistics_row.update({value: statistics_block})
                        indexed_statistics_block = {}
                        for key in list(statistics_block.keys()):
                            if value_count < 2:
                                indexed_key = key
                            else:
                                indexed_key = key + str(monitored_value_index)
                            indexed_statistics_block.update(
                                {indexed_key: [statistics_block[key]]}
                            )
                        indexed_statistics_row.update(indexed_statistics_block)
                        monitored_value_index += 1

                    if row_index < 1:
                        statistics = indexed_statistics_row
                    else:
                        for key in list(statistics.keys()):
                            statistics[key].append(indexed_statistics_row[key][0])

                    row_index = row_index + 1

        self.processing.csv_store.write_statistics_to_csv(
            test_name,
            {"commit": data["commit"]} | statistics,
        )
        return new_statistics_row, statistics

    def plot_marginals_and_deviations(
        self,
        x_data,
        statistics,
        plot_limit,
        result_index="",
    ):
        for key in statistics.keys():
            statistics[key] = statistics[key][-plot_limit:]
        plt.plot(
            x_data,
            statistics["upper_marginal" + result_index],
            marker="",
            linestyle="dotted",
            color="r",
        )
        plt.plot(
            x_data,
            statistics["lower_marginal" + result_index],
            marker="",
            linestyle="dotted",
            color="r",
        )

        row = 0
        low_limit_labels = []
        low_limit_data = []
        increase_labels = []
        increase_data = []
        decrease_labels = []
        decrease_data = []
        for result in statistics["measurement" + result_index]:
            flag = statistics["flag" + result_index][row]
            if flag != 0:
                if flag == self.processing.zero_result_flag:
                    low_limit_labels.append(x_data[row])
                    low_limit_data.append(result)
                elif flag > 0:
                    increase_labels.append(x_data[row])
                    increase_data.append(result)
                else:
                    decrease_labels.append(x_data[row])
                    decrease_data.append(result)
            row += 1
        plt.plot(
            low_limit_labels,
            low_limit_data,
            marker="x",
            markersize=12,
            linestyle="None",
            mfc="r",
            mec="r",
        )
        plt.plot(
            increase_labels,
            increase_data,
            marker="^",
            markersize=12,
            linestyle="None",
            mfc="y",
            mec="r",
        )
        plt.plot(
            decrease_labels,
            decrease_data,
            marker="v",
            markersize=12,
            linestyle="None",
            mfc="y",
            mec="r",
        )
