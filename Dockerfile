#
FROM ubuntu:14.04
MAINTAINER Exosphere Data, LLC <docker@exospheredata.com>

EXPOSE 80 443
VOLUME '/var/opt/opscode'

RUN apt-get update && \
    apt-get install -q --yes logrotate vim-nox hardlink wget ca-certificates apt-transport-https
RUN tmpdir="`mktemp -d`" && cd "$tmpdir" && \
    wget -nv https://packages.chef.io/files/stable/chef-server/12.15.8/ubuntu/14.04/chef-server-core_12.15.8-1_amd64.deb && \
    wget -nv https://packages.chef.io/files/stable/chef/13.2.20/ubuntu/14.04/chef_13.2.20-1_amd64.deb && \
    echo '4351cc42f344292bb89b8d252b66364e79d0eb271967ef9f5debcbf3a5a6faae chef-server-core_12.15.8-1_amd64.deb' > sha256sum.txt && \
    echo '88cd274a694bfe23d255937794744d50af972097958fa681a544479e2bfb7f6b chef_13.2.20-1_amd64.deb' >> sha256sum.txt && \
    sha256sum -c sha256sum.txt && \
    dpkg -i chef-server-core_12.15.8-1_amd64.deb chef_13.2.20-1_amd64.deb && \
    rm -rf /etc/opscode && \
    mkdir -p /etc/cron.hourly && \
    ln -sfv /var/opt/opscode/log /var/log/opscode && \
    ln -sfv /var/opt/opscode/etc /etc/opscode && \
    ln -sfv /opt/opscode/sv/logrotate /opt/opscode/service && \
    ln -sfv /opt/opscode/embedded/bin/sv /opt/opscode/init/logrotate && \
    rm -rf /opt/chef-manage/service && \
    mkdir -p /opt/chef-manage && \
    ln -sf /opt/opscode/service /opt/chef-manage/service && \
    chef-apply -e 'chef_gem "knife-opc"' && \
    apt-get clean && \
    rm -rf $tmpdir /tmp/install.sh /var/lib/apt/lists/* /var/cache/apt/archives/* 

COPY init.rb /init.rb
COPY chef-server.rb /.chef/chef-server.rb
COPY logrotate /opt/opscode/sv/logrotate
COPY knife.rb /etc/chef/knife.rb
COPY backup.sh /usr/local/bin/chef-server-backup

ENV KNIFE_HOME /etc/chef
ENV PUBLIC_URL ""

CMD [ "/opt/opscode/embedded/bin/ruby", "/init.rb" ]
