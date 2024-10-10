import os
import re
import sys
from datetime import datetime

# Check if input file is provided as an argument
if len(sys.argv) < 2:
    script_name = os.path.basename(__file__)
    print(f"Usage: python {script_name} <input_file>")
    sys.exit(1)

# Input file name from command-line argument
input_file = sys.argv[1]

# Generate a timestamp for the output file name
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
output_file = f"imu_data_{timestamp}.csv"

# Column names to append at the beginning of the file
column_names = "Time,AccelX,AccelY,AccelZ,GyroX,GyroY,GyroZ"

# Regular expression to match valid data lines
valid_line_pattern = re.compile(
    r"Time:(\d+),AccelX:-?[0-9]+\.[0-9]+,AccelY:-?[0-9]+\.[0-9]+,"
    r"AccelZ:-?[0-9]+\.[0-9]+,GyroX:-?[0-9]+\.[0-9]+,GyroY:-?[0-9]+\.[0-9]+,"
    r"GyroZ:-?[0-9]+\.[0-9]+"
)

previous_line = None
previous_time = -1

# Open the input file and create the output file with the timestamp
with open(input_file, "r") as infile, open(output_file, "w") as outfile:
    # Append the column names as the first line in the output file
    outfile.write(column_names + "\n")

    for line in infile:
        line = line.strip()

        # Check if the line matches the valid pattern
        match = valid_line_pattern.match(line)
        if match:
            current_time = int(match.group(1))  # Extract the current Time value

            # Compare current time with the previous time if previous_time exists
            if previous_time != -1 and current_time < previous_time:
                # If current time is less than previous time, skip the previous line and keep this one
                print(
                    f"Skipping previous line due to invalid time difference: {previous_line}"
                )
                previous_line = (
                    line  # The current line is kept for comparison with the next
                )
                previous_time = current_time
            else:
                # Write the previous valid line (if any) before moving to the next
                if previous_line:
                    # Extract only the numerical values
                    values = [pair.split(":")[1] for pair in previous_line.split(",")]
                    outfile.write(",".join(values) + "\n")

                # Update previous_line and previous_time for the next iteration
                previous_line = line
                previous_time = current_time
        else:
            print(f"Skipping malformed line: {line}")

    # Write the last valid line (if any) at the end
    if previous_line:
        # Extract only the numerical values
        values = [pair.split(":")[1] for pair in previous_line.split(",")]
        outfile.write(",".join(values) + "\n")

print(f"Cleaned data saved to '{output_file}'.")
