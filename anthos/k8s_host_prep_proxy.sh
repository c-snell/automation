#/bin/bash

arg=$1

if [[ $arg = "-proxy" ]]
then

cat <<EOF >> /etc/environment
export http_proxy="http://16.85.88.10:8080"
export https_proxy="http://16.85.88.10:8080"
export no_proxy="127.0.0.1,localhost,.cluster.local,.svc,localaddress,10.10.0.0/16,172.17.0.0/16,16.0.0.0/8,192.0.0.0/8"
EOF

cat <<EOF >> /etc/bashrc
export http_proxy="http://16.85.88.10:8080"
export https_proxy="http://16.85.88.10:8080"
export no_proxy="127.0.0.1,localhost,.cluster.local,.svc,localaddress,10.10.0.0/16,172.17.0.0/16,16.0.0.0/8,192.0.0.0/8"
EOF

cat <<EOF >> /etc/profile.d/proxy.sh
export http_proxy="http://16.85.88.10:8080"
export https_proxy="http://16.85.88.10:8080"
export no_proxy="127.0.0.1,localhost,.cluster.local,.svc,localaddress,10.10.0.0/16,172.17.0.0/16,16.0.0.0/8,192.0.0.0/8"
EOF

mkdir -p /etc/systemd/system/docker.service.d/

cat <<EOF >> /etc/systemd/system/docker.service.d/no_proxy.conf
[Service]
Environment="NO_PROXY=127.0.0.1,localhost,.cluster.local,.svc,localaddress,10.10.0.0/16,172.17.0.0/16,16.0.0.0/8,192.0.0.0/8"
Environment="HTTP_PROXY=http://16.85.88.10:8080"
Environment="HTTPS_PROXY=http://16.85.88.10:8080"
EOF

elif [[ $arg = "-centos" ]]
then

sudo yum update -y
sudo yum remove podman buildah -y
# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
# Disable SELinux
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
# Disable firewall
sudo systemctl stop firewalld && sudo systemctl disable firewalld
# Install requirements
sudo yum install -y  yum-utils device-mapper-persistent-data lvm2
# Install Docker
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io open-vm-tools
sudo systemctl start docker && sudo systemctl enable docker
sudo reboot

elif [[ $arg = "-rhel" ]]
then

sudo yum update -y
sudo yum remove podman buildah -y
# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
# Disable SELinux
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
# Disable firewall
sudo systemctl stop firewalld && sudo systemctl disable firewalld
# Install requirements
sudo yum install -y  yum-utils device-mapper-persistent-data lvm2 open-vm-tools
# Install Docker
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker && sudo systemctl enable docker
sudo reboot

elif [[ $arg = "-ubuntu" ]]
then

sudo apt dist-upgrade -y
sudo systemctl stop apparmor && systemctl disable apparmor
# Disable firewall
sudo systemctl stop ufw && sudo systemctl disable ufw
sudo apt remove podman buildah docker docker-engine docker.io containerd runc -y
# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
# Disable SELinux
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
# Install Docker
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common docker.io open-vm-tools
sudo systemctl start docker && sudo systemctl enable docker
sudo reboot

else
  echo "Specify \"-centos\", \"-rhel\", or \"-ubuntu\" to prepare nodes. Use \"-proxy\" to apply HPE proxy settings"
fi
