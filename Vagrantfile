# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define "controller" do |n1|
    n1.vm.hostname = "controller.ofs.local"
    n1.vm.network :private_network, ip: "172.16.188.11", auto_config: true
    n1.vm.network :private_network, ip: "172.16.199.11", auto_config: true
    n1.vm.network :private_network, ip: "192.168.166.11", auto_config: true
    n1.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--ioapic", "on"]
      vb.customize ["modifyvm", :id, "--cpus", 2]
      vb.customize ["modifyvm", :id, "--memory", 2048]
    end
  end

  config.vm.define "network" do |n2|
    n2.vm.hostname = "network.ofs.local"
    n2.vm.network :private_network, ip: "172.16.188.12", auto_config: true
    n2.vm.network :private_network, ip: "172.16.199.12", auto_config: true
    n2.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--ioapic", "off"]
      vb.customize ["modifyvm", :id, "--cpus", 1]
      vb.customize ["modifyvm", :id, "--memory", 1024]
    end
  end

  config.vm.define "compute" do |n3|
    n3.vm.hostname = "compute.ofs.local"
    n3.vm.network :private_network, ip: "172.16.188.13", auto_config: true
    n3.vm.network :private_network, ip: "172.16.199.13", auto_config: true
    n3.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--ioapic", "on"]
      vb.customize ["modifyvm", :id, "--cpus", 2]
      vb.customize ["modifyvm", :id, "--memory", 2048]
    end
  end

  config.vm.provision :shell, :path => "provision/provision.sh"

  config.vm.box = "centos65"
  config.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-6.5_chef-provisionerless.box"


end
