# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

ruby_type = ENV['VAGRANT_RUBY'] || 'jruby'

ruby_version_test = if ruby_type == 'mri'
                      "2.1.2"
                    elsif ruby_type == 'jruby'
                      "1.9.3"
                    end

ruby_build_version = if ruby_type == 'mri'
                       "2.1.2"
                     elsif ruby_type == 'jruby'
                       "jruby-1.7.12"
                     end

install_ruby = <<BASH
RUBY_VERSION=`ruby -e "p RUBY_VERSION"`
if [[ "$RUBY_VERSION" != "\"#{ruby_version_test}\"" ]]; then
  echo JRUBY_OPTS=--2.0 >> /etc/environment
  apt-get update
  apt-get remove -y openjdk-6-jre
  apt-get install -y build-essential libssl-dev libreadline-dev wget libc6-dev libssl-dev libreadline6-dev zlib1g-dev libyaml-dev libpq-dev git-core openjdk-7-jre libmysqlclient-dev
  apt-get clean
  git clone https://github.com/sstephenson/ruby-build.git && cd ruby-build && ./install.sh
  export CONFIGURE_OPTS="--disable-install-rdoc"
  ruby-build #{ruby_build_version} /usr/local
  ruby -v
  gem install bundler
fi
BASH

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "phusion_ubuntu-12.04-docker"
  config.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/ubuntu-12.04.3-amd64-vbox.box"
  config.vm.network :forwarded_port, guest: 3000, host: 3000

  config.vm.provision "shell", inline: "mkdir -p /opt/postgresql"
  config.vm.provision "shell", inline: install_ruby

  config.vm.provision "docker" do |d|
    d.pull_images "paintedfox/postgresql"
    d.pull_images 'edpaget/zookeeper'

    d.run 'paintedfox/postgresql',
      args: '--name pg -p 5432:5432 -e USER="panoptes" -e PASS="panoptes" -v /opt/postgresql:/data'
    d.run 'edpaget/zookeeper:3.4.6',
      args: '--name zk -p 2181:2181',
      cmd: '-c localhost:2888:3888 -i 1'
  end
end
