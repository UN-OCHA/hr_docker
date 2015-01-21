# HumanitarianResponse.info Environment

## General Requirements

To run these local Docker setups, you will need the following software installed

1. Docker 1\.3\.x+, except 1.4.0
    - 1.4.0 had a problem with volumes and may not work with fig; see:
        - <https://github.com/docker/docker/pull/9631>
        - <https://github.com/docker/fig/issues/723>
    - Docker 1.3+ is needed to support the 'docker exec' command, which makes it easy to get a shell in the container
1. Fig >= 1.0
1. The phase2/dnsdock container, used to support automatic creation and maintenance of DNS namespace for the containers
    - This is a public container that is only about 12M; you may freely pull it
1. No existing networks occupying the 172.17.42.0/24 address space
    - you can confirm that 172.17.42.0/24 is available with either
        - `netstat -rn | grep 172.17.42.0`
        - `ip route show | grep 172.17.42.0`
1. Use of one of three options to forward DNS queries to the dnsdock container (see below)

### Setting up Docker
#### Fedora

1. Install Docker
    - `yum install docker-io`
1. Install Pip 
    - `yum install python-pip`
1. Install Fig
    - `sudo pip install fig`
1. Add your user to the Docker group
    - `sudo usermod -aG docker $USER`
1. Log out, then back in, in order to pick up your new group assignments
1. Set the DNS configuration for dnsdock, as well as known RFC-1918 address space
    - Please note that the following command will over-write your existing Docker daemon configuration file.  Please set the -bip=172.17.42.1/24 and -dns=172.17.42.1 options manually as an alternative
    - `echo 'OPTIONS=-bip=172.17.42.1/24 -dns=172.17.42.1' | sudo tee /etc/sysconfig/docker` 
1. Set up the docker0 network as trusted
    - `sudo firewall-cmd --zone=trusted--add-interface=docker0 && sudo firewall-cmd --zone=trusted --add-interface=docker0 --permanent`
1. Start the docker daemon
    - `sudo systemctl start docker`
1. Log into the OCHA Docker Hub Account with the credentials furnished to you.  You'll only need to do this once.
    - `docker login`
1. Pull the phase2/dnsdock container
    - `docker pull phase2/dnsdock`

#### Ubuntu/Linux Mint/Debian
1. Install Docker
    - `curl -sSL https://get.docker.com/ | sh`
1. Install Pip 
    - `apt-get install python-pip`
1. Install Fig
    - `sudo pip install fig`
1. Add your user to the Docker group
    - `sudo usermod -aG docker $USER`
1. Log out, then back in, in order to pick up your new group assignments
1. Set the DNS configuration for dnsdock, as well as known RFC-1918 address space
    - Please note that the following command will over-write your existing Docker daemon configuration file.  Please set the -bip=172.17.42.1/24 and -dns=172.17.42.1 options manually as an alternative
    - `echo 'OPTIONS=-bip=172.17.42.1/24 -dns=172.17.42.1' | sudo tee /etc/default/docker` 
1. Start the docker daemon
    - `sudo start docker`
1. Log into the OCHA Docker Hub Account with the credentials furnished to you.  You'll only need to do this once.
    - `docker login`
1. Pull the phase2/dnsdock container
    - `docker pull phase2/dnsdock`

#### DNS Configuration Options

##### Method 1: libnss-resolver

libnss-resolver is an app that adds Mac-style /etc/resolver/$FQDN files to the Linux NSS resolution stack to query a different DNS server for any .vm address.  It may be the easiest option for most installations.

There are releases for Fedora 20, Ubuntu 12.04 and Ubuntu 14.04.

1. Install libnss-resolver from https://github.com/azukiapp/libnss-resolver/releases 
2. Set up .vm hostname resolution
    - `echo 'nameserver 172.17.42.1:53' | sudo tee /etc/resolver/vm`
3. Run the dnsdock container
    - `docker run -d --name=dnsdock -e DNSDOCK_NAME=dnsdock -e DNSDOCK_IMAGE=dnsdock -p 172.17.42.1:53:53/udp -v /var/run/docker.sock:/var/run/docker.sock phase2/dnsdock`

##### Method 2: dnsdock as main resolver

This method will probably only work well if this is a fixed computer or server with a consistent single upstream DNS server. If you meet these criteria, you can very easily use this to set up .vm resolution for containers an delegate the rest to your normal DNS server.

This example assumes that the upstream DNS server for a Linux workstation is 192.168.0.1.

1. Run the dnsdock container, specifying your upstream DNS server at the end.
    - `docker run -d --name=dnsdock -e DNSDOCK_NAME=dnsdock -e DNSDOCK_IMAGE=dnsdock -p 172.17.42.1:53:53/udp -v /var/run/docker.sock:/var/run/docker.sock phase2/dnsdock /opt/bin/dnsdock -domain=vm -nameserver='192.168.0.1:53'`
1. Configure 172.17.42.1 as your first DNS resolver in your network configuration. The method for doing this may differ based on whether you are using a desktop environment or running Linux on a server, but that nameserver should end up as the first 'nameserver' line in your /etc/resolv.conf file.

##### Method 3: dnsmasq via NetworkManager

This method works well with no other needed software provided that you have unfettered access to your system's configuration, and are using NetworkManager to maintain your networking stack

1. Add the line dns=dnsmasq to /etc/NetworkManager/NetworkManager.conf under the [main] configuration stanza. This will cause NetworkManager to spawn and use a dnsmasq process for all name resolution.
If you already have a local configuration, ensure that it is not configured to start on system boot.
1. Add a single rule to direct all DNS lookups for .vm addresses to the 172.17.42.1 address.
    - `echo 'server=/vm/172.17.42.1' | sudo tee /etc/NetworkManager/dnsmasq.d/dnsdock.conf`
1. Restart NetworkManager, either through systemd, or by simply rebooting.  To restart via systemd:
    - `systemctl restart NetworkManager`
1. Run the dnsdock container
    - `docker run -d --name=dnsdock -e DNSDOCK_NAME=dnsdock -e DNSDOCK_IMAGE=dnsdock -p 172.17.42.1:53:53/udp -v /var/run/docker.sock:/var/run/docker.sock phase2/dnsdock`

##### DNS resolution tests

1. There are several tests you can perform to ensure everything is functioning as it should
    - `dig @172.17.42.1 dnsdock.dnsdock.vm.`
        - You should get a 172.17.0.0/16 address.
    - `ping dnsdock.dnsdock.vm`
        - You should get echo replies from a 172.17.0.0/16 address.
    -  `getent hosts dnsdock.dnsdock.vm`
        - You should get a 172.17.0.0/16 address.

