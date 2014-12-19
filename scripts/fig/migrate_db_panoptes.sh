#!/bin/bash
SCRIPT_DIR="`dirname \"$0\"`"
rails_env="development"
echo $rails_env
if [ $# -eq 1 ]; then
  rails_env=$1
fi
$SCRIPT_DIR/run_cmd_panoptes.sh "rake db:migrate RAILS_ENV=$rails_env"
