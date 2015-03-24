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
  end

  desc "Setup development Dockerfile"
  task :dev_docker do
    sh "rm Dockerfile" if File.exists?('./Dockerfile')
    sh "cp dockerfiles/Dockerfile.dev Dockerfile"
    sh "git update-index --assume-unchanged Dockerfile"
  end

  desc "Setup production Dockerfile"
  task :prod_docker do
    sh "rm Dockerfile" if File.exists?('./Dockerfile')
    sh "cp dockerfiles/Dockerfile.prod Dockerfile"
    sh "git update-index --no-assume-unchanged Dockerfile"
  end
end

task configure: 'configure:local'
