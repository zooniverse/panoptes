# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :configure do
  desc "Setup Configuration files"
  task :local do
    Dir['config/*.yml.hudson'].each do |file|
      new_name = file[0..-8]
      sh "cp #{file} #{new_name}"
    end

    rsa_private = OpenSSL::PKey::RSA.generate 4096
    rsa_public = rsa_private.public_key
    File.open('config/doorkeeper-jwt.pem', 'w') { |f| f.puts rsa_private.to_s }
    File.open('config/doorkeeper-jwt.pub', 'w') { |f| f.puts rsa_public.to_s }
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
