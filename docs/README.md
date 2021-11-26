# Panoptes Documentation Site

Welcome to the new Zooniverse API documentation site.

https://zooniverse.github.io/panoptes/

## Requirements

These docs are built using [Slate](https://slatedocs.github.io/slate/#introduction) and [Middleman](https://middlemanapp.com/)

## Installation

We only support running the documentation site via Docker and Docker Compose.

## Usage

1. `cd docs` Ensure you are in the docs directory

2. Run `docker-compose build` to build the docs container

3. Run `docker-compose up` to serve the docs on localhost

Alternatively run `docker-compose run --rm --service-ports docs bash` to start a bash shell in a docs container

## Deploying

These docs autodeploy to the `gh-pages` branch on the repo on all pushes to master branch (i.e. all merged pull requests).

This is done via a GitHub Actions [publish docs workflow](../.github/workflows/publish_docs.yml).

You should not have to manually deploy these docs.

Once deployed these docs are available at https://zooniverse.github.io/panoptes/
