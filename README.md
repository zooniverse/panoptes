## Panoptes

The new Zooniverse API for supporting user-created projects. 

### Requirements

Panoptes is developed on Ruby 2.1.1. It has not been tested with lower versions. 

You will need the following services available:
* Postgresql 9.3
* Kafka 0.8.1
* [Cellect](https://github.com/parrish/Cellect)
* Zookeeper 3.4.6

### Vagrant

Panoptes is convenient to use with [Vagrant](http://vagrantup.com) (version > 1.5.0). Simply run  to use run:

      vagrant up
      vagrant ssh
      cd /vagrant
      bundle install
      rails s

### License

Copyright 2014 by the Zooniverse

Distributed under the Apache Public License v2. See LICENSE
