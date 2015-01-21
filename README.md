# Panoptes ![Build Status](https://travis-ci.org/zooniverse/Panoptes.svg?branch=master)

The new Zooniverse API for supporting user-created projects.

## Documentation

The Panoptes public API is documented [here](http://docs.panoptes.apiary.io), using [apiary.io](http://apiary.io).

If you're interested in how Panoptes is implemented check out the [wiki](https://github.com/zooniverse/Panoptes/wiki).

* [Data Model Description](https://github.com/zooniverse/Panoptes/wiki/DataModel)

## Requirements

Panoptes is primarily developed against stable JRuby, currently 1.7.18. It is tested against the following versions:

* 1.7.18
* 2.1.5

It uses a couple of Ruby 2.0 features, so you'll need to put JRuby in 2.0 mode by setting `JRUBY_OPTS=--2.0` in your environment.

You will need the following services available:

* Postgresql 9.3
* Kafka 0.8.1
* [Cellect Server](https://github.com/zooniverse/Cellect)
* Zookeeper 3.4.6
* Redis

## Installation

### 1. Setup a development environment with Fig and Docker

An easy way to get the full Panoptes stack running (see `fig.yml` to dig into the setup).

#### Requirements

* Docker
  * [OS X](https://docs.docker.com/installation/mac/) - Boot2Docker
  * [Ubuntu](https://docs.docker.com/installation/ubuntulinux/) - Docker
  * [Windows](http://docs.docker.com/installation/windows/) - Boot2Docker

* [fig](http://fig.sh)

#### Usage

1. Run `rake configure FIG_RAKE=off`

2. Run `fig up`

3. Open a new terminal and run `rake db:create db:migrate`

4. Once step 3 is finished, run `rails runner db/fig_dev_seed_data/fig_dev_seed_data.rb`
  * This will seed the development database with an Admin user and a Doorkeeper client application for API access.

This will get you a working copy of the checked out code base. Keep your code up to date and rebuild the image if needed!

If you've added new gems you'll need to rebuild the docker image via the command in step 4.

### 2. Run manually with self installed and run dependencies

Setup the following services to get Panoptes up and running:

* [Postgresql](http://postgresql.org) version > 9.3
* [Zookeeper](http://zookeeper.apache.org) version > 3.4.6
* [Cellect Server](https://github.com/zooniverse/Cellect) version > 0.1.0
* [Kafka](http://kafka.apache.org) version > 0.8.1.1
* [Redis](http://redis.io) version > 2.8.19

We strongly recommend using fig and docker to run Panoptes

## Contributing

Thanks a bunch for wanting to help Zooniverse. Here are few quick guidelines to start working on our project:

1. Fork the Project on Github.
2. Clone the code and follow one of the above guides to setup a dev environment.
3. Create a new git branch and make your changes.
4. Make sure the tests still pass by running `bundle exec rspec`.
5. Add tests if you introduced new functionality.
6. Commit your changes. Try to make your commit message [informative](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html), but we're not sticklers about it. Do try to to add `Closes #issue` or `Fixes #issue` somewhere in your message if it's addressing a specific open issue.
7. Submit a Pull Request
8. Wait for feedback or a merge!

Your Pull Request will run on [travis-ci](https://travis-ci.org/zooniverse/Panoptes), and we'll probably wait for it to pass on MRI Ruby 2.1.2 and JRuby 1.7.16 before we take a look at it.

## License

Copyright 2014-2015 by the Zooniverse

Distributed under the Apache Public License v2. See LICENSE
