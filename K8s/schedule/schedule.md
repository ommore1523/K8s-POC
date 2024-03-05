# *Playing Around POD and CONTAINER FOR POD SCHEDULIN*

## 1. POC: Manual Node Selection With `Node Name`
  - How scheduling works ?
    * Every pod has nodeName in spec defined which kubernetes adds it automatically 
    * Check `namespace.yaml` file
    * Schedular looks for rigth node for scheduling pod  using internal algotihtm
    * Then it select and set nodeName property 
    * And completes scheduing

  - What we do we do not have default schedular ?
    *  set nodename property in pod file and schedulr OR
    *  If pod is already created and assign pod to node
        *  create binding object  and send post request to node mimicing like schedular

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secrete
data: 
  POSTGRES_PASSWORD: cGFzc3dvcmQ=
  POSTGRES_USER: YWRtaW4=
stringData:
  POSTGRES_DB: postgresdbb
  PGDATA: /var/lib/postgresql/data/pgdata

```

```yaml

apiVersion: v1
kind: Pod
metadata:
  name: pd-pod-name3 # POD NAME
  labels:
    app: pd-label # POD LABEL FROM WHICH POD WILL BE RECOGNISED OR SELECTED BY OTHER SERVICES
spec:

  containers:
    - name: db-pod-con-name # CONTAINER NAME
      image: 'postgres:12'
      envFrom:
      - secretRef:
          name: db-secrete
      ports:
        - containerPort: 5432
  nodeName: worker1  # set node name for schedule pod **********
```

```bash

# BEFORE
pd-pod-name    1/1     Running   0          51s   10.244.2.14   worker2   <none>           <none>
pd-pod-name1   1/1     Running   0          34s   10.244.1.13   worker1   <none>           <none>
pd-pod-name2   1/1     Running   0          18s   10.244.1.14   worker1   <none>           <none>
pd-pod-name3   1/1     Running   0          2s    10.244.2.15   worker2   <none>           <none>

#AFTER
pd-pod-name    1/1     Running   0          22s   10.244.1.15   worker1   <none>           <none>
pd-pod-name1   1/1     Running   0          14s   10.244.1.16   worker1   <none>           <none>
pd-pod-name2   1/1     Running   0          10s   10.244.1.17   worker1   <none>           <none>
pd-pod-name3   1/1     Running   0          5s    10.244.1.18   worker1   <none>           <none>
```


## 2. POC: Labels and Selectors For NODE
```text
    
    - Labels or selectores are the properties of animals which helps to group them on certain criteria
      like color, living style size etc. Also it helps to filter them.
    
    - animal  color  living-style
      cat     red    land
      fish    red    sea
      parrot  green  land
      tortoise grey  sea
      
      ==> when we say class= red and sea  ::  fish
    - labels are actual labels and selector is filter criteria
    - Kubernetes helps in identify the resources with application  or functionality names and helps to 
      filter it using labels and selector

    - annotations are used to save other details like versiona and contact details
```

**There are two types of labels of selectors**
1. Label and selector for pods ( Used for grouping applications)
2. Label and selector for nodes ( used for scheduling pods for matching node label) ie. Example Below

```bash
ubuntu@admin:~/k8s$  kubectl describe node worker1

# Default labels
Labels: beta.kubernetes.io/arch=amd64
        beta.kubernetes.io/os=linux
        kubernetes.io/arch=amd64
        kubernetes.io/hostname=worker1  
        kubernetes.io/os=linux

ubuntu@admin:~/k8s$  kubectl describe node worker2
# Default labels
Labels: beta.kubernetes.io/arch=amd64
        beta.kubernetes.io/os=linux
        kubernetes.io/arch=amd64
        kubernetes.io/hostname=worker2
        kubernetes.io/os=linux

# ------------------------------------------
# Now add label to worker1 node as SERVER=DB
# -------------------------------------------

ubuntu@admin:~/k8s$ kubectl label nodes worker1 SERVER=DB
```

```bash
# POD changes

apiVersion: v1
kind: Pod
metadata:
  name: pd-pod-name2 # POD NAME
  labels:
    app: pd-label # POD LABEL FROM WHICH POD WILL BE RECOGNISED OR SELECTED BY OTHER SERVICES
spec:

  containers:
    - name: db-pod-con-name # CONTAINER NAME
      image: 'postgres:12'
      envFrom:
      - secretRef:
          name: db-secrete
      ports:
        - containerPort: 5432

  nodeSelector:
    SERVER: DB # this is node label ***********

```


```bash
# Output
NAME           READY   STATUS    RESTARTS   AGE   IP            NODE      NOMINATED NODE   READINESS GATES
pd-pod-name    1/1     Running   0          14s   10.244.1.19   worker1   <none>           <none>
pd-pod-name1   1/1     Running   0          8s    10.244.1.20   worker1   <none>           <none>
pd-pod-name2   1/1     Running   0          4s    10.244.1.21   worker1   <none>           <none>

```

## 3. POC: Taint and Toleration  
```txt

   - Taint is applied on  nodes (Exp. taint= Blue)
   - Toleration is applied on pod ( toleration=blue)
   - The pod which can tolerate the node or matches is scheduled on that node
     else shifted to next one 

   - kubectl taint nodes <node-name> <key>=<value>:<taint-effect>
   - taint-effect: 
      1. NoSchedule  : Do not schedule upcoming pod without toleration
      2. PreferNoSchedule  : Try to not schedule but not guaranted
      3. NoExecute : Do not schedule new pod but remove previous pods which do not matches criteria
    exp. `kubectl taint nodes node01 app=front-end:NoSchedule`
    to check `kubectl describe nodes <nodename>`
   - For toleration on pod check `toleration.yaml`

   - Remove node taint `kubectl taint nodes <nodeName/--all(master)> <key>=<val>:<effect>-`

  
   - Note: Tolerated pod can deployed on any other nodes. There is no restriction on pods. Taint is restriction
    on nodes only to accept the tolerated pods.
```

```bash
ubuntu@admin:~/k8s$ kubectl describe node worker1
Taints:             <none>

ubuntu@admin:~/k8s$ kubectl describe node worker2
Taints:             <none>

ubuntu@admin:~/k8s$ kubectl taint nodes worker1 app=db:NoSchedule
ubuntu@admin:~/k8s$ kubectl taint nodes worker1 app=db:NoSchedule-  # UNtain node command
```

```bash
apiVersion: v1
kind: Pod
metadata:
  name: pd-pod-name3 # POD NAME
  labels:
    app: pd-label # POD LABEL FROM WHICH POD WILL BE RECOGNISED OR SELECTED BY OTHER SERVICES
spec:

  containers:
    - name: db-pod-con-name # CONTAINER NAME
      image: 'postgres:12'
      envFrom:
      - secretRef:
          name: db-secrete
      ports:
        - containerPort: 5432

  tolerations:  # ***************************
  - key: "app"            # The key of the taint to tolerate
    operator: "Equal"         # Operator can be "Equal" or "Exists"
    value: "db"  # The value of the taint to tolerate
    effect: "NoSchedule"  
```

```bash

# output: NOTE: Other nodes can schedule pod  , node can only schedule if toleration match 
# i.e lock is on node   if key available at pod then  only it can enter 

tolerations:
- key: "app"         
operator: "Equal"      
value: "db"  
effect: "NoSchedule"  

NAME           READY   STATUS    RESTARTS   AGE   IP            NODE      NOMINATED NODE   READINESS GATES
pd-pod-name    1/1     Running   0          9s    10.244.1.23   worker1   <none>           <none>
pd-pod-name1   1/1     Running   0          23s   10.244.2.16   worker2   <none>           <none>
pd-pod-name2   1/1     Running   0          13s   10.244.1.22   worker1   <none>           <none>
pd-pod-name3   1/1     Running   0          4s    10.244.2.17   worker2   <none>           <none>


# -----------------------------------------------------------------------------------------------------------

# NO Toleration Matches then schedules anothe node only
  tolerations:
  - key: "app"            # The key of the taint to tolerate
    operator: "Equal"         # Operator can be "Equal" or "Exists"
    value: "db2"  # The value of the taint to tolerate
    effect: "NoSchedule"  

pd-pod-name    1/1     Running   0          2s    10.244.2.21   worker2   <none>           <none>
pd-pod-name1   1/1     Running   0          6s    10.244.2.20   worker2   <none>           <none>
pd-pod-name2   1/1     Running   0          10s   10.244.2.19   worker2   <none>           <none>
pd-pod-name3   1/1     Running   0          17s   10.244.2.18   worker2   <none>           <none>
```


# POC: Node affinity

```txt
   - Node affinity feature provides advanced expression feature for selecting nodes for 
    deploy pods on
   - affinity rules is only applied on pods definitions

    `kubectl get nodes`
    `kubectl describe nodes node01` # check labels
    `kubectl label nodes node01 color=blue` #add label
    `kubectl label nodes node01 color-` # #Remove Label

```

NOTE: 

- Taint/Toleration vs node affinity
- Taint/Toleration will not guarante that pods will deploy on same node where it matches to taint
    but *not matching taint name will not deploy on node*.
- node-affinity will ensure that it will be deploy on matched label node only but
    *not matching label can be also deployed on node*

**Both Can be used together to deploy matched labels and tains pods on our node** and 
**Avoid our pods to be deployed to others nodes**

```bash

ubuntu@admin:~/k8s$ kubectl label nodes worker1 SERVER=DB

```

```yaml

apiVersion: v1
kind: Pod
metadata:
  name: pd-pod-name # POD NAME
  labels:
    app: pd-label # POD LABEL FROM WHICH POD WILL BE RECOGNISED OR SELECTED BY OTHER SERVICES
spec:

  containers:
    - name: db-pod-con-name # CONTAINER NAME
      image: 'postgres:12'
      envFrom:
      - secretRef:
          name: db-secrete
      ports:
        - containerPort: 5432

  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution: # node label and pod affinity rule should match
      # preferredDuringSchedulingIgnoredDuringExecution # prefered but not mandatory
      # Ignored meaning after schedluing any changes will not affect to pod
        nodeSelectorTerms:
        - matchExpressions:
          - key: SERVER   # Key of noe
            operator: In # NotIn Exists
            values:
              - Large  # values of node
              - Medium
              - DB
```

## Resource Limits
- `Resource request` is once concept which is considers the 0.5 cpu and 256Mi memory by default needed.
    minimum amount the memory required.
- File terminologies: `check resource_limits.yaml`

## DaemonSets
   - Previously we deployed more pods on cluster. The pods are randomly assigned to any node. In some node may 
     not available one of the pod replica. 
   - Daemonset helps to this scenario where you wants one copy on each node. New node added replica added to new
     node also i.e it ensures each node contains one copy
   - Use case .. Suppose i wants to deploy monitoring tool for each node .. SO by daemonset It add each copy of 
     monitoring tool on each node. or logs viewer.


   - `kubectl get daemonset`
   - `kubectl describe daemonset <name-of-daemonset>`

```yaml

apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: daemonset-name
spec:
  template:
    metadata:
      labels:
        name: daemonset-pod-name
    spec:
      containers:
      - name: daemonset-container-name
        image: nginx
  selector:
    matchLabels:
      name: daemonset-pod-name

```

## Static Pods:
- Manage the node when dont have any component like kube-api etc. Then you will have only kubelet 
    and docker installed on node. At the time on thing which knows to kubelet is to deploy pod. These
    pods are called as static pods.
- Process:
    - create one pod yaml file
    - put file /etc/kubernetes/manifests/ folder. This pod manifest path is defined in kubelet.service file
    - Kubelet checks every time to this location. 
    - so it will create anpod
    - Note: U can only create pod with this . No replicaset or deployment possible


