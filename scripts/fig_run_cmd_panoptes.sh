#!/bin/bash
if [ -z "$1" ]; then
  run_cmd="bundle install && rails c"
else
  run_cmd="$1"
fi
fig run --entrypoint=/bin/bash panoptes -c $run_cmd
