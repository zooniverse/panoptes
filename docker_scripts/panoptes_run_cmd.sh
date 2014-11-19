#!/bin/bash -ex
#TODO: add args to override but have a default to enter into a bash shell
fig run --entrypoint=/bin/bash panoptes -c "bundle install && rails c"
