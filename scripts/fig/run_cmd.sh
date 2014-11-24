#!/bin/bash
run_cmd="bundle install && rails c"
if [ ! -z "$1" ]; then
  run_cmd="$1"
fi
echo "Running command: $run_cmd"
fig run --entrypoint=/bin/bash panoptes -c "$run_cmd"
