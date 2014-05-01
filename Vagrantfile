# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "phusion_ubuntu-12.04-docker"
  config.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/ubuntu-12.04.3-amd64-vbox.box"
  config.vm.network :forwarded_port, guest: 3000, host: 3000

  config.vm.provision "shell", inline: "mkdir -p /opt/postgresql"

  config.vm.provision "docker" do |d|
    d.pull_images "paintedfox/postgresql"
    d.build_image "/vagrant", args: "-t panoptes/panoptes"

    d.run 'paintedfox/postgresql',
      args: '--name pg -p 5432:5432 -e USER="panoptes" -e PASS="panoptes" -v /opt/postgresql:/data'
    
    d.run 'panoptes/panoptes',
      args: '--name panoptes -p 3000:3000 -e RAILS_ENV="docker_dev" --link pg:db',
      cmd: 'bash -c "rake db:create db:migrate && rails s"'
  end
end
