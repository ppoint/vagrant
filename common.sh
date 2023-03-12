#!/bin/bash
set -e

yum install -y tar

source /etc/os-release

cat << EOF > /etc/yum.repos.d/docker-ce.repo
[docker-ce-stable]
name=Docker CE Stable - x86_64
baseurl=https://download.docker.com/linux/centos/${VERSION}/x86_64/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
exclude=docker*
EOF

cat << EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg \
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF

cat << EOF > /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF

yum install -y device-mapper-persistent-data lvm2  \
    --disableexcludes=kubernetes,docker-ce-stable

yum install -y containerd.io cri-tools

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
systemctl restart containerd
crictl config --set runtime-endpoint=unix:///run/containerd/containerd.sock --set image-endpoint=unix:///run/containerd/containerd.sock

systemctl daemon-reload
systemctl restart containerd
systemctl enable containerd.service

yum install -y kubelet kubeadm kubectl --disableexcludes kubernetes
systemctl enable kubelet
systemctl enable --now kubelet

setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

modprobe br_netfilter
sysctl --system

swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab


#
#
# Install helpful containerd tools
#
# nerdctl
curl -fsSLO https://github.com/containerd/nerdctl/releases/download/v1.2.1/nerdctl-1.2.1-linux-amd64.tar.gz
tar zxvf nerdctl-1.2.1-linux-amd64.tar.gz -C /usr/local/bin

