from datetime import datetime
import math
import os
import re
import pandas
import numpy as np
import matplotlib.pyplot as plt
import xlwt


class FileReader:
    max_files_per_bin = 0
    total_bins = 0
    bin_range = []
    file_numbers_to_be_binned = []

    def __init__(self, folders_set_to_analyse):
        self.folder_data_pairs = folders_set_to_analyse
        # self.manually_selected_folder_path = manually_selected_folder_path
        # self.raw_curves_folder_path = raw_curves_folder_path

    def calculate_cycle_time(self):
        approach_value = 0
        pause_value = 0
        retract_value = 0

        first_manual_file_path =''

        for key in self.folder_data_pairs:
            first_manual_file_path =  key
            for topdir, dirs, files in os.walk(first_manual_file_path):
                firstfile = files[0]
                first_file_path = os.path.join(topdir, firstfile)
                file_to_read = open(first_file_path, 'r')
                lines_of_file = file_to_read.readlines()
                is_approach_time_found = False
                is_pause_time_found = False
                is_retract_time_found = False

                for line in lines_of_file:
                    # skip the comparison if we alredy found the line
                    if not is_approach_time_found:
                        if re.search('# force-settings.segment.0.duration:', line):
                            # print('Print first value line   ' + line)
                            approach_value = float(line.split(": ")[1].rstrip())
                            is_approach_time_found = True
                            continue
                    if not is_pause_time_found:
                        if re.search('# force-settings.segment.1.duration:', line):
                            # print('Print second value line   ' + line)
                            pause_value = float(line.split(": ")[1].rstrip())
                            is_pause_time_found = True
                            continue
                    if not is_retract_time_found:
                        if re.search('# force-settings.segment.2.duration:', line):
                            # print('Print third value line   ' + line)
                            retract_value = float(line.split(": ")[1].rstrip())
                            is_retract_time_found = True
                            continue

        cycle_time = approach_value + pause_value + retract_value
        self.max_files_per_bin = math.floor(14400 / cycle_time)

    def calculate_bin_number(self):
        # total_files = 0
        # for raw_curves_folder_path in self.folder_data_pairs.values():
        #     files_list = os.listdir(raw_curves_folder_path)  # dir is your directory path
        #     total_files += int(len(files_list))
        self.total_bins = 12

    def create_bins(self):
        end_range = self.total_bins + 1
        #TODO change range to use the end_range
        for bin in range(end_range):
            self.bin_range.append(self.max_files_per_bin * bin)

    def get_file_numbers_to_bin(self):
        for manual_path_folder in self.folder_data_pairs:
            for file in os.listdir(manual_path_folder):
                if(file.endswith('.txt')):
                    self.file_numbers_to_be_binned.append([int(n) for n in re.findall('\d+(?=.txt)', file)][0])

    def plot_bar_chart(self):
        my_bins = self.bin_range
        my_file_numbers_to_fin = self.file_numbers_to_be_binned

        plot_data = {'y_axis_TotalFiles': np.arange(len(my_file_numbers_to_fin)),
                     'x_axis_Files': my_file_numbers_to_fin
                     }
        df = pandas.DataFrame(plot_data)

        x_tick_labels = np.arange(start=1, stop=len(my_bins))

        df['bin'] = pandas.cut(df.x_axis_Files, my_bins)

        grouped_per_bin_df = df[['bin', 'x_axis_Files']].groupby('bin').count()
        for v in grouped_per_bin_df.values:
            print( 'value: ', str(v[0]))
        the_plot = grouped_per_bin_df.plot(kind='bar')
        the_plot.set_xticklabels(x_tick_labels, rotation=0)
        plt.xlabel("Time(h)")
        plt.ylabel("Number of complete protein unfolding")
        plt.title("Complete protein unfolding per hour")
        #plt.yticks(np.arange(min(), max(), 2.0))
        plt.show()
