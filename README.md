## Panoptes ![Build Status](https://travis-ci.org/zooniverse/Panoptes.svg?branch=master)

The new Zooniverse API for supporting user-created projects. 

### Requirements

Panoptes is primarily developed against stable MRI Ruby, currently 2.1.2. It is tested against the following versions:
* 2.1.2
* 2.1.1
* JRuby 1.7.12
* JRuby HEAD

You will need the following services available:
* Postgresql 9.3
* Kafka 0.8.1
* [Cellect](https://github.com/parrish/Cellect)
* Zookeeper 3.4.6

### Vagrant

Panoptes comes with [Vagrant](http://vagrantup.com) (version > 1.5.0) and [VirtualBox](https://www.virtualbox.org/) (version > 4.3) configuration to make a test environment easy to get up and running. Use the following commands to get started

      vagrant up
      vagrant ssh
      cd /vagrant
      bundle install
      rails s

The Rails application running in the VM will be available at `http://localhost:3000`.

You can specify either MRI-Ruby or JRuby for the vagrant box by setting $VAGRANT_RUBY to 'mri' or 'jruby' in your shell then running `vagrant provision` (or `vagrant up` if you haven't created the VM yet). By default it will install MRI-Ruby.

### License

Copyright 2014 by the Zooniverse

Distributed under the Apache Public License v2. See LICENSE
