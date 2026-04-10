import logging
from itertools import cycle

import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import pandas


PLOT_FIGSIZE = (20, 10)
PLOT_LINEWIDTH = 2.5


def configure_time_axis(fig, ax, x_time_format):
    if x_time_format is None:
        return
    # Treat the x-axis as dates
    ax.xaxis.set_major_locator(mdates.AutoDateLocator())
    ax.xaxis.set_major_formatter(mdates.DateFormatter(x_time_format))
    fig.autofmt_xdate()


# Calculate relative available memory
def add_percentage_columns(df, column_specs):
    for numerator_col, denominator_col, pct_col in column_specs:
        numerator = pandas.to_numeric(df[numerator_col], errors="coerce")
        denominator = pandas.to_numeric(df[denominator_col], errors="coerce")
        pct = (numerator / denominator) * 100.0
        df[pct_col] = pct.where(denominator > 0)


# Add indices if there are identical values
def build_unique_labels(values):
    counters = {}
    labels = []
    for value in [str(item) for item in values]:
        counters[value] = counters.get(value, -1) + 1
        if counters[value] > 0:
            labels.append(f"{value}-{counters[value]}")
        else:
            labels.append(value)
    return labels


# Plot data as one-series-per-group
def plot_grouped_metric(
    df,
    x_col,
    y_col,
    out_path,
    title,
    xlabel,
    group_col="vm",
    ylabel="%",
    sort_col="datetime_dt",
    x_labels=None,
    x_time_format="%H:%M:%S",
    y_limits=None,
    legend_loc="upper left",
    marker="o",
):
    fig, ax = plt.subplots(figsize=PLOT_FIGSIZE)
    plt.set_loglevel("WARNING")

    for group_name, group_df in df.groupby(group_col):
        if sort_col:
            group_df = group_df.sort_values(sort_col)
        y_values = pandas.to_numeric(group_df[y_col], errors="coerce")
        if y_values.isna().all():
            continue
        ax.plot(
            group_df[x_col],
            y_values,
            marker=marker,
            linestyle="-",
            label=group_name,
            linewidth=PLOT_LINEWIDTH,
        )

    ax.set_title(title, fontsize=18, fontweight="bold")
    ax.set_xlabel(xlabel, fontsize=16)
    ax.set_ylabel(ylabel, fontsize=16)
    ax.grid(True)
    if y_limits:
        ax.set_ylim(*y_limits)
    configure_time_axis(fig, ax, x_time_format)
    if x_labels is not None:
        ax.set_xticks(sorted(df[x_col].dropna().unique().tolist()))
        ax.set_xticklabels(x_labels, rotation=90, fontsize=10)
    ax.legend(loc=legend_loc)
    fig.tight_layout()
    fig.savefig(out_path)
    plt.close(fig)
    logging.info("Wrote plot to %s", out_path)


# Plot data as two-series-per-group
def plot_grouped_metric_pair(
    df,
    x_col,
    value_col,
    total_col,
    out_path,
    title,
    xlabel,
    group_col="vm",
    ylabel="MiB",
    value_label="value",
    total_label="total",
    sort_col="datetime_dt",
    x_labels=None,
    x_time_format="%H:%M:%S",
    legend_loc="upper left",
    value_marker="o",
    total_marker="s",
):
    fig, ax = plt.subplots(figsize=PLOT_FIGSIZE)
    plt.set_loglevel("WARNING")
    color_cycle = cycle(plt.rcParams["axes.prop_cycle"].by_key()["color"])

    for group_name, group_df in df.groupby(group_col):
        if sort_col:
            group_df = group_df.sort_values(sort_col)
        values = pandas.to_numeric(group_df[value_col], errors="coerce")
        totals = pandas.to_numeric(group_df[total_col], errors="coerce")
        if values.isna().all() and totals.isna().all():
            continue

        color = next(color_cycle)
        if not totals.isna().all():
            ax.plot(
                group_df[x_col],
                totals,
                marker=total_marker,
                linestyle=":",
                label=f"{group_name} ({total_label})",
                linewidth=PLOT_LINEWIDTH,
                color=color,
            )
        if not values.isna().all():
            ax.plot(
                group_df[x_col],
                values,
                marker=value_marker,
                linestyle="-",
                label=f"{group_name} ({value_label})",
                linewidth=PLOT_LINEWIDTH,
                color=color,
            )

    ax.set_title(title, fontsize=18, fontweight="bold")
    ax.set_xlabel(xlabel, fontsize=16)
    ax.set_ylabel(ylabel, fontsize=16)
    ax.grid(True)
    configure_time_axis(fig, ax, x_time_format)
    if x_labels is not None:
        ax.set_xticks(sorted(df[x_col].dropna().unique().tolist()))
        ax.set_xticklabels(x_labels, rotation=90, fontsize=10)
    ax.legend(loc=legend_loc)
    fig.tight_layout()
    fig.savefig(out_path)
    plt.close(fig)
    logging.info("Wrote plot to %s", out_path)
