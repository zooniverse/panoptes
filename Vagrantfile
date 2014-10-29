# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

ruby_version = ENV['PANOTPES_RUBY'] || 'jruby-1.7.16'
bundle_command = ruby_version.match(/jruby/) ? 'jbundle' : 'bundle'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu-14.04-docker"
  config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"
  config.vm.network :forwarded_port, guest: 3000, host: 3000

  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--memory", "2048"]
  end

  config.vm.synced_folder "./", "/home/vagrant/panoptes/"

  config.vm.provision "docker",
    version: '1.0.1'

  config.vm.provision "shell", inline: "apt-get -y -q install python-pip"
  config.vm.provision "shell", inline: "pip install \"fig>=1.0,<1.1\""
  config.vm.provision "shell", inline: "mkdir -p /opt/postgresql"
  config.vm.provision "shell", inline: "cd /home/vagrant/panoptes && fig stop && fig rm; rm /home/vagrant/panoptes/tmp/pids/server.pid || true"
  config.vm.provision "shell", inline: "echo #{ ruby_version } > /home/vagrant/.ruby-version"

  config.vm.provision "shell", inline: "cd /home/vagrant/panoptes && fig up"
end
