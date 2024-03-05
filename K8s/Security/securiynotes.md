1. Kuberneties Security Premitives:
    
    - Disable password based authentication on all the machines
    - Only ssh key based authentication is enabled
    - The main entrypoint for any action is enabled through `kubeapi-server`
    - So wee need to take two decisions like `who can access the server ?` and `what can they do ?`
        *  **who can access the server ?** : 
            - This is defined  by authentication mechanism
            - You can use username and passwords stored in files
            - YOu can use username and tokens
            - You can use certificates
            - YOu can user LDAP authentication 
            - You can use service accounts
        * **What can they do ?** : 
             - You can use RBAC (Role based access controls)
             - You can use ABAC (Atribute based access control)
             - Node Authorization 
             - Webhook mode
    - All the communication within cluster like ETCD , kubeschedular and kube-apiserver is enabled by tls certificate
    - All the communication within application in cluster can be restricted using network policies. By default is `not configured` and communicate all.

            
2. Authentication:
    - There are three types of user 
        * `Admin` : 
        * `Developes` :
        * `Application End User` : This user managed by developers inside app authentication mechanism.
        * `Bots` : Other services like through python

    - Using static file , username/password or username/tokens:
        - not used much in industry. 
        - You need to create one csv file and keep it in one location
        

3. TLS Basics: 
    1. Symmetric Ecnryption

        - Its kind of `fernet` authentication where you encrypt the data with key and same key you pass to the server to decrypt it.
        - exp. {'username':'user','password':'pass'}  + encrypt with {key}  --> server --> {'username':'user','password':'pass'} + decrypt with {key}
        - here passing the key with data is insecure because anyone who find it can easily get username and password

    2. Assymetric Encryption :
        - it uses pair of keys `public key` and `private key`
        - Here you encrypt the data with `public key` then only it can be decrypted with `private key`
        - Process of passwordless authentication:
           1. `ssh-keygen` Generate public and private key 
           2. `ssh-copy-id username@host-ip` Copy Public key to remote server this will copy to `.ssh/authorized_keys` file with <key> <user-name>.
           3. `ssh username@host-ip`  check passwordless
           4. For other servers you can copy same public key to all servers `.ssh/authorized_keys` file.
        
4. TLS in Kubernetes :
    * Public Keys: `*.crt , *.pem` Private Keys `*.key, *-key.pem`
    1. Root Certificates (Certificate authority certificates ie. for local we generate it by ourself): used to sign the client and admin certificates
    2. Client Certificate 
    3. Admin Certificate 

    * Kubernetes used two types of certificates:
        1. Server Certificates for server(Pub, priv)
            * kube-api 
            * ETCD 
            * kubelet

        2. Client certificates for cliets
            * local_laptop certificated used by admin (Admin certificates)
            * schedular
            * kubectl (controller)
            * kube-proxy

5. TLS in Kubernetes – Certificate Creation:

    1. Create Certificate Authority:
        1. Generate Keys: `openssl genrsa -out ca.key 2048`
        2. Certificate signing request: `openssl req -new -key ca.key -subj "/CN=KUBERNETES-CA" -out ca.csr`  (KUBERNETES-CA: is common name for certificate)
        3. Sign certificate : `openssl x509 -req -in ca.csr -signkey ca.key -out ca.crt` 
    
    2. Generate one of the client certificate for admin user:
        1. Generate Keys: `openssl genrsa -out admin.key 2048`
        2. Certificate signing request: `openssl req -new -key admin.key -subj "/CN=kube-admin/O=system:masters" -out admin.csr`  (kube-admin: is common name for certificate. O=system:masters : for masters group)
        3. Sign certificate : `openssl x509 -req -in admin.csr -CA ca.crt -CAkey ca.key -out admin.crt`

        4. Note: All the client used same process of creating certificate and in admin laptop kube-config file you can specify admin certificates. **ca.crt must be present in call client machines**

    3. Generate one of the server certificates:
        - for etcd we create same as above client 

        - Generate for kube-api server 
            1. Generate Keys: `openssl genrsa -out api-server.key 2048`
            2. Note that all the component in cluster recognise to api server with different dns name like 
            kubernetes, kubernetes.defualt  ,kubernetes.defualt.svc, kubernetes.default.svc.cluster.local and ip of the server on which api-server to being installed.
            3. To specify all the these dns name openssl.cnf and set 
                ```yaml
                DNS.1 = kubernetes
                DNS.2 = kubernetes.defualt
                DNS.3 = kubernetes.defualt.svc
                DNS.4 = kubernetes.default.svc.cluster.local

                IP.1 = Server IP
                IP.2 = Private.ip

                ```
            4. Certificate signing request: `openssl req -new -key api-server.key -subj "/CN=api-server" -out api-server.csr -config openssl.cnf`
            
            5. Sign certificate : `openssl x509 -req -in api-server.csr -CA ca.crt -CAkey ca.key -out api-server.crt --extensions v3_req -extfile openssl.cnf --days 1000`
        
        - kubectl nodes:
            - Generate kubectlet key and crt for all nodes separately and specify the path to all kubelet-config.yaml file
              ie. clienCAFile (ca.pem),  tlsCertFile (node01.crt), tlsPrivateKeyFile (node01.key)

            - subject should containe `/o:system:nodes`


        - in the case of kubeadm the all the certificate are generated automatically.

6. View Certificate Details:
     - cat `/etc/kubernetes/manifests/kube-apiserver.yaml`

     - check certificates details: `openssl x509 -in /etc/pki/apiserver.crt -text -noout` 

     - check `kubectl logs etcd-masters` to check certificates used by etcd and its path 
     - OR you can do docker container ls and check logs `docker logs <container_id>`


     * **Practical To check certificates :**
        1.  If something happes to etcd certificats confi in etcd.yaml or apiserver.yaml file in manifests folder then
        kubernetes can go down.
        

7. Certificate API:
    - **Problem statement**: As the admin of the cluster admin have created all the ca server and certificates to get access to
    the cluster. Now new admin comes to my team. Now he does not have acces to my cluster . He will generate his own private key.
    sends to certificate sign in request and send it to me. Admin will send this request to cluster/master and return approved response back to the new admin. Now admin can do it. *Note: Certificate has validaty period after every expiry you need to follow same steps*

    - **Solution** : To make this process easy i.e also admin can be rights to approve the request. For that master node have the certificate-api. Once request comes to admin, admin will also can review the request and approve the same and share certificate back to user.
        * `openssl genrsa -out new-admin.key 2048`
        * `openssl req -new -key new-admin.key -subj "/CN=new-admin" -out new-admin.csr`
        * cat new-admin_Req.yaml
        * cat new-admin.csr | base64
        * copy context and paste to request: 
            ```yaml 
                apiVersion: certificates.k8s.io/v1
                kind: CertificateSigningRequest
                metadata:
                name: new-admin
                spec:
                request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJQ1ZqQ0NBVDRDQVFBd0VURVBNQTBHQTFVRUF3d0dZV3R6YUdGNU1JSUJJakFOQmdrcWhraUc5dzBCQVFFRgpBQU9DQVE4QU1JSUJDZ0tDQVFFQXN6Y2lpbzVScWJveC9XSkQ3MkpKK0NoNFd3TFIyeFlvMGNoVm5ONDdZOGNwClREamlTSjFMbFdLMkpWNk1uQnF3S0YxdFpYWVJTd0R0ZEt1WVhmbHdoVitLanhaTitaYSszVmJ6RUp2MjdsN2UKajJvSmxYKzcrd0hqOFNBNXoxRDN3UzdsSnZqSTVmaDhYVGVRTmZwc25tcm1XRWN2Ulp0TDhCcHJhQ0ZJRElSago4Mk1KNjJ0cnkrSm9pODRQdjdNWTRSNm4wK0JBV0Y2MFl0akNVUmtwZG9FNzlQeThvQUxzTWhWVG1lc0RKRWt2CnBNTEJaSGR4UVBFcGtBSGdRTS9VSlUrTk5kRlRRVG9sTGRGNjNoSkFxVXB3YzJHMUI0Qlg5Ykc5d1RNcEo1MHMKK1liT1duSjVheEYxekZsWGRFTHRGZXNCU0NFandkRU8yN0dxSDFjR0hRSURBUUFCb0FBd0RRWUpLb1pJaHZjTgpBUUVMQlFBRGdnRUJBQ0lzbk44MHFSVDAvUkxsbXFOZFI0bWJ5UWhLTkJtQmc5VSs0ZFBWdnNMWUpKTjBMQ3V6Cm1DbEVsTFllRU1DWU1pYU5sazVjM1Bhc21aQytKVDYraEp1RXFQUlorN3NBQXp4QTNhUWZQajJueW05ZjBpelcKZHlRTnUvNnFwSmYwQisyWGlRU0lRUmlKN0xwVWFYSUNlRm1JaHdZbm54UW9GUTFqOE1XamwvVXUycUxpYWp2NgowVjNxNndibUZFOGM2QzNGNk9wM1YwRVFtZHhML2gxbVpOb2JYdS96bzJtSFRVaXcrOFhVWjk1a2lvcUpNUGFiCllOSXVXNVhhNEJqbDE2ZGdUdSsrd09yd1pmRFNiNWFKUEhheS9xVEo2OU1rR3FVS2N3SUc3VCtjcG1hQmYwUlMKRzdBVTRRMEhtNktCN1RuSWUrM2MrL0FKWnh5RmNUUEEzbmc9Ci0tLS0tRU5EIENFUlRJRklDQVRFIFJFUVVFU1QtLS0tLQo=
                signerName: kubernetes.io/kube-apiserver-client
                usages:
                - client auth
                ```
        * `kubectl get csr`  check requests`
        * `kubectl certificate approve new-admin`
        * `kubectl get csr new-admin -o yaml`
        * `echo <certificate-text> | base64 --decode
        *  now share this certificate with end new-admin

8. Kube-config
    - To list down resources used the server address, client-key, client-certificate, certificate-authority  , for exp.
     `kubectl get pods --server <api-address> --client-key <admin.key> --client-certificate <admin.crt> --certificate-authority <ca.crt>` 
    - To make it simplified all the other params are set in kubeconfig file
    - Default path `$HOME/.kube/config
    - Config file has three parts: 
        1. **clusters**  : develpment, production exp .(--server <api-address>, certificate-authority)
        2. **Users** : admin , dev , prod  exp.(--client-key, --client-certificate)
        3. **Contexts**  : it tells which user access which account exp. admin@production

    - `kubectl config use-context test-1  --kubeconfig /root/myconfig.yaml`

9. Kubernetes api:
    - kubernetes api are which returns the kub config information and resource information on curl
    - exp. `curl https://kube-masters:6443/version` will return version 
    - `/api/v1/pods` will return pods
    - There are different kind of apis present like `/metrics` , `/healthz`, `/version` , `/api`, `/apis`, `/logs` 

    - There are two kind of apis we are focus on 

        1. /api (core): 
            - /v1
                - /namespace
                - /pods
                - /rc
                - /events
                - /pv
                - /pvcs
                - /nodes
                - /configmaps   etc

        2. /apis (named):
            - /apps
            - /extensions
            - /newtworking.k8s.io
            - etc

10. Authorization:
    
    - As we have different kind of users. all users should have different of permissions to perform on cluster.
    - There are four types of authorization supported in kubernets:
        1. Node:
            * Node will have access through read pods and all from kube api server with node authorization technique
            * Node has node status write permission in cluster to master node
            * 
        2. ABAC:
            * Here we set attributes like dev-user ==> can view pod, can create pod, can-delete pod
            * ```json
                  // For each user you need to specify different policy separately
                    {
                        "kind" : "Policy",
                        "spec" : {
                            "user" : "dev-user",
                            "namspace" : "*",
                            "resource" : "pods",
                            "apiGroup":"*"
                        }
                    }

                     {
                        "kind" : "Policy",
                        "spec" : {
                            "user" : "security-1",
                            "namspace" : "*",
                            "resource" : "csr",
                            "apiGroup":"*"
                        }
                    }


                ```
        3. RBAC (Mostly used):
            * here we set role first and assign different kind of permssions to it
            * And then we asscociate all the developers to it
        4. Webhook

        5. AlwaysAllow / AlwaysDeny

    - in kube-api configuration file `--authorization-mode= < comma separated types>`  is used to configure authorization
    - If more than one is specified , request is authorized throuh all technique one after another.


11. RBAC:
    
    - create one role named as developer
        - Refer `role.yaml`
        - `kubectl create  -f role.yaml`
    - bind the role to user
        - Refer  `role-bind.yaml`
        - `kubectl create -f role-bin.yaml`

    - `kubectl get roles`
    - `kubectl get rolebindings`
    - `kubectl describe role developer`

    - Check :
        * `kubectl auth can-i create deployment`
        * `kubectl auth can-i delete nodes --as dev-user --as namespace test`
        * etc




12. Cluster Roles:
    - RBAC is created within specifi namespaces
    - Resources are categorized in two parts
        1. Namspaced
            - pods, replicaset, jobs, deployments, services, secrets, `roles`, `rolebindings`, configmaps, pvc etc
            - default created in defaul namespace
            - check via `kubectl api-resources --namespaced=true`
        2. Cluster Scoped
            - nodes, pv, `clusterroles`,  `clusterbindings`, namespaces, certificatesigninrequest etc
            - check via `kubectl api-resources --namespaced=false`

    - example. cluster-admin => can view node, can create node, can delete node
    -           storage-admin => can create pv, can delete pv, can view pv

    - create cluster role check `cluster-role.yaml`
    -  `kubectl create -f cluster-role.yaml`
    - create cluster role binding `cluster-binding.yaml`
    -  
    - **If you created the cluster role for namespaced resources then this user will have access across all namespaces**
    -  For exp. Pods in all the namespaces


13. Security context:
   - adding username and password for docker hub

14. Network Policies :

    - adding ingress (inbound) , and egress(outbound) policies