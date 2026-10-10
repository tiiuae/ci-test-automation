import os

import matplotlib.pyplot as plt
import pandas


def start_plot(figsize=(20, 10)):
    plt.figure(figsize=figsize)
    plt.set_loglevel('WARNING')


def save_plot(plot_dir, device, test_name, close=False):
    plt.tight_layout()
    plt.savefig(plot_dir + f'{device}_{test_name}.png')
    if close:
        plt.close()


def _snap_to_previous_value(x_values, value):
    previous_values = [x_value for x_value in x_values if x_value <= value]
    if not previous_values:
        return None
    return previous_values[-1]


def draw_vertical_event_lines(
    event_lines,
    label=None,
    x_values=None,
    snap_to_previous=False,
    x_formatter=None,
    color='k',
    linestyle='-.',
    linewidth=3,
):
    if not event_lines:
        return
    if hasattr(event_lines, 'items'):
        events = event_lines.items()
    else:
        events = ((x_value, label) for x_value in event_lines)

    shown_labels = set()
    has_label = False
    for x_value, event_label in events:
        if snap_to_previous:
            x_value = _snap_to_previous_value(x_values, x_value)
        if x_value is None:
            continue
        if x_formatter is not None:
            x_value = x_formatter(x_value)
        line_label = event_label
        if line_label:
            has_label = True
            if line_label in shown_labels:
                line_label = None
            else:
                shown_labels.add(line_label)
        plt.axvline(
            x=x_value,
            color=color,
            linestyle=linestyle,
            linewidth=linewidth,
            label=line_label,
        )
    if has_label:
        plt.legend(loc='upper left')


def plot_standard_history_series(
    x_data,
    y_data,
    title,
    ylabel,
    ticklabel_style='plain',
    result_index=None,
    statistics=None,
    xlabel=None,
    use_math_text=False,
    label=None,
    color='b',
    subplot=None,
    total_subplots=None,
    deviation_plotter=None,
    plot_limit=40,
):
    if subplot is not None and total_subplots is not None:
        plt.subplot(total_subplots, 1, subplot)
    plt.ticklabel_format(axis='y', style=ticklabel_style, useMathText=use_math_text)
    plt.plot(x_data, y_data, marker='o', linestyle='-', color=color, label=label)
    if statistics is not None and deviation_plotter is not None:
        deviation_plotter(
            x_data,
            statistics,
            plot_limit,
            '' if result_index is None else result_index,
        )
    plt.yticks(fontsize=14)
    plt.title(title, loc='right', fontweight="bold", fontsize=16)
    plt.ylabel(ylabel, fontsize=16)
    plt.grid(True)
    if label:
        plt.legend(loc='upper left')
    if xlabel:
        plt.xlabel(xlabel, fontsize=16)
    plt.xticks(x_data, rotation=90, fontsize=10)


def plot_standard_latency_panel(
    x_data,
    avg_data,
    max_data,
    min_data,
    subplot=None,
    total_subplots=None,
):
    if subplot is not None and total_subplots is not None:
        plt.subplot(total_subplots, 1, subplot)
    plt.ticklabel_format(axis='y', style='plain')
    plt.plot(x_data, avg_data, marker='o', linestyle='-', color='b', label='Avg')
    plt.ylabel('Avg Latency (ms)', fontsize=16)
    plt.legend(loc='upper left')
    plt.grid(True)
    plt.xlabel('Build Number', fontsize=16)
    plt.xticks(x_data, rotation=90, fontsize=10)
    plt.ylabel('Max/Min Latency (ms)', fontsize=16)
    plt.yticks(fontsize=14)
    plt.twinx()
    plt.plot(x_data, max_data, marker='o', linestyle='-', color='r', label='Max')
    plt.plot(x_data, min_data, marker='o', linestyle='-', color='g', label='Min')
    plt.legend(loc='upper left')
    plt.title('Latency', loc='right', fontweight="bold", fontsize=16)


def generate_ballooning_graph_plot(data_dir, plot_dir, device, result_id, test_name):
    vm_data_path = data_dir + "ballooning_" + result_id + ".csv"
    host_data_path = data_dir + "ballooning_host_" + result_id + ".csv"
    vm_data = pandas.read_csv(vm_data_path) if os.path.exists(vm_data_path) else None
    host_data = pandas.read_csv(host_data_path) if os.path.exists(host_data_path) else None
    if vm_data is None and host_data is None:
        raise FileNotFoundError(f"No ballooning CSV data found for {result_id}")

    start_time = 0
    end_times = []
    if vm_data is not None:
        end_times.append(vm_data['time'].max())
    if host_data is not None:
        end_times.append(host_data['time'].max())
    end_time = int(max(end_times))
    step = int((end_time - start_time) / 20)
    if step < 1:
        step = 1
    plt.figure(figsize=(20, 10))
    plt.set_loglevel('WARNING')
    plt.ticklabel_format(axis='y', style='plain')
    plt.yticks(fontsize=14)
    if host_data is not None:
        plt.plot(
            host_data['time'],
            host_data['vm_visible_memory_target'],
            marker='o',
            linestyle='-',
            color='b',
            label='VM visible memory target',
        )
        plt.plot(
            host_data['time'],
            host_data['host_available_mem'],
            marker='o',
            linestyle='-',
            color='g',
            label='host MemAvailable',
        )
    if vm_data is not None:
        plt.plot(
            vm_data['time'],
            vm_data['vm_available_mem'],
            marker='o',
            linestyle='-',
            color='r',
            label='Apparent VM MemAvailable (seen by "free")',
        )
    plt.title(device + " - " + test_name, loc='center', fontweight="bold", fontsize=16)
    plt.ylabel('MiB', fontsize=16)
    plt.grid(True)
    plt.xlabel('Time (s)', fontsize=16)
    plt.legend(loc='upper left', fontsize=20)
    plt.xticks(range(start_time, end_time, step), fontsize=10)
    plt.savefig(plot_dir + f'mem_ballooning_{result_id}.png')
