POC:  Resource Limit and Request


```NOTE: If the node where a Pod is running has enough of a resource available, it's possible (and allowed) for a container to use more resource than its request for that resource specifies. However, a container is not allowed to use more than its resource limit.```


**ResourceQuota is a Kubernetes resource that allows you to specify and limit the amount of compute resources (CPU and memory) and the number of objects (such as pods, services, and persistent volume claims) that can be consumed within a specific namespace. ResourceQuotas help in enforcing resource usage policies and ensuring that different teams or applications within a Kubernetes cluster do not consume more resources than allocated to them.**

```yaml

apiVersion: v1
kind: ResourceQuota
metadata:
  name: example-resourcequota
spec:
  hard:
    pods: "10"               # Maximum number of pods
    requests.cpu: "2"        # Maximum CPU request in millicores
    requests.memory: 2Gi     # Maximum memory request
    limits.cpu: "4"          # Maximum CPU limit in millicores
    limits.memory: 4Gi       # Maximum memory limit

```