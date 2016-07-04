# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :configure do
  desc "Setup Configuration files"
  task :local => [:config_files, :doorkeeper_keys]

  task :config_files do
    Dir['config/*.yml.hudson'].each do |file|
      new_name = file[0..-8]
      sh "cp #{file} #{new_name}"
    end
  end

  task :doorkeeper_keys do
    generate_doorkeeper_keypair("development")
    generate_doorkeeper_keypair("test")
  end

  def generate_doorkeeper_keypair(env)
    rsa_private = OpenSSL::PKey::RSA.generate 4096
    rsa_public = rsa_private.public_key
    File.open("config/doorkeeper-jwt-#{env}.pem", 'w') { |f| f.puts rsa_private.to_s }
    File.open("config/doorkeeper-jwt-#{env}.pub", 'w') { |f| f.puts rsa_public.to_s }

  end

  task travis: :local do
    database_config = <<YAML
test:
  adapter: postgresql
  database: travis_ci_test
  username: postgres
YAML
    File.open('config/database.yml', 'w') { |f| f.write(database_config) }
  end
end

task configure: 'configure:local'
