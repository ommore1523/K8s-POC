# POC 5- readinessProbe  : Check how it works and check healthiness for the pod


- readinessProbe initially waits for `initialDelaySeconds` before starting check healthyness.
- after completion of `initialDelaySeconds` it starts for checking for every `timeoutSeconds` seconds.
- if requirement/cmd/request fails **it will remove the pod** from the clusture
- I will be schedule for every `timeoutSeconds` seconds



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
        
      readinessProbe: # remove the container if not healty 
        exec:
          command:
          - cat
          - /var/lib/postgresql/data/pgdata/om.txt

        initialDelaySeconds: 5
        timeoutSeconds: 5

      volumeMounts:
        - name: psql-persistent-volume
          mountPath: /var/lib/postgresql/data

  volumes:
    - name: psql-persistent-volume
      persistentVolumeClaim:
        claimName: psqlpvc

```


```bash

# When om.txt not present It will remove pod
omkar@espl ~/D/O/K/K8s (master)> kubectl get pods
NAME          READY   STATUS    RESTARTS   AGE
pd-pod-name   0/1     Running   0          16m
```
```bash
# When om.txt  present

omkar@espl ~/D/O/K/K8s (master)> kubectl get pods
NAME          READY   STATUS    RESTARTS   AGE
pd-pod-name   1/1     Running   0          16m
```


# POC-6: livenessProbe  : Check how it works and check healthiness for the pod

- readinessProbe initially waits for `initialDelaySeconds` before starting check healthyness.
- after completion of `initialDelaySeconds` it starts for checking for every `timeoutSeconds` seconds.
- if requirement/cmd/request fails it will **restart the pod** from the clusture
- I will be schedule for every `timeoutSeconds` seconds

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

      livenessProbe: # retry and redeploy  the container if not healty
        exec:
          command:
          - cat
          - /var/lib/postgresql/data/pgdata/om.txt
          
        initialDelaySeconds: 5
        timeoutSeconds: 5


      volumeMounts:
        - name: psql-persistent-volume
          mountPath: /var/lib/postgresql/data

  volumes:
    - name: psql-persistent-volume
      persistentVolumeClaim:
        claimName: psqlpvc
```


```bash

NAME          READY   STATUS    RESTARTS     AGE
pd-pod-name   1/1     Running   **4 (5s ago)**   2m56s

NAME          READY   STATUS             RESTARTS      AGE
pd-pod-name   0/1     CrashLoopBackOff   5 (67s ago)   5m38s

```


# POC-6: startupProbe  : Check how it works and check healthiness for the pod

- readinessProbe initially waits for `initialDelaySeconds` before starting check healthyness.
- after completion of `initialDelaySeconds` .
- if requirement/cmd/request fails it will **wait for start**.
- I will be **not schedule** . 
- First time starts then it will not care if requirement/cmd/request afterwards.


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

      startupProbe: # It will check at starting level.. ONce container add to healthy and after app crashes it will not care
        exec:
          command:
            - cat
            - /var/lib/postgresql/data/pgdata/om.txt
        failureThreshold: 10
        periodSeconds: 5


      volumeMounts:
        - name: psql-persistent-volume
          mountPath: /var/lib/postgresql/data

  volumes:
    - name: psql-persistent-volume
      persistentVolumeClaim:
        claimName: psqlpvc
```