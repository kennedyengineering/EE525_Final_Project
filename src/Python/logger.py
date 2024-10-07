# Read and Store MPU6050 Data to Disk

import serial
from serial.serialutil import SerialException

import time
import argparse

# Parse command line arguments
parser = argparse.ArgumentParser()
parser.add_argument("--port", type=str, default="/dev/ttyACM0")
parser.add_argument("--baud_rate", type=int, default=115200)
args = parser.parse_args()

# Open serial port
try:
    ser = serial.Serial(args.port, args.baud_rate)
except SerialException as ex:
    print(ex.strerror)
    exit()

# Allow for Arduino to reset
time.sleep(3)
ser.reset_input_buffer()

# Read data from Arduino
try:
    while True:
        if ser.in_waiting > 0:  # Check if there is data to read
            line = (
                ser.readline().decode("utf-8").rstrip()
            )  # Read a line from the serial
            print(line)  # Print the line to the console
except KeyboardInterrupt:
    print("Exiting logger.")

# Close serial port
ser.close()
