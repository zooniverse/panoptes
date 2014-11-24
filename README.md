## Panoptes ![Build Status](https://travis-ci.org/zooniverse/Panoptes.svg?branch=master)

The new Zooniverse API for supporting user-created projects.

### Documentation

Panoptes Public API is documented [here](http://docs.panoptes.apiary.io), using [apiary.io](http://apiary.io).

If you're interested in how Panoptes is implemented check out the [wiki](https://github.com/zooniverse/Panoptes/wiki).

* [Data Model Description](https://github.com/zooniverse/Panoptes/wiki/DataModel)

### Requirements

Panoptes is primarily developed against stable JRuby, currently 1.7.16. It is
tested against the following versions:
* 2.1.2
* JRuby 1.7.16

It uses a couple Ruby 2.0 features, so you'll need to put JRuby in 2.0 mode by
setting JRUBY_OPTS=--2.0 in your environment.

You will need the following services available:
* Postgresql 9.3
* Kafka 0.8.1
* [Cellect Server](https://github.com/zooniverse/Cellect)
* Zookeeper 3.4.6
* Redis

#### Development Environment with Fig and Docker

An easy way to get a full stack Panoptes running (see fig.yml to dig into the setup),
##### Required - you'll need docker installed!
 + [OS X Docs](https://docs.docker.com/installation/mac/) - Boot2Docker
 + [Ubuntu docs](https://docs.docker.com/installation/ubuntulinux/) - Docker
 + [Windows Docks](http://docs.docker.com/installation/windows/) - Boot2Docker

Prepare your fig development environment config files. You should only have to do this before the first boot. **Note:** the fig docker environment uses linked docker containers so your Postgres and Zookeeper hosts url's need to refer to these containers.

* Copy all the *file_name*.yml.hudson files to *file_name*.yml, the default values should work out of the box.

Prepare the docker containers, from rails root run:
1. `./scripts/fig/up_panoptes.sh`
  + On the first run it will build the docker containers, setup the database and install the dev and test gems but won't start the rails server(s).
2. `./scripts/fig/up_panoptes.sh`
  + On the second the script will start Panoptes and all the dependant services.
    + **Note:** this script does not recreate containers to avoid installing gems and migrating the database.
    + Run `fig up` if you need to recreate the build image perhaps because you've added new gems.
3. Seed the fig development database in the docker container.
  + `scripts/fig/run_cmd_panoptes.sh "bundle install && rails runner db/fig_dev_seed_data/fig_dev_seed_data.rb"`
  + **Note:** Run this only after step 1 has completed successfully.
4. Finally if you want to apply schema migrations you can do this via `scripts/fig/migrate_db_panoptes.sh

This will get you a working copy of the checked out code base. Keep your code up to date and rebuild the image if needed!

Finally there are some helper scripts to get access to a console, bash shell etc. **Note:** these commands build a new run container
* To get a rails console `scripts/fig/rails_console_panoptes.sh`
  + **Note:** you can override the RAILS_ENV by passing a param, just make sure you've setup the DB for it!
* To get a bash console `scripts/fig/run_cmd_panoptes.sh bash`
* You can also attach a bash process to the running container, e.g. `docker exec -it panoptes_panoptes_1 bash`
  + Assuming the 'panoptes_panoptes_1' container is running, use `fig ps` or `docker ps` to check.

**Note:** if you've ever built a Panoptes docker container before you should just run `fig up` instead of the `./scripts/fig/up_panoptes.sh` to ensure the previously built container is not re-used. After rebuilding you should be good to use `./scripts/fig/up_panoptes.sh` script to use the re-created containers.

### Run manually with self installed and run dependencies

Setup the following services to get Panoptes up and running

#### Postgresql
If you don't want to use docker then just install Postgresql 9.3+ and setup as per a normal Rails app.

#### Cellect Server
See the Cellect server gem and docker file - http://rubygems.org/gems/cellect-server

#### Redis
Normal redis config and configure sidekiq (config/sidekiq.yml) to access redis.

#### Kafka
Setup kafka and then configure the config/kafka.yml file

#### Zookeeper
A really easy way to get Zookeeper running on your local machine, if you don't
want to use the Vagrant configuration, is to run it in a docker container. First
install docker ([OS X Docs](https://docs.docker.com/installation/mac/), [Ubuntu
docs](https://docs.docker.com/installation/ubuntulinux/)), then run the
following command to pull and run a Zookeeper container:

      sudo docker run -d --name zk --publish 2181:2181 zooniverse/zookeeper

Make sure you don't have anything else running on port 2181 that will conflict
with the container. Or change the second number to map to a different port and
adjust the port in your `cellect.yml` file.

### Vagrant

If you're just looking to run Panoptes to develop against it's API. I
recommend looking at [Devoptes](https://github.com/zooniverse/Devoptes).

Panoptes comes with [Vagrant](http://vagrantup.com) (version > 1.5.0) and
[VirtualBox](https://www.virtualbox.org/) (version > 4.3) configuration to make
a test environment easy to get up and running. Use the following commands to get
started

      vagrant up
      vagrant ssh

The Rails application running in the VM will be available at
`http://localhost:3000`. Note that it will take a few minutes for Panoptes to
start. Monitor it with `docker logs panoptes`.

After Panoptes starts you can access a rails console within the
vagrant box by running

      vagrant ssh #if not already logged in
      ./panoptes/vagrant-scripts/console.sh

### License

Copyright 2014 by the Zooniverse

Distributed under the Apache Public License v2. See LICENSE
