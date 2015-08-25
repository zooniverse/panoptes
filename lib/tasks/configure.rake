# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :configure do
  desc "Setup Configuration files"
  task :local do
    Dir['config/*.yml.hudson'].each do |file|
      new_name = file[0..-8]
      sh "cp #{file} #{new_name}"
    end
  end

  task travis: :local do
    database_config = <<YAML
test:
  adapter: postgresql
  database: travis_ci_test
  username: postgres

zooniverse_home_test:
  adapter: sqlite3
  database: db/not_used.sqlite3

YAML
    File.open('config/database.yml', 'w') { |f| f.write(database_config) }
    cequel_config = <<YAML
test:
  host: 127.0.0.1
  port: 9042
  keyspace: panoptes_test
  max_retries: 3
  retry_delay: 0.5
  newrelic: false
YAML

    File.open('config/cequel.yml', 'w') { |f| f.write(cequel_config) }
  end
end

task configure: 'configure:local'
