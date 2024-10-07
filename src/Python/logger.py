# Read and Store MPU6050 Data to Disk

import serial
from serial.serialutil import SerialException

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

ser.close()
