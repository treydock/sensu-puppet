# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Environment variables may be used to control the behavior of the Vagrant VM's
# defined in this file. This is intended as a special-purpose affordance and
# should not be necessary in normal situations. If there is a need to run
# multiple backend instances simultaneously, avoid the IP conflict by setting
# the ALTERNATE_IP environment variable:
#
#     ALTERNATE_IP=192.168.52.9 vagrant up sensu-backend
#
# NOTE: The agent VM instances assume the backend VM is accessible on the
# default IP address, therefore using an ALTERNATE_IP is not expected to behave
# well with agent instances.
if not Vagrant.has_plugin?('vagrant-vbguest')
  abort <<-EOM

vagrant plugin vagrant-vbguest >= 0.16.0 is required.
https://github.com/dotless-de/vagrant-vbguest
To install the plugin, please run, 'vagrant plugin install vagrant-vbguest'.

  EOM
end

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "512"]
  end

  config.vm.define "sensu-backend", primary: true, autostart: true do |backend|
    backend.vm.box = "centos/7"
    backend.vm.hostname = 'sensu-backend.example.com'
    backend.vm.network :private_network, ip: ENV['ALTERNATE_IP'] || '192.168.52.10'
    backend.vm.network :forwarded_port, guest: 2380, host: 2380, auto_correct: true
    backend.vm.network :forwarded_port, guest: 3000, host: 3000, auto_correct: true
    backend.vm.network :forwarded_port, guest: 8080, host: 8080, auto_correct: true
    backend.vm.network :forwarded_port, guest: 8081, host: 8081, auto_correct: true
    backend.vm.provision :shell, :path => "tests/provision_basic_el.sh"
    backend.vm.provision :shell, :inline => "puppet apply /vagrant/tests/sensu-backend.pp"
    backend.vm.provision :shell, :inline => "facter --custom-dir=/vagrant/lib/facter sensu_backend"
    backend.vm.provision :shell, :inline => "facter --custom-dir=/vagrant/lib/facter sensuctl"
  end

  config.vm.define "sensu-backend-peer1", autostart: false  do |backend|
    backend.vm.box = "centos/7"
    backend.vm.hostname = 'sensu-backend-peer1.example.com'
    backend.vm.network :private_network, ip: ENV['ALTERNATE_IP'] || '192.168.52.21'
    backend.vm.network :forwarded_port, guest: 2380, host: 2381, auto_correct: true
    backend.vm.network :forwarded_port, guest: 3000, host: 3001, auto_correct: true
    backend.vm.network :forwarded_port, guest: 8080, host: 8082, auto_correct: true
    backend.vm.network :forwarded_port, guest: 8081, host: 8083, auto_correct: true
    backend.vm.provision :shell, :path => "tests/provision_basic_el.sh"
    backend.vm.provision :shell, :inline => "puppet apply /vagrant/tests/sensu-backend-cluster.pp"
    backend.vm.provision :shell, :inline => "facter --custom-dir=/vagrant/lib/facter sensu_backend"
  end

  config.vm.define "sensu-backend-peer2", autostart: false do |backend|
    backend.vm.box = "centos/7"
    backend.vm.hostname = 'sensu-backend-peer2.example.com'
    backend.vm.network :private_network, ip: ENV['ALTERNATE_IP'] || '192.168.52.22'
    backend.vm.network :forwarded_port, guest: 2380, host: 2382, auto_correct: true
    backend.vm.network :forwarded_port, guest: 3000, host: 3002, auto_correct: true
    backend.vm.network :forwarded_port, guest: 8080, host: 8084, auto_correct: true
    backend.vm.network :forwarded_port, guest: 8081, host: 8085, auto_correct: true
    backend.vm.provision :shell, :path => "tests/provision_basic_el.sh"
    backend.vm.provision :shell, :inline => "puppet apply /vagrant/tests/sensu-backend-cluster.pp"
    backend.vm.provision :shell, :inline => "facter --custom-dir=/vagrant/lib/facter sensu_backend"
  end

  config.vm.define "el7-agent", autostart: true do |agent|
    agent.vm.box = "centos/7"
    agent.vm.hostname = 'el7-agent.example.com'
    agent.vm.network  :private_network, ip: "192.168.52.11"
    agent.vm.provision :shell, :path => "tests/provision_basic_el.sh"
    agent.vm.provision :shell, :inline => "puppet apply /vagrant/tests/sensu-agent.pp"
    agent.vm.provision :shell, :inline => "facter --custom-dir=/vagrant/lib/facter sensu_agent"
  end

  config.vm.define "el6-agent", autostart: false do |agent|
    agent.vm.box = "centos/6"
    agent.vm.hostname = 'el6-agent.example.com'
    agent.vm.network  :private_network, ip: "192.168.52.12"
    agent.vm.provision :shell, :path => "tests/provision_basic_el.sh"
    agent.vm.provision :shell, :inline => "puppet apply /vagrant/tests/sensu-agent.pp"
    agent.vm.provision :shell, :inline => "facter --custom-dir=/vagrant/lib/facter sensu_agent"
  end

  config.vm.define "ubuntu1804-agent", autostart: false do |agent|
    agent.vm.box = "ubuntu/bionic64"
    agent.vm.hostname = 'ubuntu1804-agent.example.com'
    agent.vm.network  :private_network, ip: "192.168.52.13"
    agent.vm.provision :shell, :path => "tests/provision_basic_debian.sh"
    agent.vm.provision :shell, :inline => "puppet apply /vagrant/tests/sensu-agent.pp"
    agent.vm.provision :shell, :inline => "facter --custom-dir=/vagrant/lib/facter sensu_agent"
  end

  config.vm.define "ubuntu1604-agent", autostart: false do |agent|
    agent.vm.box = "ubuntu/xenial64"
    agent.vm.hostname = 'ubuntu1604-agent.example.com'
    agent.vm.network  :private_network, ip: "192.168.52.23"
    agent.vm.provision :shell, :path => "tests/provision_basic_debian.sh"
    agent.vm.provision :shell, :inline => "puppet apply /vagrant/tests/sensu-agent.pp"
    agent.vm.provision :shell, :inline => "facter --custom-dir=/vagrant/lib/facter sensu_agent"
  end

  config.vm.define "ubuntu1404-agent", autostart: false do |agent|
    agent.vm.box = "ubuntu/trusty64"
    agent.vm.hostname = 'ubuntu1404-agent.example.com'
    agent.vm.network  :private_network, ip: "192.168.52.14"
    agent.vm.provision :shell, :path => "tests/provision_basic_debian.sh"
    agent.vm.provision :shell, :inline => "puppet apply /vagrant/tests/sensu-agent.pp"
    agent.vm.provision :shell, :inline => "facter --custom-dir=/vagrant/lib/facter sensu_agent"
  end

  config.vm.define "debian9-agent", autostart: false do |agent|
    agent.vm.box = "debian/stretch64"
    agent.vm.hostname = 'debian9-agent.example.com'
    agent.vm.network  :private_network, ip: "192.168.52.20"
    agent.vm.provision :shell, :path => "tests/provision_basic_debian.sh"
    agent.vm.provision :shell, :inline => "puppet apply /vagrant/tests/sensu-agent.pp"
    agent.vm.provision :shell, :inline => "facter --custom-dir=/vagrant/lib/facter sensu_agent"
  end

  config.vm.define "debian8-agent", autostart: false do |agent|
    agent.vm.box = "debian/jessie64"
    agent.vm.hostname = 'debian8-agent.example.com'
    agent.vm.network  :private_network, ip: "192.168.52.17"
    agent.vm.provision :shell, :path => "tests/provision_basic_debian.sh"
    agent.vm.provision :shell, :inline => "puppet apply /vagrant/tests/sensu-agent.pp"
    agent.vm.provision :shell, :inline => "facter --custom-dir=/vagrant/lib/facter sensu_agent"
  end

  config.vm.define "win2012r2-agent", autostart: false do |agent|
    agent.vm.box = "opentable/win-2012r2-standard-amd64-nocm"
    agent.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "2048"]
      vb.customize ["modifyvm", :id, "--cpus", "1"]
    end
    agent.vm.hostname = 'win2012r2-agent'
    agent.vm.network  :private_network, ip: "192.168.52.24"
    agent.vm.network "forwarded_port", host: 3389, guest: 3389, auto_correct: true
    agent.vm.provision :shell, :path => "tests/provision_basic_win.ps1"
    agent.vm.provision :shell, :inline => 'iex "puppet apply -v C:/vagrant/tests/sensu-agent.pp"'
    agent.vm.provision :shell, :inline => "facter --custom-dir=C:\vagrant\lib\facter sensu_agent"
  end
end
