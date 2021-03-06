#on CENTOS7
sudo su
yum update -y 
yum install -y epel-release inotify-tools
yum install -y git socat golang gcc libseccomp-devel make
yum install -y yum-utils
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl start docker

setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
swapoff -a
sed -e '/swap/s/^/#/g' -i /etc/fstab
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg	 https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF
yum install -y kubelet-1.21.0 kubeadm-1.21.0 kubectl-1.21.0 --disableexcludes=kubernetes
systemctl enable kubelet
lsmod | grep br_netfilter
modprobe br_netfilter
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
systemctl stop firewalld
kubeadm init --pod-network-cidr=192.168.0.0/16  
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/calico.yaml
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/Nienkeeijsvogel/helm/master/scripts/get-helm-3
chmod +x get_helm.sh
export PATH=$PATH:/usr/local/bin
./get_helm.sh
kubectl create namespace kube-system
kubectl config set-context $(kubectl config current-context) --namespace=kube-system
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install kafka-local bitnami/kafka --set persistence.enabled=false,zookeeper.persistence.enabled=false --set replicaCount=3
kubectl taint nodes $(hostname) node-role.kubernetes.io/master-
kubectl run consumer --image neijsvogel/kafka:consumerch --namespace kube-system --command python3 /code/consumer.py 
kubectl wait --for=condition=Ready pod/consumer
kubectl run producer --image neijsvogel/kafka:producerch --namespace kube-system --command python3 /code/producer.py
kubectl logs --selector=run=consumer --tail 5
