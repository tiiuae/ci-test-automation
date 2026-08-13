import csv
import json
import logging
import os


class PerformanceCsvStore:
    def __init__(self, processing):
        self.processing = processing

    def get_job_name(self):
        if self.processing.config_path != "None":
            with open(
                self.processing.config_path + f"/{self.processing.build_number}.json"
            ) as config_file:
                data = json.load(config_file)
            return data["Job"]
        return "dummy_job"

    def create_result_dirs(self):
        job = self.get_job_name()
        data_dir = self.processing.perf_data_dir + f"{job}/"
        logging.info(f"Creating {data_dir}")
        os.makedirs(data_dir, exist_ok=True)
        statistics_dir = f"{data_dir}statistics"
        os.makedirs(statistics_dir, exist_ok=True)
        if self.processing.plot_dir != "./":
            logging.info(f"Creating {self.processing.plot_dir}")
            os.makedirs(self.processing.plot_dir, exist_ok=True)
        return data_dir

    def write_to_csv(self, test_name, data):
        file_path = os.path.join(
            self.processing.data_dir,
            f"{self.processing.device}_{test_name}.csv",
        )
        logging.info(f"Writing data to {file_path}")
        with open(file_path, "a", newline="") as csvfile:
            csvwriter = csv.writer(csvfile)
            csvwriter.writerow(data)

    def write_statistics_to_csv(self, test_name, data):
        file_path = os.path.join(
            self.processing.data_dir,
            f"statistics/{self.processing.device}_{test_name}_statistics.csv",
        )
        logging.info("Updating statistics for %s", test_name)
        with open(file_path, "w", newline="") as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(data.keys())
            writer.writerows(zip(*(data.values())))

    def write_test_data_to_csv(self, test_name, test_data):
        logging.info("Saving test data to csv")
        data = [self.processing.build_number + "-" + self.processing.commit]
        if type(test_data) == list:
            for value in test_data:
                data.append(value)
        else:
            for key in test_data:
                data.append(test_data[key])
        data.append(self.processing.device)
        self.write_to_csv(test_name, data)

    def write_test_data_and_read(self, test_name, test_data, read_function, *read_args):
        self.write_test_data_to_csv(test_name, test_data)
        return read_function(test_name, *read_args)
