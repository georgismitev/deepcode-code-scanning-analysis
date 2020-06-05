#!/usr/bin/env bash

# PARAMETERS
FILES_DIR="/src"

CONFIG_FILE="/dc/config.json"
OUTPUT_FILE="/dc/output.json"
ANALYSIS_DIR="/dc/src"

if ! [ -d "$FILES_DIR" ]
then
  echo "$FILES_DIR directory not found."
  exit 1
fi

DEBUG=$(printenv DEBUG)
if [ "$DEBUG" == 'true' ] ; then
  exec 3>&2
else
  exec 3>/dev/null
fi

TIMEOUT=$(( $(printenv TIMEOUT_SECONDS) ))
if [ "$TIMEOUT" -eq 0 ] 2>&3; then
  TIMEOUT=900
fi

echo "External environment variables: DEBUG=$DEBUG TIMEOUT=$TIMEOUT" >&3
echo "DeepCode config file: "$(cat $CONFIG_FILE) >&3

# SUPPORT FUNCTIONS
function load_src_files {
  codacy_files=$(cd $FILES_DIR || exit; find . -type f -exec echo {} \; | cut -c3-)
}

function create_symlink {
  local file="$1"
  final_file="$FILES_DIR/$file"
  if [ -f "$final_file" ]; then
    link_file="$ANALYSIS_DIR/$file"
    parent_dir=$(dirname "$link_file")
    mkdir -p "$parent_dir"
    ln -s "$final_file" "$link_file"
  else
    echo "{\"filename\":\"$file\",\"message\":\"could not parse the file\"}"
  fi
}

function report_error {
  local file="$1"
  local output="$2"
  echo "{\"filename\":\"$file\",\"message\":\"found $output\",\"patternId\":\"foobar\",\"line\":1}"
}

# MAIN EXECUTION
load_src_files

# Create symlinks for requested files into the analysis dir
# Directly passing the path of the files as arguments for the analysis would be
# more efficient, but bash has a limitation on the total length of arguments a
# command can have, and batching the paths would result in hundreds of parallel
# CLI executions which defies the purpose of having a CLI already managing it.
echo "Creating symbolic links for the analysis." >&3
rm -rf "$ANALYSIS_DIR"
mkdir -p "$ANALYSIS_DIR"
while read -r file; do
  create_symlink "$file"
done <<< "$codacy_files"

# Spawn a child process for the analysis
echo "Spawning analysis child process." >&3
(deepcode -c "$CONFIG_FILE" analyze -l -s -p "$ANALYSIS_DIR" 2>&3 >"$OUTPUT_FILE")&
analysis_pid=$!

# in the background, sleep for $TIMEOUT secs then kill the analysis process.
echo "Spawning timeout child process." >&3
(sleep $TIMEOUT && kill -9 $analysis_pid)&
waiter_pid=$!

# wait on our worker process and return the exitcode
echo "Waiting for the analysis to finish." >&3
wait $analysis_pid 2>&3
analysis_exitcode=$?

# kill the waiter subshell, if it still runs
kill -9 $waiter_pid 2>&3
# 0 if we killed the waiter, cause that means the process finished before the waiter
timeout_exitcode=$?
# avoid child termination message in the output
wait $waiter_pid 2>&3


# TEST EXIT CODES AND OUTPUT FILE
echo "Analysis results: analysis_exitcode=$analysis_exitcode, timeout_exitcode=$timeout_exitcode." >&3

if [ $timeout_exitcode -ne 0 ]; then
  echo "Analysis timed out"
  exit 2
fi

if [ $analysis_exitcode -gt 1 ] || [ ! -s "$OUTPUT_FILE" ]; then
  echo "Analysis failed"
  exit 1
fi

if [ $analysis_exitcode -eq 0 ]; then
  # Analysis succeeded, but there is nothing to report
  exit 0
fi


# FORMAT OUTPUT
echo "Converting DeepCode output to Codacy format." >&3

declare -A RULEMAP

output=$(cat $OUTPUT_FILE)

suggestion_indexes=$(jq -cer '.results.suggestions | keys_unsorted[]' <<< "$output")
file_indexes=$(jq -cer '.results.files | keys_unsorted[]' <<< "$output")

severity_map=( [1]="Info" [2]="Warning" [3]="Error" )
while read -r idx; do
  suggestion=$(jq -ce ".results.suggestions[\"$idx\"]" <<< "$output")
  message=$(jq -ce '.message' <<< "$suggestion")
  pattern_id=$(jq -ce '.id' <<< "$suggestion")
  severity=$(jq -cer '.severity' <<< "$suggestion")
  level=${severity_map[$severity]}
  if [ -z "$level" ]; then
    level="Info"
  fi
  RULEMAP["$idx"]="\"patternId\":$pattern_id,\"message\":$message,\"level\":\"$level\",\"category\": \"ErrorProne\""
done <<< "$suggestion_indexes"

# error on json parsing or associative array creation
if [ $? -ne 0 ]; then
  echo "Can't parse analysis output"
  exit 1
fi

cat $OUTPUT_FILE

echo "Success." >&3
exit 0
