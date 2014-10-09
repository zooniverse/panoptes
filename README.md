## Panoptes ![Build Status](https://travis-ci.org/zooniverse/Panoptes.svg?branch=master)

The new Zooniverse API for supporting user-created projects. 

### Documentation

Panoptes Public API is documented [here](http://docs.panoptes.apiary.io), using [apiary.io](http://apiary.io).

If you're interested in how Panoptes is implemented check out the [wiki](https://github.com/zooniverse/Panoptes/wiki).

* [Data Model Description](https://github.com/zooniverse/Panoptes/wiki/DataModel)

### Requirements

Panoptes is primarily developed against stable JRuby, currently 1.7.12. It is
tested against the following versions:
* 2.1.2
* JRuby 1.7.12
* JRuby HEAD

It uses a couple Ruby 2.0 features, so you'll need to put JRuby in 2.0 mode by
setting JRUBY_OPTS=--2.0 in your environment.

You will need the following services available:
* Postgresql 9.3
* Kafka 0.8.1
* [Cellect](https://github.com/parrish/Cellect)
* Zookeeper 3.4.6

#### Zookeeper

A really easy way to get Zookeeper running on your local machine, if you don't
want to use the Vagrant configuration, is to run it in a docker container. First
install docker ([OS X Docs](https://docs.docker.com/installation/mac/), [Ubuntu
docs](https://docs.docker.com/installation/ubuntulinux/)), then run the
following command to pull and run a Zookeeper container:

      sudo docker run -d --name zk --publish 2181:2181 edpaget/zookeeper:3.4.6 -i 1 -c localhost:2888:3888

Make sure you don't have anything else running on port 2181 that will conflict
with the container. Or change the second number to map to a different port and
adjust the port in your `cellect.yml` file.

### Vagrant

Panoptes comes with [Vagrant](http://vagrantup.com) (version > 1.5.0) and
[VirtualBox](https://www.virtualbox.org/) (version > 4.3) configuration to make
a test environment easy to get up and running. Use the following commands to get
started

      vagrant up
      vagrant ssh

The Rails application running in the VM will be available at
`http://localhost:3000`. Note that it will take a few minutes for Panoptes to
start. Monitor it with `docker logs panoptes`.

### License

Copyright 2014 by the Zooniverse

Distributed under the Apache Public License v2. See LICENSE
