#!/bin/bash
SCRIPT_DIR="`dirname \"$0\"`"
rails_env="development"
if [ $# -eq 1 ]; then
 rails_env="$1"
fi
$SCRIPT_DIR/run_cmd_panoptes.sh "bundle install && rails c $rails_env"
