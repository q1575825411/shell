#!/bin/bash

# --- Part 1: Fetch and record commit history ---
# Define the root directory for storing all repository commit histories
root_output_dir="$(pwd)/History_cord"
mkdir -p "$root_output_dir"

# Fetch all project paths using the 'repo' command and check for success
repo_paths=$(repo forall -c 'echo $REPO_PATH')
if [ $? -ne 0 ]; then
    echo "Failed to list repositories using 'repo forall'."
    exit 1
else
    echo "Successfully listed all repositories."
fi

# Process each repository path
while IFS= read -r repo_path; do
    if [ -z "$repo_path" ]; then
        continue
    fi

    absolute_repo_path=$(realpath "$repo_path")
    echo "Processing repository: $repo_path ..."
    echo "Absolute path: $absolute_repo_path"

    repo_output_dir_name=$(echo "$repo_path" | sed 's/\//_/g')
    repo_output_dir="${root_output_dir}/${repo_output_dir_name}"
    mkdir -p "$repo_output_dir"

    output_file="${repo_output_dir}/${repo_output_dir_name}.txt"
    echo "Output will be saved to: $output_file"

    if ! git -C "$absolute_repo_path" log --pretty=format:"%h - %an, %ar : %s" > "$output_file"; then
        echo "Failed to get commit history for $repo_path"
    fi
done <<< "$repo_paths"

echo "All repositories' commit histories have been processed."

# --- Part 2: Combine and sort results ---
result_file="$(pwd)/combined_results.txt"
> "$result_file"

delimiter="=================================================================="

find "$root_output_dir" -type f -name "*.txt" -print0 | sort -z | while IFS= read -r -d $'\0' txt_file; do
    file_name=$(basename "$txt_file")
    content=$(<"$txt_file")
    line_count=$(echo "$content" | wc -l)

    if [ "$line_count" -eq 1 ] && [[ "$content" == *"initialize platform base chipcode"* ]]; then
        continue
    fi

    printf "\n%s\nFile: %s\n%s\n" "$delimiter" "$file_name" "$delimiter" >> "$result_file"
    grep -v -E "tag_SP3115_V|\[SP3915|\[SP3136|\[SP3115" "$txt_file" >> "$result_file"
done

echo "Operation complete, all eligible file contents have been consolidated into $result_file."
