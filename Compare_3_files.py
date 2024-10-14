import os

# Function to process files and check for duplicates in the first 30 characters
def process_files(file_list):
    line_starts = {}  # Dictionary to track the first 30 characters of each line and its origin
    duplicates = []   # List to store duplicate lines and their file info
    unique_lines = [] # List to store unique lines and their file info

    # Loop through each file
    for file_name in file_list:
        with open(file_name, 'r') as f:
            lines = f.readlines()
        
        # Loop through the lines and check the first 30 characters
        for idx, line in enumerate(lines):
            line_start = line[:30]  # Get the first 30 characters
            
            # Check if we've seen this start before
            if line_start in line_starts:
                # Add to duplicates list
                duplicates.append(f"File: {file_name}, Line {idx+1}: {line.strip()}")
            else:
                # Add to unique list
                unique_lines.append(f"File: {file_name}, Line {idx+1}: {line.strip()}")
                # Store the line start with its file and line number
                line_starts[line_start] = (file_name, idx+1)

    return duplicates, unique_lines


# Function to export results to files
def export_results(duplicates, unique_lines, duplicate_output_file, unique_output_file):
    # Export duplicates
    with open(duplicate_output_file, 'w') as dup_file:
        dup_file.write("Duplicate Lines:\n")
        for line in duplicates:
            dup_file.write(line + "\n")

    # Export unique lines
    with open(unique_output_file, 'w') as unique_file:
        unique_file.write("Unique Lines:\n")
        for line in unique_lines:
            unique_file.write(line + "\n")


# Function to select up to 3 files interactively
def select_files():
    print("Please select up to 3 files for comparison:")
    
    file_list = []
    file_count = 0
    while file_count < 3:
        file_path = input(f"Enter the path of file {file_count+1} (or press Enter to stop): ")
        if not file_path:
            break  # Exit if the user presses Enter without providing a file
        
        if os.path.isfile(file_path):
            file_list.append(file_path)
            file_count += 1
        else:
            print(f"File '{file_path}' does not exist. Please enter a valid file path.")
    
    return file_list


# Main function
def main():
    # Step 1: Select files interactively
    file_list = select_files()
    
    if len(file_list) < 2:
        print("You need to select at least 2 files for comparison. Exiting.")
        return

    # Step 2: Process the files to find duplicates and unique lines
    duplicates, unique_lines = process_files(file_list)

    # Step 3: Export the results
    export_results(duplicates, unique_lines, 'duplicates_output.txt', 'unique_lines_output.txt')

    print("Process completed! Check 'duplicates_output.txt' and 'unique_lines_output.txt' for results.")


# Run the main function
if __name__ == "__main__":
    main()
