import re
import subprocess
import json
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime

# Run docker compose logs and grep for relevant lines
def get_logs(service):
    result = subprocess.run(
        f"docker compose logs {service} | grep decision_id -A 120", 
        shell=True, capture_output=True, text=True
    )
    return result.stdout.splitlines()

# Extract metrics and timestamp from the logs
def extract_data(log_lines):
    data = []
    metrics = {}
    timestamp = None
    
    for line in log_lines:
        if '"metrics": {' in line:
            metrics = {}
        elif '"timestamp":' in line:
            timestamp = re.search(r'"timestamp":\s*"([^"]+)"', line).group(1)
        elif 'timer_' in line:
            key_value = line.strip().strip(',').split(': ')
            metrics[key_value[0]] = int(key_value[1])
        elif '}' in line and metrics:
            if timestamp:
                data.append((timestamp, sum(metrics.values())))
            metrics = {}

    return data

# Group data by second and calculate the required statistics (average, max, min, quantile)
def group_and_calculate(data, func):
    df = pd.DataFrame(data, columns=["timestamp", "metrics_sum_ns"])
    df['timestamp'] = pd.to_datetime(df['timestamp'])
    df['second'] = df['timestamp'].dt.floor('S')  # Group by second
    grouped = df.groupby('second')['metrics_sum_ns'].apply(func).reset_index()
    grouped['metrics_sum_ms'] = grouped['metrics_sum_ns'] / 1_000_000  # Convert to milliseconds
    return grouped

# Plot the data and annotate absolute values every 5 seconds
def plot_data(static_opa_data, ext_authz_opa_data, title, func_name):
    plt.figure(figsize=(12, 6))
    plt.plot(static_opa_data['second'], static_opa_data['metrics_sum_ms'], label='static-opa')
    plt.plot(ext_authz_opa_data['second'], ext_authz_opa_data['metrics_sum_ms'], label='ext_authz-opa-service')
    
    # Annotate every 5 seconds
    for i, row in static_opa_data.iterrows():
        if i % 5 == 0:
            plt.text(row['second'], row['metrics_sum_ms'], f"{row['metrics_sum_ms']:.2f} ms", color='blue', fontsize=8)
    for i, row in ext_authz_opa_data.iterrows():
        if i % 5 == 0:
            plt.text(row['second'], row['metrics_sum_ms'], f"{row['metrics_sum_ms']:.2f} ms", color='orange', fontsize=8)
    
    plt.xlabel('Time (Seconds)')
    plt.ylabel(f'{func_name} Total Time (ms)')
    plt.title(f'{title} per Second (static-opa vs ext_authz-opa-service)')
    plt.grid(True, color='lightgrey')
    plt.legend()
    plt.tight_layout()
    plt.show()

# Main workflow
if __name__ == "__main__":
    static_opa_logs = get_logs("static-opa")
    ext_authz_opa_logs = get_logs("ext_authz-opa-service")

    static_opa_data = extract_data(static_opa_logs)
    ext_authz_opa_data = extract_data(ext_authz_opa_logs)

    # Generate charts for average, max, min, and quantile 0.5 (median)
    funcs = [
        (lambda x: x.mean(), "Average", "Average"),
        (max, "Max", "Maximum"),
        (min, "Min", "Minimum"),
        (lambda x: x.quantile(0.5), "Quantile 0.5 (Median)", "Median"),
    ]

    for func, func_name, title in funcs:
        static_opa_grouped = group_and_calculate(static_opa_data, func)
        ext_authz_opa_grouped = group_and_calculate(ext_authz_opa_data, func)
        plot_data(static_opa_grouped, ext_authz_opa_grouped, title, func_name)
