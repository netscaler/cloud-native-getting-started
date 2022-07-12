# Developer Persona

## The Setup  
![](assets/sml-page-2.png)

The diagram above illustrates the environment at a high-level. There is a GKE cluster in which I will deploy my application, with an external Citrix VPX acting as a TCP ingress to forward traffic into the cluster and an ADC CPX as a Tier 2 Ingress controlling the North - South Traffic for my apps. My application is following a Service Mesh Lite Architecture where more than one CPXs are deployed in my GKE cluster to handle also East - West Traffic.

My CPX that will handle the North - South traffic will be used to apply mTLS, Web Application Firewall (WAF) protection, Rate-Limiting and ,manipulate the requests by adding extra mandatory HTTP headers. Citrix VPX appliance is usually managed by external teams and adheres to corporate application delivery standards, but allows me to specify my configuration when required. For our purpose though we only use VPX to forward traffic within GKE. 

On the other hand Citrix CPX is fully managed by me and my team and we are responsible to configure it based on our Applications requirements.

As a developer, I am responsible for deploying applications to a Google GKE and ensuring that my application is available and complies to my corporate deployment standards. Ingress into my application needs to permit and protect access to the application.

## The Why  

Deploying applications into a Google GKE allows me, the developer, to set specific network configurations as simple annotations within my kubernetes manifests. I don't need to learn an additional platform or tool, and this configuration will be applied in accordance with any constraints set out by the platform, network, and security teams. This allows my application to get to market faster with less internal meetings, approvals, or change requests.  

My platform and security teams have requested that I protect my application by applying North - South mTLS. In addition to that they requested to use Citrix WAF, Rate-limiting and Rewrite / Responder capabilities in accordance to my application needs for better protection. As the developer, I am responsible for ensuring that the all configurations are appropriate for my application. Luckily Citrix provides Kubernetes Custom Resources that I can use to define the right policy without needing to engage with other teams, and still be compliant with my platform and security teams requirements.  


## The How  

---
**NOTE**
In this demonstration, the kubectl binary and local files are used to deploy the application. In production scenarios, other deployment methods would likely be in place, such as a GitOps approach like Google Anthos Configuration Management / Argo CD, Flux CD or any other.  

---

First I will deploy the sockshop sample application manifests. I will then deploy Citrix components, and then the ingress resources required to configure ADCs. These steps help to outline the control I have over the ingress to apply protections into my application, without the need to engage with the network or security team to make Application Delivery Controller configuration changes. 
- Deploy the sockshop demo application 
  ```shell
    sh-5.1$ kubectl apply -f sockshop/microservices.yaml
    NAME                                     READY   STATUS    RESTARTS   AGE
    carts-7c9df6fdb4-tmg8w         1/1     Running   0          5m15s
    carts-db-6c6c68b747-m8d85      1/1     Running   0          5m19s
    catalogue-7c6dcb64f7-qwkgw     1/1     Running   0          5m6s
    catalogue-db-96f6f6b4c-29kgn   1/1     Running   0          5m11s
    front-end-7b8bcd59cb-jbmfb     1/1     Running   0          5m2s
    orders-c9994cff9-psqxj         1/1     Running   0          4m53s
    orders-db-659949975f-xnqxd     1/1     Running   0          4m58s
    payment-8576977df5-4k28w       1/1     Running   0          4m49s
    queue-master-bbb6c4b9d-mr28x   1/1     Running   0          4m44s
    rabbitmq-6d77f74dc-2db2b       1/1     Running   0          4m39s
    shipping-5d7c4f8bbf-5mcmp      1/1     Running   0          4m35s
    user-846f474c46-rnqlg          1/1     Running   0          4m27s
    user-db-5f68d7b558-6n4z7       1/1     Running   0          4m31s
  ```
- Open manifest file that contains all CIC and CPX configuration. Verify that NSIP and VIP are correct for VPX. Also check the name of the Kubernetes secret (nscred) required by CIC to authenticate on VPX.
  ```shell
    sh-5.1$ cat sockshop/ctx.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
    name: sml-cic
    namespace: default
    spec:
    selector:
        matchLabels:
        app: sml-cic
    replicas: 1
    template:
        metadata:
        name: cic
        labels:
            app: sml-cic
        spec:
        serviceAccountName: sml-cic
        containers:
        - name: cic
            image: quay.io/citrix/citrix-k8s-ingress-controller:1.25.6
            imagePullPolicy: IfNotPresent
            args:
            - --configmap default/sml-cic-configmap
            - --ingress-classes tier-1-vpx
            - --feature-node-watch true
            - --update-ingress-status yes
            env:
            - name: NS_IP
            value: 10.162.15.237
            - name: NS_VIP
            value: 192.168.40.2
            - name: NS_USER
            valueFrom:
                secretKeyRef:
                name: nscred
                key: username
            - name: NS_PASSWORD
            valueFrom:
                secretKeyRef:
                name: nscred
                key: password
            - name: EULA
            value: 'yes'
            - name: NS_APPS_NAME_PREFIX
            value: k8s
            resources: {}
  ```
  - Validate the correctness of values by checking the VPX Compute Engine VM Instance created using the terraform script in the previous steps Google Cloud Console > Compute Engine > VM Instances > {name-of-vpx}
  - Create the Kubernetes Secret (nscred) we saw in the last step
  ```shell
    sh-5.1$ kubectl create secret generic nscred --from-literal=username='{vpx-username}' --from-literal=password='{vpx-password}'
    secret/nscred created
  ```
  - Deploy CIC and CPXs along with their relevant ServiceAccounts, RBAC configurations and IngressClasses
    Verify that cic and cpx are deployed and running.
  ```shell
    sh-5.1$ kubectl apply -f sockshop/ctx.yaml
    NAME                           READY   STATUS    RESTARTS   AGE
    carts-7c9df6fdb4-tmg8w         1/1     Running   0          32m
    carts-db-6c6c68b747-m8d85      1/1     Running   0          32m
    catalogue-7c6dcb64f7-qwkgw     1/1     Running   0          32m
    catalogue-db-96f6f6b4c-29kgn   1/1     Running   0          32m
    front-end-7b8bcd59cb-jbmfb     1/1     Running   0          32m
    orders-c9994cff9-psqxj         1/1     Running   0          31m
    orders-db-659949975f-xnqxd     1/1     Running   0          31m
    payment-8576977df5-4k28w       1/1     Running   0          31m
    queue-master-bbb6c4b9d-mr28x   1/1     Running   0          31m
    rabbitmq-6d77f74dc-2db2b       1/1     Running   0          31m
    shipping-5d7c4f8bbf-5mcmp      1/1     Running   0          31m
    sml-cic-cf4b7cddc-47z9m        1/1     Running   0          12s
    sml1-cpx-759984bd99-hgvh8      2/2     Running   0          16s
    sml2-cpx-54659dcc79-8gsjw      2/2     Running   0          15s
    sml3-cpx-bbc958ddc-v9mt5       2/2     Running   0          14s
    user-846f474c46-rnqlg          1/1     Running   0          31m
    user-db-5f68d7b558-6n4z7       1/1     Running   0          31m
  ``` 

  ### North - South mTLS using CPX
  In our first use case we will see how to configure our CPX to apply mTLS for our North - South traffic.
  Please follow next steps to see that.

  - Open manifest file that contains all Ingress resource definitions for our CIC and CPX and check how we have configure VPX and CPXs to handle North-South and East-West traffic. We are using VPX only for TCP ingress. Also check Ingress for CPX that handles the North-South traffic entering our Kubernetes cluster. 
  ```shell
    sh-5.1$ cat sockshop/ingresses.yaml
    ### VPX Start
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
    name: tier1-vpx-ingress
    annotations:
        ingress.citrix.com/insecure-port: "443"
        ingress.citrix.com/insecure-service-type: tcp
        kubernetes.io/ingress.class: "tier-1-vpx"
    spec:
    defaultBackend:
        service:
        name: sml1-cpx-service
        port:
            number: 443
    ### VPX End
    ---
    ### Front-End HTTP Start
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
    name: front-end-ingress
    annotations:
        ingress.citrix.com/insecure-service-type: "http"
        ingress.citrix.com/insecure-port: "80"
        kubernetes.io/ingress.class: "tier-2-cpx1"
    spec:
    rules:
    - host: front-end
        http:
        paths:
        - backend:
            service:
                name: front-end-headless
                port:
                number: 80
            path: /
            pathType: ImplementationSpecific
    ### Front-End HTTP End
    ---
    ### Front-End HTTPS Start
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
    name: front-end-ns-ingress
    annotations:
        ingress.citrix.com/ca-secret: '{"front-end-headless": "sockshop-ca-secret"}'
        ingress.citrix.com/frontend-sslprofile: '{"clientauth":"enabled"}'
        ingress.citrix.com/secure-port: "443"
        kubernetes.io/ingress.class: "tier-2-cpx1"
    spec:
    tls:
    - secretName: sockshop-secret
    rules:
    - host: sockshop.citrix
        http:
        paths:
        - backend:
            service:
                name: front-end-headless
                port:
                number: 80
            path: /
            pathType: ImplementationSpecific
        ### Front-End HTTPS End
        ---
  ```
  - As we see in the front-end-ns-ingress definition our Ingress Resource requires 2 Kubernetes secrets. One for our Certificate Authority and one for our TLS. Let's create these 2 secrets
  ```shell
    sh-5.1$ kubectl create secret generic sockshop-ca-secret --from-file=tls.crt=certs/ns-root.cert
    secret/sockshop-ca-secret created
    sh-5.1$ kubectl create secret tls sockshop-secret --cert=certs/myCert --key=certs/myKey
    secret/sockshop-secret created
    sh-5.1$ kubectl get secrets
    NAME                   TYPE                                  DATA   AGE
    nscred                 Opaque                                2      31m
    sockshop-ca-secret     Opaque                                1      119s
    sockshop-secret        kubernetes.io/tls                     2      62s
  ```
  - Now that our Secrets are in place lets deploy all our Ingress configuration
  ```shell
    sh-5.1$ kubectl apply -f sockshop/ingresses.yaml
    ingress.networking.k8s.io/carts-db-ingress created
    ingress.networking.k8s.io/carts-ingress created
    ingress.networking.k8s.io/catalogue-db-ingress created
    ingress.networking.k8s.io/catalogue-ingress created
    ingress.networking.k8s.io/front-end-ingress created
    ingress.networking.k8s.io/front-end-ns-ingress created
    ingress.networking.k8s.io/orders-db-ingress created
    ingress.networking.k8s.io/orders-ingress created
    ingress.networking.k8s.io/payment-ingress created
    ingress.networking.k8s.io/queue-master-ingress created
    ingress.networking.k8s.io/rabbitmq-ingress created
    ingress.networking.k8s.io/shipping-ingress created
    ingress.networking.k8s.io/user-db-ingress created
    ingress.networking.k8s.io/user-ingress created
    ingress.networking.k8s.io/tier1-vpx-ingress created
  ```
  - Lets Visit VPX now to see the TCP LB Virtual Server created, that points to our CPX inside our GKE cluster. We can see **a service group has been created pointing to our CPX (10.8.0.18) that handles North - South GKE traffic**
  ```script
  sh-5.1$ ssh {username}@{nsip}
  sh-5.1$ sh lb vserver
  
  k8s-sml1-cpx-service_443_lbv_gitvn5l6xa4s7vpztdyhpuqzlawqmvhf (0.0.0.0:0) - TCP	Type: ADDRESS
  State: UP
  Last state change was at Tue Jul 12 09:03:33 2022
  Time since last state change: 0 days, 00:52:56.600
  Effective State: UP  ARP:DISABLED
  Client Idle Timeout: 9000 sec
  Down state flush: ENABLED
  Disable Primary Vserver On Down : DISABLED
  Comment: "rv:506780,ing:tier1-vpx-ingress,ingport:443,ns:default,svc:sml1-cpx-service,svcport:443"
  Appflow logging: ENABLED
  No. of Bound Services :  1 (Total) 	 1 (Active)
  Configured Method: LEASTCONNECTION
  Current Method: Round Robin, Reason: Bound service's state changed to UP	BackupMethod: ROUNDROBIN
  Mode: IP
  Persistence: NONE
  Connection Failover: DISABLED
  L2Conn: OFF
  Skip Persistency: None
  Listen Policy: NONE
  IcmpResponse: PASSIVE
  RHIstate: PASSIVE
  New Service Startup Request Rate: 0 PER_SECOND, Increment Interval: 0
  Mac mode Retain Vlan: DISABLED
  DBS_LB: DISABLED
  Process Local: DISABLED
  Traffic Domain: 0
  TROFS Persistence honored: ENABLED
  Retain Connections on Cluster: NO
  Order Sequence: ASCENDING
  Current Active Order: None

  sh lb vserver k8s-sml1-cpx-service_443_lbv_gitvn5l6xa4s7vpztdyhpuqzlawqmvhf

  k8s-sml1-cpx-service_443_lbv_gitvn5l6xa4s7vpztdyhpuqzlawqmvhf (0.0.0.0:0) - TCP	Type: ADDRESS
  State: UP
  Last state change was at Tue Jul 12 09:03:33 2022
  Time since last state change: 0 days, 00:55:27.100
  Effective State: UP  ARP:DISABLED
  Client Idle Timeout: 9000 sec
  Down state flush: ENABLED
  Disable Primary Vserver On Down : DISABLED
  Comment: "rv:506780,ing:tier1-vpx-ingress,ingport:443,ns:default,svc:sml1-cpx-service,svcport:443"
  Appflow logging: ENABLED
  No. of Bound Services :  1 (Total) 	 1 (Active)
  Configured Method: LEASTCONNECTION
  Current Method: Round Robin, Reason: Bound service's state changed to UP	BackupMethod: ROUNDROBIN
  Mode: IP
  Persistence: NONE
  Connection Failover: DISABLED
  L2Conn: OFF
  Skip Persistency: None
  Listen Policy: NONE
  IcmpResponse: PASSIVE
  RHIstate: PASSIVE
  New Service Startup Request Rate: 0 PER_SECOND, Increment Interval: 0
  Mac mode Retain Vlan: DISABLED
  DBS_LB: DISABLED
  Process Local: DISABLED
  Traffic Domain: 0
  TROFS Persistence honored: ENABLED
  Retain Connections on Cluster: NO
  Order Sequence: ASCENDING
  Current Active Order: None

  Bound Service Groups:
  1)	Group Name: k8s-sml1-cpx-service_443_sgp_gitvn5l6xa4s7vpztdyhpuqzlawqmvhf

      1) k8s-sml1-cpx-service_443_sgp_gitvn5l6xa4s7vpztdyhpuqzlawqmvhf (10.8.0.18: 443) - TCP State: UP	Weight: 1 Order:

  1)	CSPolicy: 	CSVserver: k8s-192.168.40.2_443_tcp	Priority: 0	Hits: 8
  ```

  You can see same details from VPX GUI in the following screeshot:
  ![](/assets/VPX-lbvserver.png) 


  - Lets now login to our CPX through CLI and check our configuration there. We will see out **SSL Virtual Server** and **SSL Profile** created and that our SSL Profile has **CLIENT Authentication Enabled**. 
  ```shell
  sh-5.1$ kubectl get pods | grep cpx
  sml1-cpx-759984bd99-hgvh8      2/2     Running   0          106m
  sml2-cpx-54659dcc79-8gsjw      2/2     Running   0          106m
  sml3-cpx-bbc958ddc-v9mt5       2/2     Running   0          106m
  sh-5.1$ kubectl exec -it sml1-cpx-759984bd99-hgvh8 bash
  root@sml1-cpx-759984bd99-hgvh8:/# nscli -U :nsroot:$(cat /var/random_id)
  root@sml1-cpx-759984bd99-hgvh8:/# sh sslvserver
  1) VServer Name: k8s-10.8.0.18_443_ssl
	Profile Name :k8s-10.8.0.18_443_ssl
  root@sml1-cpx-759984bd99-hgvh8:/# sh sslvserver k8s-10.8.0.18_443_ssl
  Advanced SSL configuration for VServer k8s-10.8.0.18_443_ssl:
	Profile Name :k8s-10.8.0.18_443_ssl
  1)	CertKey Name: k8s-7OKGABPEZVZBWCDCQOJ2VC3Z2VM	Server Certificate
  2)	CertKey Name: k8s-3BXDB3TH6MHSSMA2EP22YJQXP6K	CA Certificate		OCSPCheck: Optional		CA_Name Sent

  root@sml1-cpx-759984bd99-hgvh8:/# sh ssl profile k8s-10.8.0.18_443_ssl
  1)	Name: k8s-10.8.0.18_443_ssl 	(Front-End)
	SSLv3: DISABLED	TLSv1.0: ENABLED  TLSv1.1: ENABLED  TLSv1.2: ENABLED  TLSv1.3: DISABLED
	Client Auth: ENABLED	Client Cert Required: Mandatory
	Use only bound CA certificates: DISABLED
	Strict CA checks:		NO
	Session Reuse: ENABLED		Timeout: 120 seconds
	DH: DISABLED
	DH Private-Key Exponent Size Limit: DISABLED	Ephemeral RSA: ENABLED		Refresh Count: 0
	Deny SSL Renegotiation		ALL
	Non FIPS Ciphers: DISABLED
	Cipher Redirect: DISABLED
	SSL Redirect: DISABLED
	Send Close-Notify: YES
	Strict Sig-Digest Check: DISABLED
	Zero RTT Early Data: DISABLED
	DHE Key Exchange With PSK: NO
	Tickets Per Authentication Context: 1
	Push Encryption Trigger: Always
	PUSH encryption trigger timeout:	1 ms
	SNI: DISABLED
	OCSP Stapling: DISABLED
	Strict Host Header check for SNI enabled SSL sessions:		NO
	Match HTTP Host header with SNI:		CERT
	Push flag:	0x0 (Auto)
	SSL quantum size:		8 kB
	Encryption trigger timeout	100 mS
	Encryption trigger packet count:	45
	Subject/Issuer Name Insertion Format:	Unicode

	SSL Interception: DISABLED
	SSL Interception OCSP Check: ENABLED
	SSL Interception End to End Renegotiation: ENABLED
	SSL Interception Maximum Reuse Sessions per Server:	10
	Session Ticket: DISABLED
	HSTS: DISABLED
	HSTS IncludeSubDomains: NO
	HSTS Max-Age: 0
	HSTS Preload: NO
	Skip Client Cert Policy Check: DISABLED
	Allow Extended Master Secret: NO
	Send ALPN Protocol: NONE


	ECC Curve: P_256, P_384, P_224, P_521

  1)	Cipher Name: DEFAULT	 Priority :1
    Description: Predefined Cipher Alias

  1)	Vserver Name: k8s-10.8.0.18_443_ssl

  ```
  - Now that we verified that our configuration is in place lets send an HTTP request to https://sockshop.citrix and see the response we get. **As we did not pass our cert and key, we can see that we get a handshake failure.** 
  ```shell
  sh-5.1$ curl -vk https://sockshop.citrix
  *   Trying 35.203.76.216:443...
  * Connected to sockshop.citrix (35.203.76.216) port 443 (#0)
  * ALPN, offering h2
  * ALPN, offering http/1.1
  * successfully set certificate verify locations:
  *  CAfile: /etc/ssl/cert.pem
  *  CApath: none
  * TLSv1.2 (OUT), TLS handshake, Client hello (1):
  * TLSv1.2 (IN), TLS handshake, Server hello (2):
  * TLSv1.2 (IN), TLS handshake, Certificate (11):
  * TLSv1.2 (IN), TLS handshake, Request CERT (13):
  * TLSv1.2 (IN), TLS handshake, Server finished (14):
  * TLSv1.2 (OUT), TLS handshake, Certificate (11):
  * TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
  * TLSv1.2 (OUT), TLS change cipher, Change cipher spec (1):
  * TLSv1.2 (OUT), TLS handshake, Finished (20):
  * TLSv1.2 (IN), TLS alert, handshake failure (552):
  * error:1401E410:SSL routines:CONNECT_CR_FINISHED:sslv3 alert handshake failure
  * Closing connection 0
  curl: (35) error:1401E410:SSL routines:CONNECT_CR_FINISHED:sslv3 alert handshake failure
  ```
  
  
  - Lets send a request again by also passing our cert and key used for TLS. **We can see that we get a HTTP 200 response and mTLS worked.**
  ```shell
  sh-5.1$ curl --cert certs/myCert --key certs/myKey https://sockshop.citrix -kv | head -n 10
   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0*   Trying 35.203.76.216:443...
  * Connected to sockshop.citrix (35.203.76.216) port 443 (#0)
  * ALPN, offering h2
  * ALPN, offering http/1.1
  * successfully set certificate verify locations:
  *  CAfile: /etc/ssl/cert.pem
  *  CApath: none
  * TLSv1.2 (OUT), TLS handshake, Client hello (1):
  } [229 bytes data]
  * TLSv1.2 (IN), TLS handshake, Server hello (2):
  { [91 bytes data]
  * TLSv1.2 (IN), TLS handshake, Certificate (11):
  { [1130 bytes data]
  * TLSv1.2 (IN), TLS handshake, Request CERT (13):
  { [167 bytes data]
  * TLSv1.2 (IN), TLS handshake, Server finished (14):
  { [4 bytes data]
  * TLSv1.2 (OUT), TLS handshake, Certificate (11):
  } [1130 bytes data]
  * TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
  } [262 bytes data]
  * TLSv1.2 (OUT), TLS handshake, CERT verify (15):
  } [264 bytes data]
  * TLSv1.2 (OUT), TLS change cipher, Change cipher spec (1):
  } [1 bytes data]
  * TLSv1.2 (OUT), TLS handshake, Finished (20):
  } [16 bytes data]
    0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0* TLSv1.2 (IN), TLS change cipher, Change cipher spec (1):
  { [1 bytes data]
  * TLSv1.2 (IN), TLS handshake, Finished (20):
  { [16 bytes data]
  * SSL connection using TLSv1.2 / AES256-SHA
  * ALPN, server accepted to use http/1.1
  * Server certificate:
  *  subject: C=US; ST=CA; O=Citrix; CN=myCustomName
  *  start date: Jul  4 10:43:00 2022 GMT
  *  expire date: Jul  4 10:43:00 2023 GMT
  *  issuer: C=US; ST=California; L=San Jose; O=Citrix ANG; OU=NS Internal; CN=default UOKNQC
  *  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
  > GET / HTTP/1.1
  > Host: sockshop.citrix
  > User-Agent: curl/7.77.0
  > Accept: */*
  >
  * Mark bundle as not supporting multiuse
  < HTTP/1.1 200 OK
  ```
  

  - If we visit again our CPX and check SSL Virtual Server Stats we will see **Client Authentication Success increasing**
  ```shell
  sh-5.1$ kubectl get pods | grep cpx
  sml1-cpx-759984bd99-hgvh8      2/2     Running   0          106m
  sml2-cpx-54659dcc79-8gsjw      2/2     Running   0          106m
  sml3-cpx-bbc958ddc-v9mt5       2/2     Running   0          106m
  sh-5.1$ kubectl exec -it sml1-cpx-759984bd99-hgvh8 bash
  root@sml1-cpx-759984bd99-hgvh8:/# nscli -U :nsroot:$(cat /var/random_id)
  root@sml1-cpx-759984bd99-hgvh8:/# stat ssl vserver
  Virtual Server Summary
                        vsvrIP  port     Protocol        State   Health  actSvcs
  k8s-...3_ssl       10.8.0.18   443          SSL           UP        0        0

  VServer Stats:
                                            Rate (/s)                Total
  Client Authentication Success                      0                    2
  ```

  ### WAF protection using CPX
  In This use case we will see how to enable WAF on our CPX to protect traffic going to our front-end micro-service.
  As most of our configurations require Citrix CRDs to be installed and available on GKE we will first install all CRDs required for this and the following use cases. We will see how to apply a WAF policy to protect our front-end microservice from an SQL Injection attack and we will login to CPX to see how the WAF policy is applied.

  - Lets install WAF, Rate-limiting and Rewrite & Responder CRDs.
  ```shell 
  sh-5.1$ kubectl apply -f crds/
  customresourcedefinition.apiextensions.k8s.io/ratelimits.citrix.com created
  customresourcedefinition.apiextensions.k8s.io/rewritepolicies.citrix.com created
  customresourcedefinition.apiextensions.k8s.io/wafs.citrix.com created
  ```
  - Lets now check the WAF policy we prepared and apply. We will protect front-end microservice and we will test this by sending a malicious SQL Injection attack request.
  ```shell 
  sh-5.1$ cat policies/waf_basic.yaml
  apiVersion: citrix.com/v1
  kind: waf
  metadata:
      name: wafbasic
  spec:
      servicenames:
          - front-end-headless
      security_checks:
          common:
            allow_url: "on"
            block_url: "on"
            buffer_overflow: "on"
            multiple_headers:
              action: ["block", "log"]
          html:
            cross_site_scripting: "on"
            field_format: "on"
            sql_injection: "on"
            fileupload_type: "on"
          json:
            dos: "on"
            sql_injection: "on"
            cross_site_scripting: "on"
          xml:
            dos: "on"
            wsi: "on"
            attachment: "on"
            format: "on"
      relaxations:
          common:
            allow_url:
              urls:
                  - "^[^?]+[.](html?|shtml|js|gif|jpg|jpeg|png|swf|pif|pdf|css|csv)$"
                  - "^[^?]+[.](cgi|aspx?|jsp|php|pl)([?].*)?$"
  
  sh-5.1$ kubectl apply -f policies/waf_basic.yaml
  waf.citrix.com/wafbasic created
  ```
  - Lets login to our CPX again and check that our WAF policy has been configured
  ```shell
  sh-5.1$ kubectl get pods | grep cpx
  sml1-cpx-759984bd99-hgvh8      2/2     Running   0          106m
  sml2-cpx-54659dcc79-8gsjw      2/2     Running   0          106m
  sml3-cpx-bbc958ddc-v9mt5       2/2     Running   0          106m
  sh-5.1$ kubectl exec -it sml1-cpx-759984bd99-hgvh8 bash
  root@sml1-cpx-759984bd99-hgvh8:/# nscli -U :nsroot:$(cat /var/random_id)
  root@sml1-cpx-759984bd99-hgvh8:/# sh appfw policy
  1)	Name: cpx_import_bypadd
	Hits: 0
	Undef Hits: 0
	Active: Yes

  2)	Name: k8s_crd_waf_wafbasicdefault
    Hits: 0
    Undef Hits: 0
    Active: Yes
  ```
  - Lets now send an HTTP request to our front-end microservice by passing some **NON malicious request parameter id=12345**
  ```shell
  curl --cert certs/myCert --key certs/myKey https://sockshop.citrix\?id\=12345 -kv | head -n 10
  > Host: sockshop.citrix
  > User-Agent: curl/7.77.0
  > Accept: */*
  >
  * Mark bundle as not supporting multiuse
  < HTTP/1.1 200 OK
  ```
  - Lets now send again an **HTTP Malicious request** (SQL Injection attack) to our front-end microservice by passing an SQL statement in our request parameter id=12358%3B%20DROP%20TABLE%20users (12358; DROP TABLE users). **As we can see in the response our WAF is not blocking the request**.
  ```shell
  sh-5.1$ noglob curl --cert certs/myCert --key certs/myKey https://sockshop.citrix\?id\=12358%3B%20DROP%20TABLE%20users -kv | head -n 10
  > Host: sockshop.citrix
  > User-Agent: curl/7.77.0
  > Accept: */*
  >
  * Mark bundle as not supporting multiuse
  * HTTP 1.0, assume close after body
  < HTTP/1.0 302 Object Moved
  < Pragma: no-cache
  < Location: /
  < Connection: close
  ```

  - Check again CPX and see **App Firewall Policy hits increasing**  
  ```shell
  sh-5.1$ kubectl get pods | grep cpx
  sml1-cpx-759984bd99-hgvh8      2/2     Running   0          106m
  sml2-cpx-54659dcc79-8gsjw      2/2     Running   0          106m
  sml3-cpx-bbc958ddc-v9mt5       2/2     Running   0          106m
  sh-5.1$ kubectl exec -it sml1-cpx-759984bd99-hgvh8 bash
  root@sml1-cpx-759984bd99-hgvh8:/# nscli -U :nsroot:$(cat /var/random_id)
  root@sml1-cpx-759984bd99-hgvh8:/# sh appfw policy
  1)	Name: cpx_import_bypadd
	Hits: 0
	Undef Hits: 0
	Active: Yes

  2)	Name: k8s_crd_waf_wafbasicdefault
    Hits: 0
    Undef Hits: 2
    Active: Yes
  ```

  ### Rate-limiting using CPX
  In This use case we will see how to configure our CPX to apply a rate limiting policy to protect our front-end micro-service. For this use case we have created a simple policy that does not allow more than 2 requests to our front-end microservice within the period of 60 seconds.

  - Lets first check the Rate-limiting policy we prepared and apply. We will protect front-end microservice and we will test that by sending a specific number of requests.
  ```shell 
  sh-5.1$ cat policies/ratelimit.yaml
  apiVersion: citrix.com/v1beta1
  kind: ratelimit
  metadata:
    name: ratelimit
  spec:
    servicenames:
      - front-end-headless
    selector_keys:
    basic:
      per_client_ip: true
    req_threshold: 2
    timeslice: 60000
    throttle_action: "RESPOND"
  
  sh-5.1$ kubectl apply -f policies/ratelimit.yaml
  ratelimit.citrix.com/ratelimit created
  ```
  - Lets send 3 HTTP requests and see the response. We will see that we get an **HTTP 429 Too Many Requests** 
  ```shell
  sh-5.1$ curl --cert certs/myCert --key certs/myKey https://sockshop.citrix -kv | head -n 10
  > GET / HTTP/1.1
  > Host: sockshop.citrix
  > User-Agent: curl/7.77.0
  > Accept: */*
  >
  * Mark bundle as not supporting multiuse
  < HTTP/1.1 429 Too Many Requests
  < Retry-After: 60.0
  ```

  - Lets check CPX and see **Rate Limiting Policy hits increasing**  
  ```shell
  sh-5.1$ kubectl get pods | grep cpx
  sml1-cpx-759984bd99-hgvh8      2/2     Running   0          106m
  sml2-cpx-54659dcc79-8gsjw      2/2     Running   0          106m
  sml3-cpx-bbc958ddc-v9mt5       2/2     Running   0          106m
  sh-5.1$ kubectl exec -it sml1-cpx-759984bd99-hgvh8 bash
  root@sml1-cpx-759984bd99-hgvh8:/# nscli -U :nsroot:$(cat /var/random_id)
  root@sml1-cpx-759984bd99-hgvh8:/# sh responder policy | grep ratelimit
  7)	Name: k8s_crd_ratelimit_default_ratelimit
	root@sml1-cpx-759984bd99-hgvh8:/# sh responder policy | grep ratelimit
  stat responder policy k8s_crd_ratelimit_default_ratelimit

  Responder Policy Statistics
  Name           Hits Rate(/s) UndefHits Rate(/s)
  k8s_...limit       1        0        0        0
  ```

  ### Rewrite Policies using CPX
  In This use case we will see how to configure our CPX to manipulate a request by adding some typical hardening headers. We will add these headers in the RESPONSE so that it is easier for us to check if these has been added. Adding these in the REQUEST is as simple as changing a value in our policy definition from RESPONSE to REQUEST
  
  We will again add these policies to the traffic going to our front-end micro-service. For our use case we will add the following headers, using one policy per header:
    1. Content-Security-Policy
    2. max-age=86400
    3. Referrer-Policy
    4. Cache-Control
    5. X-Forwarded-For

  - Lets first check the manifest file containing all our RESPONDER policies and apply. 
  ```shell 
  sh-5.1$ cat policies/rewrite_multi_hdr.yaml
  apiVersion: citrix.com/v1
  kind: rewritepolicy
  metadata:
    name: multipolicy
  spec:
    rewrite-policies:
      - servicenames:
          - front-end-headless
        goto-priority-expression: NEXT
        rewrite-policy:
          operation: insert_http_header
          target: 'Content-Security-Policy'
          modify-expression: "\"default-src 'self'\""
          comment: 'insert Content-Security-Policy in header'
          direction: RESPONSE
          rewrite-criteria: 'http.req.is_valid'
  
  sh-5.1$ kubectl apply -f policies/rewrite_multi_hdr.yaml
  rewritepolicy.citrix.com/multipolicy created
  ```

  - Lets send an HTTP requests and see the response. We will see that **the headers have been added** 
  ```shell
  sh-5.1$ curl --cert certs/myCert --key certs/myKey https://sockshop.citrix -kv | head -n 10
  * Mark bundle as not supporting multiuse
  < HTTP/1.1 200 OK
  < X-Powered-By: Express
  < Accept-Ranges: bytes
  < Cache-Control: public, max-age=0
  < Last-Modified: Tue, 21 Mar 2017 11:31:47 GMT
  < ETag: W/"21f0-15af0a320b8"
  < Content-Type: text/html; charset=UTF-8
  < Content-Length: 8688
  < Date: Tue, 12 Jul 2022 13:22:31 GMT
  < Connection: keep-alive
  < Content-Security-Policy: default-src 'self'
  < Expect-CT: max-age=86400, enforce, report-uri="https://example.com/report"
  < Referrer-Policy: origin-when-cross-origin
  < Cache-Control: no-store
  < X-Forwarded-For: 10.162.15.237
  ```

  - Lets check CPX and see **Rewrite Policies hits increasing**  
  ```shell
  sh-5.1$ kubectl get pods | grep cpx
  sml1-cpx-759984bd99-hgvh8      2/2     Running   0          106m
  sml2-cpx-54659dcc79-8gsjw      2/2     Running   0          106m
  sml3-cpx-bbc958ddc-v9mt5       2/2     Running   0          106m
  sh-5.1$ kubectl exec -it sml1-cpx-759984bd99-hgvh8 bash
  root@sml1-cpx-759984bd99-hgvh8:/# nscli -U :nsroot:$(cat /var/random_id)
  > sh rewrite policy
  1)	Name: k8s_crd_rewritepolicy_rwpolicy_multipolicy_0_default
    Hits: 1
    Undef Hits: 0
    Active: Yes
    Comment: "insert Content-Security-Policy in header"

  2)	Name: k8s_crd_rewritepolicy_rwpolicy_multipolicy_1_default
    Hits: 1
    Undef Hits: 0
    Active: Yes
    Comment: "insert Expect-CT in header"

  3)	Name: k8s_crd_rewritepolicy_rwpolicy_multipolicy_2_default
    Hits: 1
    Undef Hits: 0
    Active: Yes
    Comment: "insert Referrer-Policy in header"

  4)	Name: k8s_crd_rewritepolicy_rwpolicy_multipolicy_3_default
    Hits: 1
    Undef Hits: 0
    Active: Yes
    Comment: "insert Cache-Control in header"

  5)	Name: k8s_crd_rewritepolicy_rwpolicy_multipolicy_4_default
    Hits: 1
    Undef Hits: 0
    Active: Yes
    Comment: "HTTP Initial X-Forwarded-For header insertion"
  ```