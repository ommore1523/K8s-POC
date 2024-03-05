
sudo apt-get update && sudo apt-get update
# sudo vim /etc/ssh/sshd_config
# sudo service sshd restart
# sudo passwd ubuntu
sudo swapoff -a
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
sudo -E tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y containerd.io
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/kubernetes-xenial.gpg
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
sudo apt update
# sudo apt install -y kubelet kubeadm kubectl


#sudo apt-mark hold kubelet kubeadm kubectl

# only master
sudo kubeadm init --control-plane-endpoint=192.168.1.114
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml

kubectl get nodes



# TROUBLESHOOTING WORKED

# kubectl get pods
# kubectl describe pod nginx
# kubectl taint nodes espl node-role.kubernetes.io/control-plane:NoSchedule-
# kubectl run nginx --image=nginx --restart=Never
# kubectl get nodes
# sudo systemctl restart kubelet
# sudo systemctl restart containerd.service
# kubectl describe node espl
# kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml
# bash
# rm -rf .kube
# sudo kubeadm init --control-plane-endpoint=192.168.1.114
# sudo rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/etcd /etc/cni/net.d
# sudo kubeadm reset
# sudo swapoff -a