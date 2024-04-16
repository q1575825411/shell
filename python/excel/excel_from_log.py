import sys
import os
import csv
import re
from datetime import datetime

def try_parse_date(date_str):
    date_formats = [
        '%a %b %d %H:%M:%S %Y %z',  # e.g., "Mon Feb 4 21:52:53 2019 +0100"
        '%Y-%m-%d %H:%M:%S %z'      # e.g., "2021-07-31 17:42:16 +0800"
    ]
    for date_format in date_formats:
        try:
            return datetime.strptime(date_str, date_format).strftime('%Y-%m-%d %H:%M:%S')
        except ValueError:
            continue
    raise ValueError(f"Date format for '{date_str}' is not supported")

def process_log_lines(file):
    repo_regex = re.compile(r'^-e # (.+) --> (.+)$')
    commit_regex = re.compile(r'^commit \w+')
    author_regex = re.compile(r'^Author: (.+?) <.+>')
    date_regex = re.compile(r'^Date:\s+(.+)$')
    change_id_regex = re.compile(r'Change-Id: (\w+)')
    
    current_entry = {}
    current_repo = ""
    message = []
    collecting_message = False

    for line in file:
        line = line.rstrip()  # Remove trailing whitespace
        if repo_match := repo_regex.match(line):
            current_repo = repo_match.group(1)  # Update the current repository
        elif commit_regex.match(line):
            if current_entry:
                # Yield the current entry
                current_entry['Message'] = '\n'.join(message).strip()
                yield current_entry
            # Reset for the next entry
            current_entry = {'Repository': current_repo}
            message = []
            collecting_message = False
        elif author_match := author_regex.match(line):
            current_entry['Author'] = author_match.group(1)
        elif date_match := date_regex.match(line):
            current_entry['Date'] = try_parse_date(date_match.group(1))
            collecting_message = True  
        elif change_id_match := change_id_regex.search(line):
            current_entry['Change-Id'] = change_id_match.group(1)
        elif collecting_message:
            if line.strip():  
                message.append(line)

    # Yield the last entry if it exists
    if current_entry and message:
        current_entry['Message'] = '\n'.join(message).strip()
        yield current_entry

def save_to_csv(entries, output_dir, output_filename):
    os.makedirs(output_dir, exist_ok=True)
    filepath = os.path.join(output_dir, output_filename)
    with open(filepath, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = ['Repository', 'Author', 'Date', 'Change-Id', 'Message']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        for entry in entries:
            writer.writerow(entry)

def main():
    if len(sys.argv) < 2:
        print("Usage: python script.py <log_file_path>")
        sys.exit(1)
    
    log_file_path = sys.argv[1]
    base_filename = os.path.splitext(os.path.basename(log_file_path))[0]
    output_dir = os.path.join(os.getcwd(), base_filename)
    output_filename = f"{base_filename}_commit.csv"

    with open(log_file_path, 'r', encoding='utf-8') as file:
        entries = process_log_lines(file)
        save_to_csv(entries, output_dir, output_filename)

    print(f"Data saved to {os.path.join(output_dir, output_filename)}")

if __name__ == "__main__":
    main()
