# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

FactoryBot.create :full_project

Panoptes.flipper.enable(:cached_serializer)
Panoptes.flipper.enable(:classification_counters)
Panoptes.flipper.enable(:subject_set_statuses_create_worker)
Panoptes.flipper.enable(:subject_uploading)
Panoptes.flipper.enable(:subject_workflow_status_create_worker)
Panoptes.flipper.enable(:upp_activity_count_cache)
