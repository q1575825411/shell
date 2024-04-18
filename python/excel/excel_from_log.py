import sys
import os
import csv
import re
from datetime import datetime
from functools import lru_cache

@lru_cache(maxsize=1024)  # Cache the most recent 1024 unique date strings
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
    filter_keywords = ["Merge tag", "SP3136", "initialize platform base chipcode", "SP3915", "SP3115","Initial empty repository","SP3129","changes from t-alps-release-r0.mp1"]
    
    current_entry = {}
    current_repo = ""
    message = []
    collecting_message = False

    def check_filter(text):
        return any(keyword in text for keyword in filter_keywords)

    for line in file:
        line = line.rstrip()
        if repo_match := repo_regex.match(line):
            current_repo = repo_match.group(1)
        elif commit_regex.match(line):
            if current_entry and not check_filter('\n'.join(message)):
                current_entry['Message'] = '\n'.join(message).strip()
                yield current_entry
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
        elif collecting_message and line.strip():
            message.append(line)

    if current_entry and not check_filter('\n'.join(message)):
        current_entry['Message'] = '\n'.join(message).strip()
        yield current_entry

def save_to_csv(entries, output_dir, output_filename, max_rows=12000):
    os.makedirs(output_dir, exist_ok=True)
    current_file_index = 0
    current_file_count = 0
    current_file = None
    writer = None

    for entry in entries:
        if current_file_count >= max_rows or current_file is None:
            if current_file is not None:
                current_file.close()
            part_filename = f"{os.path.splitext(output_filename)[0]}_part{current_file_index + 1}{os.path.splitext(output_filename)[1]}"
            filepath = os.path.join(output_dir, part_filename)
            current_file = open(filepath, 'w', newline='', encoding='utf-8')
            writer = csv.DictWriter(current_file, fieldnames=['Repository', 'Message', 'Author', 'Date', 'Change-Id'])
            writer.writeheader()
            current_file_index += 1
            current_file_count = 0
            print(f"Part {current_file_index} will be saved to {filepath}")

        writer.writerow(entry)
        current_file_count += 1

    if current_file is not None:
        current_file.close()

def main():
    if len(sys.argv) < 2:
        print("Usage: python script.py <log_file_path>")
        sys.exit(1)
    
    log_file_path = sys.argv[1]
    output_dir = os.path.dirname(log_file_path)
    output_filename = f"{os.path.splitext(os.path.basename(log_file_path))[0]}_commit.csv"

    with open(log_file_path, 'r', encoding='utf-8', errors='replace') as file:
        entries = process_log_lines(file)
        save_to_csv(entries, output_dir, output_filename)

if __name__ == "__main__":
    main()
