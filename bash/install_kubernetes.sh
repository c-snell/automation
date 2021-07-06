arg=$1


# version of Kubernetes to deploy
k8s_version=1.20.1


if [[ $arg = "-remove" ]]
then
  read -p "Are you sure? "
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    # do dangerous stuff
    kubeadm reset
    rm ~/.kube/config
  fi
elif [[ $arg = "help" ]]
then
  echo "Specify -install to install latest version of Kubernetes with kubeadm or -remove to uninstall an existing deployment"
elif [[ $arg = "-install" ]]
then

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  yum install -y docker-ce-19.03.14-3.el7 docker-ce-cli-19.03.14-3.el7 containerd.io-19.03.14-3.el7
  systemctl start docker && systemctl enable docker
  yum install -y kubelet-$k8s_version-0 kubeadm-$k8s_version-0 kubectl-$k8s_version-0 --disableexcludes=kubernetes
  systemctl enable --now kubelet
  kubeadm init --kubernetes-version=$k8s_version --pod-network-cidr=192.168.0.0/16
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  


  kubectl taint nodes --all node-role.kubernetes.io/master-
  echo "Sleeping for 60 seconds for all pods to initialize"
  sleep 60
  echo 'source <(kubectl completion bash)' >>~/.bashrc
  kubectl completion bash >/etc/bash_completion.d/kubectl
  echo 'alias k=kubectl' >>~/.bashrc
  echo 'complete -F __start_kubectl k' >>~/.bashrc
  source ~/.bashrc
  kubectl get pods -A
elif [[ $arg = "-upgrade" ]]
then
  kubeadm reset
  yum remove kubelet kubectl.x86_64 kubeadm -y
  yum update -y
  yum install -y kubelet kubeadm kubectl
  kubeadm init --pod-network-cidr=192.168.0.0/16
  mkdir -p $HOME/.kube
  /bin/cp -rf /etc/kubernetes/admin.conf $HOME/.kube/config
  

  kubectl taint nodes --all node-role.kubernetes.io/master-
  echo "Sleeping for 60 seconds for all pods to initialize"
  sleep 60
  kubectl get pods -A
else
  echo "Specify -install to install latest version of Kubernetes with kubeadm or -remove to uninstall an existing deployment"
fi
