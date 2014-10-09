# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu-14.04-docker"
  config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"
  config.vm.network :forwarded_port, guest: 3000, host: 3000

  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--memory", "2048"]
  end

  config.vm.synced_folder "./", "/home/vagrant/panoptes/"

  config.vm.provision "shell", inline: "mkdir -p /opt/postgresql"
  config.vm.provision "shell", inline: "docker stop $(docker ps -aq) || true; docker rm $(docker ps -aq) || true; rm /home/vagrant/panoptes/tmp/pids/server.pid || true"

  config.vm.provision "docker",
    version: '1.0.1',
    images: [ 'zooniverse/postgresql', 'zooniverse/zookeeper', 'zooniverse/cellect', 'zooniverse/panoptes' ]

  config.vm.provision "docker" do |d|
    d.run 'zooniverse/postgresql',
      args: '--name postgres -e DB="panoptes_development" -e PG_USER="panoptes" -e PASS="panoptes" -v /opt/postgresql:/data'
    d.run 'zooniverse/zookeeper',
      args: '--name zookeeper',
      cmd: '-c localhost:2888:3888 -i 1'
    d.run 'cellect', image: 'zooniverse/cellect',
      args: '--link postgres:pg --link zookeeper:zk'
    d.run 'panoptes', image: 'zooniverse/panoptes',
      args: '--link zookeeper:zookeeper --link postgres:postgres -v /home/vagrant/panoptes/:/rails_app/ -e "RAILS_ENV=development" -p 3000:80 zooniverse/panoptes'
  end
end
