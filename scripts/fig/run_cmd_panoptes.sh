#!/bin/bash
[ $# -eq 0 ] && { echo "Usage: $0 'commands to run in the panoptes docker container'"; exit 1; }
run_cmd="$1"
echo "Running command: $run_cmd"
fig run --rm --entrypoint=/bin/bash panoptes -c "$run_cmd"
