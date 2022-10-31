from FileReader import FileReader

def main():
    #TODO add analysis per days
    # FileReader will take in a list of Day/Folder custom object
    # loop over each day and folders then process a graph
    # at the end merge each graph per day into a single one
    folder_set_to_analyse = {
        '/Users/blnina/Desktop/MelB/Unfolding_PG_RbCl_buffer/02_Analysis/210325_SelectedCurves_Class2'
    }
    my_file_reader = FileReader(folder_set_to_analyse)
    my_file_reader.calculate_cycle_time()
    my_file_reader.calculate_bin_number()
    my_file_reader.create_bins()
    my_file_reader.get_file_numbers_to_bin()
    my_file_reader.plot_bar_chart()

if __name__ == "__main__":
    main()