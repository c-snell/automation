IMAGE_NAME = "centos/7"
N = 2

Vagrant.configure("2") do |config|

  config.vm.provider "vmware_desktop" do |v|
    v.vmx["memsize"] = "4096"
    v.vmx["numvcpus"] = "2"
    v.gui = false
  end

  config.vm.define "k8s-master" do |master|
    master.vm.box = IMAGE_NAME
    master.vm.network "public_network", ip: "10.10.10.43", hostname: true
    master.vm.hostname = "k8s-master.virtware.io"
    master.vm.provision "ansible" do |ansible|
      ansible.playbook = "kubernetes-setup/master-playbook.yml"
      ansible.extra_vars = {
        node_ip: "10.10.10.43",
      }
    end
  end

  (1..N).each do |i|
    config.vm.define "node-#{i}" do |node|
      node.vm.box = IMAGE_NAME
      node.vm.network "public_network", ip: "10.10.10.#{i + 43}"
      node.vm.hostname = "node-#{i}"
      node.vm.provision "ansible" do |ansible|
        ansible.playbook = "kubernetes-setup/node-playbook.yml"
        ansible.extra_vars = {
          node_ip: "10.10.10.#{i + 43}",
        }
      end
    end
  end
end
