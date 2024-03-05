# *Playing Around POD and CONTAINER*

# POC1 - 
## 1. Create Kubernetes pod with postgres container and check if its working / reachable using psql command line tool for ubuntu
## 2. Defining Environmental Variables in file.

### Description:
-  INSTALLATION psql utility : [PSQL INSTALLATION](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-20-04) 
-  Here we created the kubernetes basic pod with postgres container
-  Here we also learn how to define environmental variables in file
-  To access the pod directly from host system or another system you need to forward the pod port to host port
-  `kubectl port-forward pd-pod-name 8888:5432` ie HOSTPOST:POD_CONTAINER_PORT
-  Command Line check `psql -h 127.0.0.1 -p 8888 -U admin -d postgresdb`
-  Equivalent Docker command : docker container run -itd -p 8888:5432 --name db-pod-con-name -e POSTGRES_DB=postgresdb -e POSTGRES_USER=admin -e  POSTGRES_PASSWORD=password postgres:12


```yaml
apiVersion: v1
kind: Pod
metadata: 
  name: pd-pod-name   # POD NAME
  labels:
    app: pd-label  # POD LABEL FROM WHICH POD WILL BE RECOGNISED OR SELECTED BY OTHER SERVICES
spec:
  containers:
    - name: db-pod-con-name  # CONTAINER NAME CONISTE OF THIS STRING
      image: postgres:12  # CONTAINER IMAGE

      env:  # ENVIRONMENTAL VARIABLES
        - name: POSTGRES_DB
          value: postgresdb
        - name: POSTGRES_USER
          value: admin
        - name: POSTGRES_PASSWORD
          value: password
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
```

```bash
omkar@espl ~ [2]> psql -h 127.0.0.1 -p 8888 -U admin -d postgresdb
Password for user admin: 
psql (14.9 (Ubuntu 14.9-0ubuntu0.22.04.1), server 12.13 (Debian 12.13-1.pgdg110+1))
Type "help" for help.

postgresdb=# 
```

<hr>

# POC-2 : How Can we Store Environmental Variable in ConfigMap and read it from there.  

### 1.  IMPERATIVE Approach (Using command create configmap):
    
Syntax :    `kubectl create configmap postgres-config --from-env-file=<file1> --from-env-file <file2>`

1. step-1:
    ```bash
        omkar@espl ~/D/O/K/K/pod_concepts [0|1]> pwd
            /home/omkar/Documents/Other/K8sAngularFlaskPSQL/K8s/pod_concepts # My current Directory
        omkar@espl ~/D/O/K/K/pod_concepts> mkdir configproperty  # create one directory with name configproperty
        omkar@espl ~/D/O/K/K/pod_concepts> touch configproperty/postgres.properties # create one file inside configproperty with name postgres.properties
        omkar@espl ~/D/O/K/K/pod_concepts> ls
            configproperty  pod.yaml  README.md
        omkar@espl ~/D/O/K/K/pod_concepts> ls configproperty/
            postgres.properties
        omkar@espl ~/D/O/K/K/pod_concepts> cat configproperty/postgres.properties # Update the below content in properties file
        POSTGRES_DB=postgresdb
        POSTGRES_USER=admin
        POSTGRES_PASSWORD=password
        PGDATA=/var/lib/postgresql/data/pgdata                                                                                                                                           
    ```

2. step-2
    ```bash
        omkar@espl ~/D/O/K/K/pod_concepts [0|1]> kubectl create configmap postgres-config --from-env-file=/home/omkar/Documents/Other/K8sAngularFlaskPSQL/K8s/pod_concepts/configproperty/postgres.properties # RUN command which will create configmap named as  `postgres-config`
        configmap/postgres-config created
    ```
3. Step-3

    ```yaml
        apiVersion: v1
        kind: Pod
        metadata:
        name: pd-pod-name # POD NAME
        labels:
            app: pd-label  # POD LABEL FROM WHICH POD WILL BE RECOGNISED OR SELECTED BY OTHER SERVICES
        spec:
        containers:
            - name: db-pod-con-name # CONTAINER NAME
            image: 'postgres:12'
            envFrom:  # LOAD ALL THE KEY=VALUE FROM CONFIGMAP AS ENVIRONMENTAL VARIABLES   
                - configMapRef:
                    name: postgres-config # name of the configmap
    ```

4. step-4
    ```bash
        # Create Pod In which Env varriables are loaded from configmap 
        omkar@espl ~/D/O/K/K/pod_concepts> kubectl apply -f pod.yaml # 
        pod/pd-pod-name created
        omkar@espl ~/D/O/K/K/pod_concepts> kubectl get pods
        NAME          READY   STATUS    RESTARTS   AGE
        pd-pod-name   1/1     Running   0          3s
    ```

5. step-5:

```bash
# Try To connect pod 
omkar@espl ~> kubectl port-forward pd-pod-name 8888:5432
Forwarding from 127.0.0.1:8888 -> 5432
Forwarding from [::1]:8888 -> 5432

omkar@espl ~> psql -h 127.0.0.1 -p 8888 -U admin -d postgresdb
Password for user admin: 
psql (14.9 (Ubuntu 14.9-0ubuntu0.22.04.1), server 12.13 (Debian 12.13-1.pgdg110+1))
Type "help" for help.

postgresdb=#    # Connected successfully

```


### 2. Declarative Approach (Using yaml file to  create configmap):

```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config # name of the configmap
  labels:
    app: postgres
data:
  POSTGRES_DB: postgresdb
  POSTGRES_USER: admin
  POSTGRES_PASSWORD: password
  PGDATA: /var/lib/postgresql/data/pgdata    
```


```yaml
# pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pd-pod-name # POD NAME
  labels:
    app: pd-label  # POD LABEL FROM WHICH POD WILL BE RECOGNISED OR SELECTED BY OTHER SERVICES
spec:
  containers:
    - name: db-pod-con-name # CONTAINER NAME
      image: 'postgres:12'
      envFrom:  # LOAD ALL THE KEY=VALUE FROM CONFIGMAP AS ENVIRONMENTAL VARIABLES   
        - configMapRef:
            name: postgres-config  # name of the configmap
```




```bash

omkar@espl ~/D/O/K/K/pod_concepts> cd configproperty/ 
omkar@espl ~/D/O/K/K/p/configproperty> ls
configmap.yaml  postgres.properties
omkar@espl ~/D/O/K/K/p/configproperty> kubectl apply -f configmap.yaml  # apply configmap file
configmap/postgres-config created
omkar@espl ~/D/O/K/K/p/configproperty> cd ..
omkar@espl ~/D/O/K/K/pod_concepts> ls
configproperty  pod.yaml  README.md
omkar@espl ~/D/O/K/K/pod_concepts> kubectl apply -f pod.yaml # apply pod file
pod/pd-pod-name created
omkar@espl ~/D/O/K/K/pod_concepts> kubectl get pods # Check if pod is in running mode
NAME          READY   STATUS    RESTARTS   AGE
pd-pod-name   1/1     Running   0          4s
omkar@espl ~/D/O/K/K/pod_concepts> kubectl port-forward pd-pod-name 8888:5432  # Forware pod port to 8888
Forwarding from 127.0.0.1:8888 -> 5432

omkar@espl ~> psql -h 127.0.0.1 -p 8888 -U admin -d postgresdb  # Try to connect the pod database
Password for user admin: 
psql (14.9 (Ubuntu 14.9-0ubuntu0.22.04.1), server 12.13 (Debian 12.13-1.pgdg110+1))
Type "help" for help.   # Connection successfully

```


### How to specify env variables selectiveley.

```yaml
# pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pd-pod-name # POD NAME
  labels:
    app: pd-label  # POD LABEL FROM WHICH POD WILL BE RECOGNISED OR SELECTED BY OTHER SERVICES
spec:
  containers:
    - name: db-pod-con-name # CONTAINER NAME
      image: 'postgres:12'
      env:  # SPECIFY ENV ONE BY ONE 
      - name: POSTGRES_DB
        valueFrom
            configMapRef:
                name: postgres-config # name of the configmap
                key: POSTGRES_DB
```


```yaml
# pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pd-pod-name # POD NAME
  labels:
    app: pd-label  # POD LABEL FROM WHICH POD WILL BE RECOGNISED OR SELECTED BY OTHER SERVICES
spec:
  volumes:
    - name: config-volume
      configMap:
        name: postgres-config
  containers:
    - name: db-pod-con-name # CONTAINER NAME
      image: 'postgres:12'
      env:  # ENVIRONMENTAL VARIABLES
        - name: POSTGRES_DB
          value: postgresdb
        - name: POSTGRES_USER
          value: admin
        - name: POSTGRES_PASSWORD
          value: password
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata

      # command: [ "/bin/sh", "-c", "ls /etc/config/" ]
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config

# Files of each key in each pod will be created
#  /etc/config/POSTGRES_USER will contain the value "admin".
#  /etc/config/API_KEY will contain the value "my-secret-key".
```
```bash

omkar@espl ~/D/O/K/K/pod_concepts> kubectl exec -it pd-pod-name -- /bin/bash # LOG IN TO POD
root@pd-pod-name:/ cd /etc/config/ # VISIT TO  /etc/config
root@pd-pod-name:/etc/config ls  # LIST DOWN ALL THE FILES
PGDATA  POSTGRES_DB  POSTGRES_PASSWORD  POSTGRES_USER  # YOU WILL SEE FILES WITH EACH KEY 
root@pd-pod-name:/etc/config cat PGDATA # CHECK VALUES FOR EACH KEY
/var/lib/postgresql/data/pgdata

```

### Advantages over each other env variables and configmap ?

- ConfigMaps are more suitable for complex or large configuration data, while environment variables are simpler and more straightforward for a small number of variables.
- ConfigMaps can be shared across multiple pods, making them suitable for configurations that need to be consistent across different parts of your application.
- ConfigMaps allow you to update configuration independently of your application code, whereas changing environment variables would typically require updating the pod's YAML and possibly redeploying the application.

### in both case shall i restart the pods ?
- Updating a ConfigMap does not automatically trigger a restart of pods that use it. Pods will continue to use the old configuration until they are restarted.
- When you update an environment variable in a pod's specification, the change takes effect immediately upon pod creation or update. You don't need to explicitly restart the pods for the new environment variables to be applied.

### Disadvantages
- ConfigMaps reside in a specific Namespace. Pods can only refer to ConfigMaps that are in the same namespace as the Pod.



<hr>

# POC-3  Storing Environmental variables with kubernetes secrets: 


```yaml
# secrete.yaml

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
# immutable: true # This will deny to update secrete once it will created

```

```yaml
# pod.yaml

apiVersion: v1
kind: Pod
metadata:
  name: pd-pod-name # POD NAME
  labels:
    app: pd-label  # POD LABEL FROM WHICH POD WILL BE RECOGNISED OR SELECTED BY OTHER SERVICES
spec:
  containers:
    - name: db-pod-con-name # CONTAINER NAME
      image: 'postgres:12'
      envFrom:
      - secretRef:
          name: db-secrete

```

```yaml
    # This template used from get individual variable as column 
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: my-database-secret
          key: password

```

```bash
kubectl apply -f secrete.yaml
kubectl apply -f secrete.yaml

omkar@espl ~/D/O/K8sAngularFlaskPSQL (master)> kubectl port-forward pd-pod-name 5556:5432
Forwarding from 127.0.0.1:5556 -> 5432
Forwarding from [::1]:5556 -> 5432
```

```bash
omkar@espl ~/D/O/K8sAngularFlaskPSQL (master) [1]> psql -h 127.0.0.1 -p 5556 -U admin -d postgresdb
psql (14.9 (Ubuntu 14.9-0ubuntu0.22.04.1), server 12.16 (Debian 12.16-1.pgdg120+1))
Type "help" for help.

postgresdb=# 

```


### *NOTE* 

**Environment variables :** 
- **Purpose:** Environment variables are used to pass configuration and runtime information to applications running inside containers. They are simple key-value pairs that are set as environment variables within a container.

- **Use Case:** Use environment variables when you need to configure your application with simple, non-sensitive data that is known at runtime. For example, you can use environment variables to specify database connection strings, API endpoints, or application-specific configuration settings.

**Secrets :**

- **Purpose:** Secrets are used to store sensitive or confidential data, such as passwords, API tokens, and SSL certificates, in a secure manner. They are base64-encoded and can be mounted as files or exposed as environment variables to Pods.

- **Use Case:** Use Secrets when you need to securely manage and distribute sensitive information to your application containers. For example, you can use Secrets to store database credentials, API keys, or SSL certificates.

**ConfigMaps :**
- **Purpose:** ConfigMaps are used to store configuration data that is not sensitive. They can be used to decouple configuration from application code, making it easier to manage and update configuration settings.

- **Use Case:** Use ConfigMaps when you have configuration data, such as application settings, environment variables, or configuration files, that needs to be made available to your application containers. ConfigMaps are particularly useful for configuration that can change between environments (e.g., development, staging, production).

