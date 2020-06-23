# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :configure do
  desc "Setup Configuration files"
  task :local => [:doorkeeper_keys]

  task :doorkeeper_keys do
    generate_doorkeeper_keypair("development")
    generate_doorkeeper_keypair("test")
  end

  def generate_doorkeeper_keypair(env)
    rsa_private = OpenSSL::PKey::RSA.generate 4096
    rsa_public = rsa_private.public_key
    File.open("config/keys/doorkeeper-jwt-#{env}.pem", 'w') { |f| f.puts rsa_private.to_s }
    File.open("config/keys/doorkeeper-jwt-#{env}.pub", 'w') { |f| f.puts rsa_public.to_s }
  end
end

task configure: 'configure:local'
