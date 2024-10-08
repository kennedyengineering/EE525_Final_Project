# Read and Store MPU6050 Data to Disk
import csv
import serial
from serial.serialutil import SerialException

from datetime import datetime
import time
import argparse
import os

# Constants
CSV_COLUMNS = ["Timestamp", "AccelX", "AccelY", "AccelZ", "GyroX", "GyroY", "GyroZ"]

# Parse command line arguments
parser = argparse.ArgumentParser()
parser.add_argument("--port", type=str, default="/dev/ttyACM0")
parser.add_argument("--baud_rate", type=int, default=115200)
parser.add_argument("--log_dir", type=str, default="./logs")
date_str = datetime.now().strftime("%Y-%m-%d_%H-%M-%S-%f")
parser.add_argument("--csv_file_name", type=str, default=f"imu_data_{date_str}.csv")
args = parser.parse_args()

# Ensure the log directory exists
if not os.path.exists(args.log_dir):
    os.makedirs(args.log_dir)

# Create a .gitignore file inside the log directory with specific content
gitignore_path = os.path.join(args.log_dir, ".gitignore")

# Check if the .gitignore file already exists, and if not, create it
if not os.path.exists(gitignore_path):
    with open(gitignore_path, "w") as f:
        f.write("*\n!.gitignore\n")

# Full path to the CSV file
file_path = os.path.join(args.log_dir, args.csv_file_name)

# Open serial port
try:
    ser = serial.Serial(args.port, args.baud_rate)
except SerialException as ex:
    print(ex.strerror)
    exit()

# Allow for Arduino to reset (physically press the reset button - for MacOS)
time.sleep(3)
ser.reset_input_buffer()

# Read data from Arduino
try:
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")
    print(f"Starting logger {timestamp}. Writing to {file_path}")
    with open(file_path, "w", newline="") as csv_log_file:
        writer = csv.writer(csv_log_file)
        writer.writerow(CSV_COLUMNS)

        while True:
            if ser.in_waiting > 0:  # Check if there is data to read, if so read it
                line = ser.readline().decode("utf-8").strip()

                # IMU data is sent as a comma-separated string of key-value pairs
                imu_data_pairs = line.split(",")
                if len(imu_data_pairs) == 6:
                    # Extract just the values from the key-value pairs
                    parsed_imu_data = [
                        float(pair.split(":")[1]) for pair in imu_data_pairs
                    ]

                    # Get the current timestamp
                    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")

                    # Write the timestamp and parsed data to the CSV file
                    writer.writerow([timestamp] + parsed_imu_data)

except KeyboardInterrupt:
    print("Exiting logger.")

# Close serial port
ser.close()
