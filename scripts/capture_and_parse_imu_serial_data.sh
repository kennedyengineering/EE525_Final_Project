#!/bin/bash

# Set the default serial port, baud rate, and capture duration (in seconds)
DEFAULT_SERIAL_PORT="/dev/cu.usbmodem2101"
DEFAULT_BAUD_RATE="115200"
CAPTURE_DURATION=60  # Capture duration in seconds (default is 1 minute)
LOG_FILE="screenlog.0"

# Prompt user for serial port and baud rate with default options
read -p "Enter the serial port (default: $DEFAULT_SERIAL_PORT): " SERIAL_PORT
read -p "Enter the baud rate (default: $DEFAULT_BAUD_RATE): " BAUD_RATE

# Use default values if no input is provided
SERIAL_PORT=${SERIAL_PORT:-$DEFAULT_SERIAL_PORT}
BAUD_RATE=${BAUD_RATE:-$DEFAULT_BAUD_RATE}

# Get the current timestamp
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Inform the user that screen session is starting in detached mode
echo "[$TIMESTAMP] Starting screen session in detached mode to capture data from $SERIAL_PORT" \
    "at $BAUD_RATE baud rate for $CAPTURE_DURATION seconds..."

# Start the screen session in detached mode
screen -dmS serial_capture -L $SERIAL_PORT $BAUD_RATE

# Sleep for the specified capture duration
sleep $CAPTURE_DURATION

# Kill the screen session after the capture duration
screen -S serial_capture -X quit

# Check if the screen log file exists
if [[ -f $LOG_FILE ]]; then
    echo "Log has been saved as '$LOG_FILE'."
else
    echo "No log file generated. Please check the screen session."
fi

# Parse the log file and save the cleaned data to a CSV file
python3 parse_screen_imu_log.py "$LOG_FILE"
