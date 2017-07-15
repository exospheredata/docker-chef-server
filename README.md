# docker-chef-server
### _Docker container for Chef Server_
This repository will create a docker image using Ubuntu and install Chef Server.

For full details on the installation of Chef Serer visit the [official documentation](https://docs.chef.io/install_server.html#standalone)

This repository is a fork and refresh of [3ofcoins/docker-chef-server](https://github.com/3ofcoins/docker-chef-server)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Requirements](#requirements)
  - [Environment Variables](#environment-variables)
  - [Ports](#ports)
  - [Volumes](#volumes)
  - [Customizing Chef Server](#customizing-chef-server)
  - [Signals](#signals)
  - [IPv6 and Docker containers](#ipv6-and-docker-containers)
- [Usage](#usage)
  - [Prerequisites and first start](#prerequisites-and-first-start)
  - [Example configurations](#example-configurations)
  - [Maintenance commands](#maintenance-commands)
  - [Publishing the endpoint](#publishing-the-endpoint)
  - [Backup and restore](#backup-and-restore)
  - [Chef Plugins](#chef-plugins)
- [License & Authors](#license-&-authors)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Requirements
The enclosed Dockerfile has been tested against the following versions of Docker:
- 17.06.0-ce

### Environment Variables
_Note: bold variables must be set as part of the container creation_

- **`PUBLIC_URL`** - should be configured to a full public URL of the endpoint (e.g. `https://chef.example.com`)
- `OC_ID_ADMINISTRATORS` - if set, it should be a comma-separated list of users that will be allowed to add oc_id applications

### Ports

Ports 80 (HTTP) and 443 (HTTPS) are exposed.

### Volumes

- `/var/opt/opscode`: holds all Chef server data. Directories `/var/log/opscode` and `/etc/opscode` are linked there as, respectively, `log` and `etc`.

### Customizing Chef Server

If there is the file `/var/opt/opscode/etc/chef-server-local.rb` is included in the container, it will be read at the end of `chef-server.rb` and it can be used to customize Chef Server's settings.

This file can be pushed into the container and added to the root of the container's filesystem `/`.  If the file is found, it will be automatically copied to the correct location and included as part of the build.

_Note: Adding a `chef-server-local.rb` file to your configuration will force the container to run a Chef reconfigure on every start.  This ensures that the systems is always configured correctly.  During testing, we noticed issues with restarts connecting to an external postgres instance if we didn't run `chef-server-ctl reconfigure` on start_

### Signals

 - `docker kill -s HUP $CONTAINER_ID` will run `chef-server-ctl reconfigure`
 - `docker kill -s USR1 $CONTAINER_ID` will run `chef-server-ctl status`

### IPv6 and Docker containers

The current Chef Server version has a built-in check to see if the host has IPv6 enabled and an address assigned to its loopback.  If you hit an error such as - _Your system has IPv6 enabled but its loopback interface has no IPv6 address._ then set the following as part of your docker container setup:

` --sysctl net.ipv6.conf.lo.disable_ipv6=0 `

## Usage

### Prerequisites and first start

The `kernel.shmmax` and `kernel.shmall` sysctl values should be set to a high value on the host. You may also run Chef server as a privileged container to let it autoconfigure -- but the setting will propagate to host anyway, and it would be the only reason for making the container privileged, so it is better to avoid it.

First start will automatically run `chef-server-ctl reconfigure`. Subsequent starts will not run `reconfigure`, unless file `/var/opt/opscode/bootstrapped` has been deleted. You can manually run `reconfigure` by sending SIGHUP to the container: `docker kill -HUP $CONTAINER_ID`.

_Note: if a Chef configuration override file `chef-server-local.rb` is included in the container, each restart of the container will trigger a reconfigure._

### Example configurations

#### Basic build using defaults
```bash
docker run --name chef -d -p 443:433 -e PUBLIC_URL="https://chefdoc" -h chefdoc exosphere/docker-chef-server:12.15.8
```

#### Basic build using defaults and adding a named docker volume
```bash
docker run --name chef -d -p 443:433 -e PUBLIC_URL="https://chefdoc" -h chefdoc -v chefdata:/var/opt/opscode exosphere/docker-chef-server:12.15.8
```

#### Basic build using defaults with IPv6 disabled
```bash
docker run --name chef -d -p 443:433 -e PUBLIC_URL="https://chefdoc" -h chefdoc --sysctl net.ipv6.conf.lo.disable_ipv6=0 exosphere/docker-chef-server:12.15.8
```

#### Advanced build using custom chef-server-local.rb file with IPv6 disabled
```bash
docker create --name chef -p 443:433 -e PUBLIC_URL="https://chefdoc" -h chefdoc --sysctl net.ipv6.conf.lo.disable_ipv6=0 exosphere/docker-chef-server:12.15.8

docker cp chef-server-local.rb chef:/chef-server-local.rb

docker start chef
```

#### Advanced build using custom chef-server-local.rb file with IPv6 disabled and custom network
_This configuration is useful when leveraging an external Postgres container for the backend._
```bash
docker network create devnet

docker create --name chef --net=devnet -p 443:433 -e PUBLIC_URL="https://chefdoc" -h chefdoc --sysctl net.ipv6.conf.lo.disable_ipv6=0 exosphere/docker-chef-server:12.15.8

docker cp chef-server-local.rb chef:/chef-server-local.rb

docker start chef
```

### Maintenance commands

Certain commands native to Chef Server will need to be run post-container creation.  These include setting up organizations and users by way of the `chef-server-ctl` command.

#### Create a new user
```bash
docker exec -it $CONTAINER_ID chef-server-ctl user-create admin Admin User admin@nothing.lab P4ssw0rd!
```

#### Create a new user and organization additionally assign the new user to have admin privileges on the organization
```bash
docker exec -it $CONTAINER_ID chef-server-ctl user-create admin Admin User admin@nothing.lab P4ssw0rd!
docker exec -it $CONTAINER_ID chef-server-ctl org-create demolab "Demolab" -a admin
```

### Publishing the endpoint

This container is not supposed to listen on a publically available port. It is very strongly recommended to use a proxy server, such as [nginx](http://nginx.org/), as a public endpoint.

Unfortunately, Chef's logic for figuring out the absolute URL of various pieces (oc_id, bookshelf, erchef API, etc) for links and redirects is twisted and fragile. There are `chef-server.rb` settings, but some pieces insist on using the `Host:` header of the request, and it doesn't seem possible to use plain HTTP endpoint and have the Chef Server generate HTTPS redirects everywhere.

The main setting you need to configure is `PUBLIC_URL` environment variable. It needs to contain full public URL, as seen by `knife` and `chef-client` (e.g. `PUBLIC_URL=https://chef-api.example.com/`).

Then, you need to make sure that the proxy passes proper `Host:` header to the Chef Server, and talks with the Chef Server on the same protocol that the final endpoint will use (i.e. proxy that listens on HTTPS would need to use Chef Server's self-signed HTTPS endpoint; proxy that listens on plain HTTP would need to talk to HTTP endpoint).

If you prefer to avoid overhead of encrypting the connection between proxy and the Chef Server, it *should* be sufficient to rewrite the `Location:` headers (`proxy_redirect` in nginx, `ProxyPassReverse` in Apache). It works for me, but I can't guarantee you won't bump into a wrong URL generated by the server.

A sample nginx configuration looks like this:

    server {
      listen 443 ssl;
      server_name chef.example.com;
      ssl_certificate /path/to/chef.example.com.pem;
      ssl_certificate_key /path/to/chef.example.com.key;
      client_max_body_size 4G;
      location / {
          proxy_pass http://127.0.0.1:5000;
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-Proto https;
          proxy_redirect default;
          proxy_redirect http://chef.example.com https://chef.example.com;
      }
    }

### Backup and restore

    $ docker exec chef-server chef-server-backup

Backup will be created in `/var/opt/opscode/backup/latest`, and all previous backups will be in their own timestamped directories. Backups will use hardlinks to share unchanged files. The backups will take form of JSON files with user and organization details, and each organization's chef repository dump generated with `knife download`.

There is no full restore script yet; you'll need to create orgs & users based on JSON files, and then use `knife upload` to upload each organization's data separately. The restore script is being worked on, but some pieces can't be restored (in particular, users' passwords), and other pieces seem tricky (in particular, ACLs).

Alternatively, one can take a binary backup of data volume (it is not possible to read anything from such backup without starting up whole Chef server, and it takes much more disk space, though):

1. `docker stop chef-server`
2. Archive `/var/opt/opscode` volume (delete the `bootstrapped` file from the archive to force `chef-server-ctl reconfigure` run on the new container)
3. `docker start chef-server`

Same thing works for upgrades: just reuse container, remembering to remove the `bootstrapped` file. You may also need to remove the symlinks in `/var/opt/opscode/service` and/or run `chef-server-ctl upgrade` via `docker exec`.

### Chef Plugins

Plug-ins can be installed manually using the `chef-server-ctl install $package-name` command.

## License & Authors

**Author:** 3ofCoins ([contact@3ofcoins.net](mailto:contact@3ofcoins.net))

**Contributor:** Jeremy Goodrum ([docker@exospheredata.com](mailto:docker@exospheredata.com))

```text

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
