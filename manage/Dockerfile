#
FROM exosphere/docker-chef-server:12.15.8
MAINTAINER Exosphere Data, LLC <docker@exospheredata.com>

EXPOSE 80 443
VOLUME /var/opt/opscode

RUN apt-get update && \
    apt-get install -q --yes logrotate vim-nox hardlink wget ca-certificates apt-transport-https
RUN tmpdir="`mktemp -d`" && cd "$tmpdir" && \
    wget -nv https://packages.chef.io/files/stable/chef-manage/2.5.4/ubuntu/14.04/chef-manage_2.5.4-1_amd64.deb && \
    echo '6141a1a099c35ba224cefea7a4bd35ec07af21a3aefdcd96b307e70de652abde chef-manage_2.5.4-1_amd64.deb' > sha256sum.txt && \
    sha256sum -c sha256sum.txt && \
    dpkg -i chef-manage_2.5.4-1_amd64.deb && \
    apt-get clean && \
    rm -rf $tmpdir /tmp/install.sh /var/lib/apt/lists/* /var/cache/apt/archives/* 

COPY init.rb /init.rb

ENV KNIFE_HOME /etc/chef
ENV PUBLIC_URL ""
ENV ACCEPT_LICENSE "false"

CMD [ "/opt/opscode/embedded/bin/ruby", "/init.rb" ]
