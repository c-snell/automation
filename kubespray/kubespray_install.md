Kubespray installation steps.

These steps have come from many hours to troubleshooting the HPE Proxy and installation steps. These steps will ensure that you have the best chance of a successful install of Kubernetes. There are a number of components within the cluster that need to be able to communicate to ensure the cluster works.


Update the system and install Pip. Disable Firewall on all nodes.

-------------------------------------------------------------------------------
$ yum update -y
$ yum install python-pip -y
$ pip install --upgrade pip
$ systemctl stop firewalld && systemctl disable firewalld


-------------------------------------------------------------------------------
Set Proxy on all nodes (master/workers/load balancers):

Change domain and IP range as needed appropriate. echo 192.168.1.{1..254} is a wildcard to cover all IPs in your subnet. Some programs don't like CIDR notation. These proxy settings include the subnets used by Kubernetes and Docker so they aren't sent to the proxy and blackholed.


-------------------------------------------------------------------------------
$ vi /etc/bashrc
    

export http_proxy="http://16.85.88.10:8080"
export https_proxy="http://16.85.88.10:8080"
export no_proxy="127.0.0.1,localhost,.example.com,.cluster.local,.svc,localaddress,.localdomain.com,.hpecorp.net,.hp.com,.hpcloud.net,`echo 192.168.1.{1..254},`10.1.0.0/16,172.17.0.0/16,172.30.0.0/16"

-------------------------------------------------------------------------------
$ vi /etc/environment


no_proxy=127.0.0.1,localhost,.example.com,.cluster.local,.svc,localaddress,.localdomain.com,.hpecorp.net,.hp.com,.hpcloud.net,`echo 192.168.1.{1..254},`10.1.0.0/16,172.17.0.0/16,172.30.0.0/16
http_proxy=http://16.85.88.10:8080
https_proxy=http://16.85.88.10:8080

-------------------------------------------------------------------------------
$ vi /etc/profile.d/proxy.sh


export http_proxy="http://16.85.88.10:8080"
export https_proxy="http://16.85.88.10:8080"
export no_proxy="127.0.0.1,localhost,.example.com,.cluster.local,.svc,localaddress,.localdomain.com,.hpecorp.net,.hp.com,.hpcloud.net,`echo 192.168.1.{1..254},`10.1.0.0/16,172.17.0.0/16,172.30.0.0/16"

-------------------------------------------------------------------------------

Reboot ALL nodes

-------------------------------------------------------------------------------

Verify NTP on all nodes. Make sure all are within seconds of each other. This ensures certificates are created correctly later on.

$ ntpq -p
$ date

-------------------------------------------------------------------------------

Setup ssh keys on all nodes.

$ ssh-keygen

Run the following to share keys on all nodes, modify hostnames to match your environment. :

$ for host in node1.example.com \
node2.example.com  \
node3.example.com ; \
do ssh-copy-id -i ~/.ssh/id_rsa.pub $host; \
done

Verify you can ssh as root on all nodes without password. I have seen where the first entry gets skipped for some reason. I also run it with IPs for additional checks. Just verify.

-------------------------------------------------------------------------------

Set Proxy for Docker.

This directory may not exist yet.

$ mkdir -p /etc/systemd/system/docker.service.d/

$ vi /etc/systemd/system/docker.service.d/no_proxy.conf
$ vi no_proxy.conf

[Service]
Environment="NO_PROXY=127.0.0.1,localhost,.example.com,.cluster.local,.svc,localaddress,.localdomain.com,.hpecorp.net,.hp.com,.hpcloud.net,`echo 192.168.1.{1..254},`10.1.0.0/16,172.17.0.0/16,172.30.0.0/16"
Environment="HTTP_PROXY=http://16.85.88.10:8080/"
Environment="HTTPS_PROXY=http://16.85.88.10:8080/"


-------------------------------------------------------------------------------

Install Kubespray. This will only be performed from a single host.

$ cd ~ (or whereever you want the install binaries to be located)
$ git clone https://github.com/kubernetes-sigs/kubespray
$ cd kubespray
$ pip install -r requirements.txt
$ cp -rfp inventory/sample inventory/mycluster
$ vi inventory/mycluster/inventory.ini

-------------------------------------------------------------------------------

This will be specific to your environment. Define your masters and workers here. This is for Kubernetes only. Not for the 3PAR/Primera plugin.


# ## Configure 'ip' variable to bind kubernetes services on a
# ## different ip than the default iface
# ## We should set etcd_member_name for etcd cluster. The node that is not a etcd member do not need to set the value, or can set the empty string value.
[all]
kube-g15-master1.example.com ansible_host=192.168.1.80  ip=192.168.1.80
k8-node1.example.com ansible_host=192.168.1.81  ip=192.168.1.81
k8-node2.example.com ansible_host=192.168.1.82  ip=192.168.1.82

# ## configure a bastion host if your nodes are not directly reachable
# bastion ansible_host=x.x.x.x ansible_user=some_user

[kube-master]
k8-master1.example.com

[etcd]
k8-master1.example.com
k8-node1.example.com
k8-node2.example.com

[kube-node]
k8-node1.example.com
k8-node2.example.com

[k8s-cluster:children]
kube-master
kube-node


Save and exit

-------------------------------------------------------------------------------


Set Proxy within Kubernetes. Remember to set domain and IPs as needed.

$ vi inventory/mycluster/group_vars/all/all.yml

## Set these proxy values in order to update package manager and docker daemon to use proxies
http_proxy: "http://16.85.88.10:8080"
https_proxy: "http://16.85.88.10:8080"

## Refer to roles/kubespray-defaults/defaults/main.yml before modifying no_proxy
# no_proxy: "127.0.0.1,localhost,.example.com,.cluster.local,.svc,localaddress,.localdomain.com,.hpecorp.net,.hp.com,.hpcloud.net,`echo 192.168.1.{1..254},`10.1.0.0/16,172.17.0.0/16,172.30.0.0/16"


-------------------------------------------------------------------------------

Set the version of Kubernetes to install

$ vi inventory/mycluster/group_vars/k8s_cluster/k8s_cluster.yml

Version: 1.15.7


Finally run the installer

$ ansible-playbook -i inventory/mycluster/inventory.ini cluster.yml

Grab a cup of your favorite beverage.


