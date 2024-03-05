
1. Operating system upgrade:
  - POD EVICTION TIMEOUT=5min: Default time of pod which node marked as dead when it goes offline
  - If you upgrading the node and you know that the node will be come back online within 5 min then the upgrade.
  - else you need to drain the node 
  - drain node : means that the node will be marked as unscheduleable the pods will be terminated gracefully and shifted to anothe node 
  - `kubectl drain <node-name>` : mark node as unschedulable. terminates running pod and shift to another node
  - `kubectl cordon <node-name>` : mark as unschedulable only
  - `kubectl uncordon <node-name>` : undrain node

2. Cluster Version Upgrade:
    - `kubectl upgrade plan`
    - `kubectl upgrade apply`
    - Upgrading version involves two measure steps:
       1. Upgrade master node
            - Upgrade master will down the resources kubectl , kubeapi. Its does not mean application will down. The cluster will 
            serve to users as normal. Since master is down . You can not access the cluster using kubectl
       2. Upgrading the worker nodes:
           1. Upgrading at once:
           2. Upgrade one node at a time
           3. Add new nodes with news software version and deletes old one

    - STEPS:
        * Master Upgrade :
            1. Upgrade kubeadm:
                > apt-get upgrade -y kubeadm=1.12.0-00

                > kubeadm upgrade apply v1.12.0

                > Check all nodes are available
            2. Upgrade kubelet
                > apt-get upgrade -y kubelet=1.12.0-00

                > systemctl restart kubelet

                > check master version using kubectl get nodes command
        * Worker upgrade :
            1. Shift all the pods to another node and set unschedulable
                >kubectl drain node01
            2. Upgrade kubelet and kubectl 
                > apt-get upgrade -y kubeadm=1.12.0-00

                > apt-get upgrade -y kubelet=1.12.0-00

                > kubeadm upgrade node config --kubelet-version v1.12.0

                > systemctl daemon-reload

                > systemctl restart kubelet

                > kubectl uncordon node01
            

    - Practical
     ```bash
            kubectl get nodes
            kubectl get pods -o wide
            kubeadm upgrade plan
            kubectl get nodes
            kubectl drain controlplane --ignore-daemonsets
            kubectl get nodes
            apt-get upgrade kubelet=1.25.0-00
            kubectl uncordon controlplane
            kubectl get nodes
            kubectl get pods -o wide
    ```

3. Cluster Backup and Restore:
   * Backup Candidates/Options:
     1. Resource configuration
        * Resource are created using imperative approach(by command) or declarative approach (file method)
        * file methods can more appropriate method which we can keep backup to scm
        * or bkp with cmd `kubectl get all --all-namespaces -o yaml > all-deploy-services.yaml`
        * There is tool called `VELERO` which helps to keep backups 
     2. ETCD cluster:
        - Backup:
            * ETCD is available on master node and by default available at dir `/var/lib/etcd`
            * Or `ETCDCTL_API=3 etcdctl  snapshot save snapshot.db` you can backup  and view status `etcdctl snapshot status snapshot.db`
        - Restore:
            * `service kube-apiserver stop` stop kubeapi server 
            * `ETCDCTL_API=3 etcdctl \ snapshot restore snapshot.db \ --data-dir /var/lib/etc-from-bkp`
            * update path in etcd.service file for --data-dir
            * systemctl daemon-reload
            * service etcd restart
            * service kube-apiserver start

            NOTE: ```bash
                # Backup ETCD with certificates
                ETCDCTL_API=3 \ etcdctl \ snapshot save snapshot.db \
                 --endpoints=https://127.0.0.1:2379 \
                 --cacert=/etc/etcd/ca.cert \
                 --cert=/etc/etcd/etcd-server.crt \
                 --key=/etc/etcd/etcd-server.key
                 ```
    
    Practical:
    - all the required static pods in the kube system namespace like etcd, schedulars mainifests(yaml files) are
    available  inside /etc/kubernetes/manifests/..  cat etcd.yaml file. Check mounts and volumes
    - `open etcd.yaml file`
    - `export ETCDCTL_API=3`
    - `etcdctl snapshot save /opt/snapshot-pre-boot.db  --endpoints=127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key`
        * --endpoints = --listen-client-urls
        * --cacert = --trusted-ca-file
        * --cert = --cert-file
        * --key = --key-file
    - `etcdctl snapshot restore --data-dir /var/lib/etcd-from-bkp /opt/snapshot-pre-boot.db`
    - check dir if data `member` folder is present 
    - open `etcd.yaml` from `/etc/kubernetes/manifests/` and change `hostpath` for volume `etcd-data` to `/var/lib/etcd-from-bkp`
    - wait for a while till `etcd from namespace kube-system is in running state`

    - If it is in pending state :
      * `kubectl delete pod etcd-controlplane -n kube-system`
      * It will recreate itself again
      * check status
    - Now all resources are back 




    
     
   