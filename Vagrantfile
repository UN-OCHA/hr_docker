##########################################################
# NOTE: This file is barebone and it's not ready for use.#
##########################################################

# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Limitate the resources used by our VMs
  config.vm.provider "virtualbox" do |v|
    v.gui = false
    v.memory = 2048
    v.cpus = 2
    v.customize ["modifyvm", :id, "--cpuexecutioncap", "70"]
    v.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
  end

  config.vm.box = "ubuntu/trusty64"
  config.vm.provision "docker"

  config.vm.network "private_network", ip: "192.168.99.200"
  #config.hostsupdater.aliases = ["hrinfo.vm"]
  config.vm.network "forwarded_port", guest: 80, host: 1080
  config.vm.network "forwarded_port", guest: 443, host: 1443
  #config.vm.network "forwarded_port", guest: 3306, host: 3306

  config.vm.synced_folder ".", "/var/www/site/docroot", :nfs => true, :mount_options => ['nolock,vers=3,udp']

  # Install the latest version of Docker
  config.vm.provision "shell", inline: <<SH
    # If you'd like to try the latest version of Docker:
    # First, check that your APT system can deal with https URLs:
    # the file /usr/lib/apt/methods/https should exist.
    # If it doesn't, you need to install the package apt-transport-https.
    [ -e /usr/lib/apt/methods/https ] || {
    apt-get -y update
    apt-get -y install apt-transport-https
    }
    # Then, add the Docker repository key to your local keychain.
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
    # Add the Docker repository to your apt sources list,
    # update and install the lxc-docker package.
    # You may receive a warning that the package isn't trusted.
    # Answer yes to continue installation.
    sh -c "echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
    apt-get -y update
    apt-get -y install lxc-docker
SH

    # Install GIT and Fig
    config.vm.provision "shell", inline: <<SH
      # It is easiest to install Git on Linux using the preferred
      # package manager of your Linux distribution.
      # Debian/Ubuntu
      # $ apt-get install git
      apt-get -y install git
      # Automatically chdir to vagrant directory upon “vagrant ssh”
      echo "\n\ncd /home/vagrant/mnt\n" >> /home/vagrant/.bashrc
      # Installing Fig
      curl -L https://github.com/orchardup/fig/releases/download/0.4.2/linux > /usr/local/bin/fig
      chmod +x /usr/local/bin/fig
SH

    config.vm.provision "shell", inline: <<SH
    cd /srv/www/htdocs
    #fig build
    #fig up -d
SH


end
