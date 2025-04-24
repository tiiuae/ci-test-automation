# SPDX-FileCopyrightText: 2022-2025 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

import pandas as pd
import logging
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker


class ParseMemoryLogData:

    def __init__(self, perf_data_dir):
        self.perf_data_dir = perf_data_dir

    def generate_graph(self, plot_dir, id):
        data = pd.read_csv(self.perf_data_dir + "ballooning_" + id + ".csv")
        start_time = 0
        end_time = int(data['time'].values[data.index.max()])
        step = int((end_time - start_time) / 20)
        if step < 1:
            step = 1
        plt.figure(figsize=(20, 10))
        plt.set_loglevel('WARNING')
        plt.ticklabel_format(axis='y', style='plain')
        plt.yticks(fontsize=14)
        plt.plot(data['time'], data['total_mem'], marker='o', linestyle='-', color='b', label='total_mem')
        plt.plot(data['time'], data['used_mem'], marker='o', linestyle='-', color='g', label='used_mem')
        plt.plot(data['time'], data['available_mem'], marker='o', linestyle='-', color='r', label='avail_mem')
        plt.title('Memory ballooning', loc='center', fontweight="bold", fontsize=16)
        plt.ylabel('MegaBytes', fontsize=16)
        plt.grid(True)
        plt.xlabel('Time (s)', fontsize=16)
        plt.legend(loc='upper left', fontsize=20)
        plt.xticks(range(start_time, end_time, step), fontsize=14)
        plt.savefig(plot_dir + f'mem_ballooning_{id}.png')
        return
