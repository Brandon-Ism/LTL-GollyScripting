# This script takes the path of the CSV file of 'jitter_bug_data.csv' as input, and outputs the plots of the jitter path using 'feh', for fast and easy preview of such jitter paths. 

# Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Jul. 2024.

import sys
import csv
import matplotlib.pyplot as plt

if len(sys.argv) != 2:
    print("Usage: python3 plot_jitter.py path/to/csv")
    sys.exit(1)

# Get the CSV file path from the command-line argument
csv_file_path = sys.argv[1]

x_values = []
y_values = []

# Open the CSV file
with open(csv_file_path, 'r') as csvfile:
    # Create a CSV reader object
    csvreader = csv.reader(csvfile)

    # Skip the first 8 rows
    for _ in range(8):
        next(csvreader)

    # Read the rest of the rows
    for row in csvreader:
        # Append the values from the second and third columns to the lists
        x_values.append(float(row[1]))
        y_values.append(float(row[2]))
        

# Define figure size
fig_size = (15, 10)        

# Plot the points only
plt.scatter(x_values, y_values, s=7)  
plt.xlabel('X')
plt.ylabel('Y')
plt.title('Points Only Plot of Jitter Bug Path')
points_only_image_path = 'points_only_plot.png'
plt.savefig(points_only_image_path)
plt.clf()  

# Plot the points connected with a polyline
plt.plot(x_values, y_values, marker='o', markersize=3, linewidth=1) 
plt.xlabel('X')
plt.ylabel('Y')
plt.title('Polyline Plot of Jitter Bug Path')
polyline_image_path = 'polyline_plot.png'
plt.savefig(polyline_image_path)
plt.clf() 


# Display the images using feh 
import os
os.system(f"feh {points_only_image_path} & feh {polyline_image_path} &")

