
# POC-4 : Create PV, PVC to store pod data in host machine dir, try delete and recreate pod with same volume. check data persistence.


```yaml
# pv.yaml

apiVersion: v1
kind: PersistentVolume
metadata:
  name: psqlpv
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain     #1/ Recycle  delete hostpath    # Delete (for deleteing external disk like ebs) # Retain (keep)
  hostPath:
    path: "/home/docker/psqlVolume"
```

```yaml
# pvc.yaml

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: psqlpvc
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce # accessmode should match
  resources:
    requests:
      storage: 2Gi

```

```yaml
# pod.yaml
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

      
      volumeMounts:
        - name: psql-persistent-volume
          mountPath: /var/lib/postgresql/data

  volumes:
    - name: psql-persistent-volume
      persistentVolumeClaim:
        claimName: psqlpvc
```

```bash
omkar@espl ~/D/O/K8sAngularFlaskPSQL (master) [2]> psql -h 127.0.0.1 -p 5556 -U admin -d postgresdb
psql (14.9 (Ubuntu 14.9-0ubuntu0.22.04.1), server 12.16 (Debian 12.16-1.pgdg120+1))
Type "help" for help.

postgresdb=# select * from test_table;
ERROR:  relation "test_table" does not exist
LINE 1: select * from test_table;
                      ^
postgresdb=# create table test_table(student_id int, stud_name varchar);
CREATE TABLE
postgresdb=# insert into test_table values(1, 'name1');
INSERT 0 1
postgresdb=# select * from test_table;
 student_id | stud_name 
------------+-----------
          1 | name1
(1 row)

postgresdb=# \q
```

<hr>


# POC-4 : Check persistentVolumeReclaimPolicy Recycle, Retain, Delete. And Effect on Volume

- **Only changes will be as `pv.yaml` file.**

```yaml
# pv.yaml

apiVersion: v1
kind: PersistentVolume
metadata:
  name: psqlpv
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  #1.  Recycle  delete hostpath    
  #2.  Delete (for deleteing external disk like ebs) 
  #3.  Retain (keep)
#   persistentVolumeReclaimPolicy: Recycle  #1   
#   persistentVolumeReclaimPolicy: Delete   #2
  persistentVolumeReclaimPolicy: Retain   #3
  hostPath:
    path: "/home/docker/psqlVolume"
```

```yaml
# pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: psqlpvc
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce # accessmode should match
  resources:
    requests:
      storage: 2Gi
```

```yaml
# pod.yaml
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

      
      volumeMounts:
        - name: psql-persistent-volume
          mountPath: /var/lib/postgresql/data

  volumes:
    - name: psql-persistent-volume
      persistentVolumeClaim:
        claimName: psqlpvc
```


#### Scenarios:

1. persistentVolumeReclaimPolicy: Recycle  #1 

- Deleted host dir

```bash

omkar@espl ~/D/O/K/K8s (master)> kubectl apply -f volumes/host_path/pv.yaml
persistentvolume/psqlpv created
omkar@espl ~/D/O/K/K8s (master)> kubectl apply -f volumes/host_path/pvc.yaml
persistentvolumeclaim/psqlpvc created
omkar@espl ~/D/O/K/K8s (master)> kubectl apply -f pod.yaml
pod/pd-pod-name created

# Check dir is created for store data 
docker@minikube:~/psqlVolume$ ls
pgdata

# Delete pv and pvc
omkar@espl ~/D/O/K/K8s (master)> kubectl delete -f volumes/host_path/pvc.yaml 
persistentvolumeclaim "psqlpvc" deleted
omkar@espl ~/D/O/K/K8s (master)> kubectl delete -f volumes/host_path/pv.yaml
persistentvolume "psqlpv" deleted


# Deleted
docker@minikube:~/psqlVolume$ ls
docker@minikube:~/psqlVolume$ 

```

2. persistentVolumeReclaimPolicy: Delete   #2

- Because Delete used to delete data from external disk not host dir it will not delet

```bash

omkar@espl ~/D/O/K/K8s (master)> kubectl apply -f volumes/host_path/pv.yaml
persistentvolume/psqlpv created
omkar@espl ~/D/O/K/K8s (master)> kubectl apply -f volumes/host_path/pvc.yaml
persistentvolumeclaim/psqlpvc created
omkar@espl ~/D/O/K/K8s (master)> kubectl apply -f pod.yaml
pod/pd-pod-name created


docker@minikube:~/psqlVolume$ ls
pgdata

omkar@espl ~/D/O/K/K8s (master)> kubectl delete -f pod.yaml
pod "pd-pod-name" deleted
omkar@espl ~/D/O/K/K8s (master)> kubectl delete -f volumes/host_path/pvc.yaml
persistentvolumeclaim "psqlpvc" deleted
omkar@espl ~/D/O/K/K8s (master)> kubectl delete -f volumes/host_path/pv.yaml
persistentvolume "psqlpv" deleted

docker@minikube:~/psqlVolume$ ls
pgdata

```

3. persistentVolumeReclaimPolicy: Retain

```bash

omkar@espl ~/D/O/K/K8s (master)> kubectl apply -f volumes/host_path/pv.yaml
persistentvolume/psqlpv created
omkar@espl ~/D/O/K/K8s (master)> kubectl apply -f volumes/host_path/pvc.yaml
persistentvolumeclaim/psqlpvc created
omkar@espl ~/D/O/K/K8s (master)> kubectl apply -f pod.yaml
pod/pd-pod-name created


docker@minikube:~/psqlVolume$ ls
pgdata

omkar@espl ~/D/O/K/K8s (master)> kubectl delete -f pod.yaml
pod "pd-pod-name" deleted
omkar@espl ~/D/O/K/K8s (master)> kubectl delete -f volumes/host_path/pvc.yaml
persistentvolumeclaim "psqlpvc" deleted
omkar@espl ~/D/O/K/K8s (master)> kubectl delete -f volumes/host_path/pv.yaml
persistentvolume "psqlpv" deleted

docker@minikube:~/psqlVolume$ ls
pgdata

```