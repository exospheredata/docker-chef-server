# Chef Manage plugin
This Dockerfile will deploy a Chef Server in a container and install the Chef Manage plugin.  This plugin is free for evaluation for up to 25 nodes.  For more information, please see the [official documentation](https://docs.chef.io/manage.html)

## Requirements
The enclosed Dockerfile has been tested against the following versions of Docker:
- 17.06.0-ce

### Environment Variables
_Note: bold variables must be set as part of the container creation_

- **`PUBLIC_URL`** - should be configured to a full public URL of the endpoint (e.g. `https://chef.example.com`)
- `OC_ID_ADMINISTRATORS` - if set, it should be a comma-separated list of users that will be allowed to add oc_id applications
- **`ACCEPT_LICENSE`** - should be set to a value of **true**

### Ports

Ports 80 (HTTP) and 443 (HTTPS) are exposed.

### Volumes

- `/var/opt/opscode`: holds all Chef server data. Directories `/var/log/opscode` and `/etc/opscode` are linked there as, respectively, `log` and `etc`.

### Customizing Chef Server

If there is the file `/var/opt/opscode/etc/chef-server-local.rb` is included in the container, it will be read at the end of `chef-server.rb` and it can be used to customize Chef Server's settings.

This file can be pushed into the container and added to the root of the container's filesystem `/`.  If the file is found, it will be automatically copied to the correct location and included as part of the build.

_Note: Adding a `chef-server-local.rb` file to your configuration will force the container to run a Chef reconfigure on every start.  This ensures that the systems is always configured correctly.  During testing, we noticed issues with restarts connecting to an external postgres instance if we didn't run `chef-server-ctl reconfigure` on start_