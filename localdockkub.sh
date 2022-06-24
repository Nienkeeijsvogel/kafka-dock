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
kubectl config set-context --current --namespace=kube-system
kubectl taint nodes $(hostname) node-role.kubernetes.io/master-

cat <<EOF > local-kafka-kuber.yml
apiVersion: v1
kind: Pod
metadata:
  name: kafka
spec:
  containers:
    - name: zookeeper
      image: confluentinc/cp-zookeeper:3.3.0-1
      env:
        - name: ZOOKEEPER_CLIENT_PORT
          value: "22181"
      ports:
        - containerPort: 22181
    - name: kafka-broker
      image: confluentinc/cp-kafka:4.1.2-2
      env:
        - name: KAFKA_ZOOKEEPER_CONNECT
          value: "localhost:22181"
        - name: KAFKA_ADVERTISED_LISTENERS
          value: "PLAINTEXT://:29092"
      ports:
        - containerPort: 22181
        - containerPort: 29092
    - name: producer
      image: neijsvogel/producer:mes10
      ports:
        - containerPort: 29092
    - name: consumer
      image: neijsvogel/consumer:localh
      ports:
        - containerPort: 29092
EOF
kubectl apply -f local-kafka-kuber.yml --namespace=kube-system
 
