# Monica Sandstorm Package

This repository contains files to turn the [Monica](https://github.com/monicahq/monica) Personal Relationship Manager into a Sandstorm app.

It is based off the official [Docker image](hub.docker.com/_/monica) and installs and configures nginx and mysqld as outlined by the vagrant-spk [lemp stack](https://github.com/sandstorm-io/vagrant-spk/tree/master/stacks/lemp).

Sandstorm-specific adjustments are applied through .patch-files.

## Development Guide

Prerequisites: Local Sandstorm, `spk`, Docker, buildah

 1. Build the Docker image, mount it and register the mounted path in sandstorm-pkgdef.capnp: `sudo ./build`
 2. `sudo spk dev` (need to be root to access the mounted image filesystem)

If you want to make changes to monica, you can clone it into the `opt/www/html` directory and it will override the installation provided by Docker:

 1. `git submodule add https://github.com/monicahq/monica opt/www/html`
 1. `cd opt/www/html && git checkout $CURRENT_MONICA_VERSION`
 2. `rm -rf storage && ln -s /var/www/html/storage storage && ln -s /var/www/html/.env .env`
 3. `git apply-patch`

Note that if you change parts of the client-side JavaScript, these have to be manually transferred into the `public/js/vendor.js` (i.e. using `yarn production`) in order to be picked up.

When finished, commit your changes to monica create a new patch file, and register it in the [Dockerfile](Dockerfile):

```bash
git commit
git format-patch HEAD~1 --stdout > ../../../monica-patches/my-patch.patch
```

## Overview of build files

 - opt/app/
   - service-config
     - [mime.types](opt/app/service-config/mime.types) [[base](https://github.com/sandstorm-io/vagrant-spk/blob/master/stacks/lemp/service-config/mime.types)]
     - [nginx.conf](opt/app/service-config/nginx.conf) [[base](https://github.com/sandstorm-io/vagrant-spk/blob/master/stacks/lemp/service-config/nginx.conf)]
   - [launcher.sh](opt/app/launcher.sh) [[base](https://github.com/sandstorm-io/vagrant-spk/blob/master/stacks/lemp/launcher.sh)]
 - [setup.sh](setup.sh) [[base](https://github.com/sandstorm-io/vagrant-spk/blob/master/stacks/lemp/setup.sh)]
