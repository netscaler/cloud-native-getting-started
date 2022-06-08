# Developer Persona

## The Setup  
![](assets/persona-developer-overview.png)

The diagram above illustrates the environment at a high-level. There is an Anthos GKE cluster in which I will deploy my APIs, with an external Citrix VPX to control ingress traffic into the cluster with support for Web Application Firewall (WAF) protection. This Citrix VPX appliance is managed by external teams and adheres to corporate application delivery standards, but allows me to specify my own WAF configurations.   

As a second Tier of protection we have an internal Containerized Citrix CPX that controls ingress traffic into a specific namespace where I deploy the applications I am working on. CPX acts as an ingress API Gateway and is managed by me and my team. Authentication / Authorization, Rate limiting and more for my APIs are offloaded to CPX.

As a developer, I am responsible for deploying applications to a Google Anthos platform and ensuring that my application is available and complies to my corporate deployment standards. Tier-1 and Tier-2 ingress into my application needs to permit and protect access to the application.

## The Why  

Deploying applications into a Citrix Integrated Google Anthos Platform allows me, the developer, to set specific network configurations as simple annotations within my kubernetes manifests. In addition, I can offload common functionalities required by my applications on the API Gateway. By using simple kubernetes CRDs I can configure Authentication / Authorization, Rate limiting and more to protect my APIs. I don't need to learn an additional platform or tool, and this configuration will be applied in accordance with any constraints set out by the platform, network, and security teams. This allows my application to get to market faster with less internal meetings, approvals, or change requests.  

My platform and security teams have requested that I protect my application using Citrix WAF capabilities and API Gateway policies, but as the developer, I am responsible for ensuring that all configurations are appropriate for my APIs. Luckily Citrix provides Kubernetes Custom Resources that I can use to define the right policies without needing to engage with other teams, and still be compliant with my platform and security teams requirements. 


## The How  

---
**NOTE**
In this demonstration, the kubectl binary and local files are used to deploy the application. In production scenarios, other deployment methods would likely be in place, such as a GitOps approach as provided from Google Anthos Configuration Management.  

**Important**
Please note that ADC VPX security features require ADC to be licensed. After ADC VPX is in place, please make sure to follow the steps required to apply your license in one of the various ways that are supported. For simplicity, for this demonstration we are [Using a standalone Citrix ADC VPX license](lab-automation/Licensing.md). For production deployment scenarios you are encouraged to apply different licensing schemes.
- [Licensing overview](https://docs.citrix.com/en-us/citrix-adc/current-release/licensing.html)
- [Citrix ADC pooled capacity](https://docs.citrix.com/en-us/citrix-application-delivery-management-software/current-release/license-server/adc-pooled-capacity.html)

---

First I will deploy the echoserver sample application manifests. As a second step I will deploy the cpx ingress object responsible for configuring my Tier-2 ADC CPX. CPX will act as the API Gateway for my namespace and will route traffic to my APIs. Finally I will deploy the vpx ingress object responsible for configuring my Tier-1 ADC VPX. VPX will be responsible for routing the traffic inside my kubernetes cluster to my ADC CPX. After we establish the basic configuration we will start testing some policies both on VPX and CPX.

## Deploy App and Ingress objects

- Deploy the application and the cpx ingress object ... first clone the git repository that the automation created, then deploy the application **Note that you will need to replace the <github-org> and <repo> tags according to your deployment of this lab** 
  ```shell
  sh-5.1$ git clone git@github.com:<github-org>/<repo>.git
  Cloning into '<repo>'...
  remote: Enumerating objects: 301, done.
  remote: Counting objects: 100% (301/301), done.
  remote: Compressing objects: 100% (283/283), done.
  remote: Total 301 (delta 102), reused 0 (delta 0), pack-reused 0
  Receiving objects: 100% (301/301), 33.28 KiB | 2.38 MiB/s, done.
  Resolving deltas: 100% (102/102), done.
  sh-5.1$ cd <repo>/demoapp/echoserver/
  sh-5.1$ kubectl apply -f echoserver -n demoapp
  sh-5.1$ kubectl get pods,services -n demoapp -o wide 
  NAME                               READY   STATUS    RESTARTS   AGE   IP          NODE                                              NOMINATED NODE   READINESS GATES
  pod/cpx-ingress-65fb478bb5-thxth   2/2     Running   0          17h   10.0.0.12   gke-ctx-lab-cluster-ctx-lab-nodes-6d105a70-vxmd   <none>           <none>
  pod/echoserver-6944fb9c86-zh4h8    1/1     Running   0          15h   10.0.0.14   gke-ctx-lab-cluster-ctx-lab-nodes-6d105a70-vxmd   <none>           <none>

  NAME                   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE   SELECTOR
  service/cpx-service    ClusterIP   10.3.251.190   <none>        80/TCP,443/TCP   17h   app=cpx-ingress
  service/pet-service    ClusterIP   10.3.253.209   <none>        7030/TCP         15h   app=echoserver
  service/play-service   ClusterIP   10.3.252.192   <none>        7050/TCP         15h   app=echoserver
  service/user-service   ClusterIP   10.3.250.168   <none>        7040/TCP         15h   app=echoserver
  
  sh-5.1$ cd ../
  sh-5.1$ cat cpx-ingress.yaml 
  # #Specify the ingress resource
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: vpx-ingress
    annotations:
    kubernetes.io/ingress.class: "tier-2-cpx"
    ingress.citrix.com/insecure-termination: "allow"
  spec:
    rules:
    - host: pet-service.echoserver.com
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: pet-service
              port:
                number: 7030
    - host: user-service.echoserver.com
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: user-service
              port:
                number: 7040
    - host: play-service.echoserver.com
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: play-service
              port:
                number: 7050
  
  sh-5.1$ kubectl apply -f cpx-ingress.yaml -n demoapp
  ingress.networking.k8s.io/cpx-ingress created
  ```
  You can check the lbvservers created on CPX as bellow:
  ```shell
  $ kubectl exec -it cpx-ingress-65fb478bb5-thxth -n demoapp bash
  root@cpx-ingress-65fb478bb5-thxth:/# cli_script.sh "sh lb vserver" | grep k8s
  4)	k8s-pet-service_7030_lbv_cfzb2mubztudgxlsbsvhnoqrfl3vccul (0.0.0.0:0) - HTTP	Type: ADDRESS
  5)	k8s-user-service_7040_lbv_cfzb2mubztudgxlsbsvhnoqrfl3vccul (0.0.0.0:0) - HTTP	Type: ADDRESS
  6)	k8s-play-service_7050_lbv_cfzb2mubztudgxlsbsvhnoqrfl3vccul (0.0.0.0:0) - HTTP	Type: ADDRESS
  ```
- Deploy the vpx ingress object and check VPX to see dynamic configuration.
  ```shell
  sh-5.1$ cat vpx-ingress.yaml
  # #Specify the ingress resource
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: vpx-ingress
    annotations:
    kubernetes.io/ingress.class: "tier-1-vpx"
    ingress.citrix.com/insecure-termination: "allow"
  spec:
    rules:
    - host: pet-service.echoserver.com
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: cpx-service
              port:
                number: 80
    - host: user-service.echoserver.com
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: cpx-service
              port:
                number: 80
    - host: play-service.echoserver.com
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: cpx-service
              port:
                number: 80

  sh-5.1$ kubectl apply -f vpx-ingress.yaml -n demoapp 
  ingress.networking.k8s.io/vpx-ingress created
  ```
  ![](assets/1.ADC-LBVServer-k8s-cpx-service.png) 
- Send a simple request to pet-service.echoserver.com and check the response. If you followed the prerequisites steps, that should be configured either on your hosts file or your DNS and resolve to ADC VIP. We will use curl to send the request and format the response with jq for better clarity:
  ```shell
  curl pet-service.echoserver.com | jq
  *   Trying 34.95.21.135:80...
  * Connected to pet-service.echoserver.com (34.95.21.135) port 80 (#0)
  > GET / HTTP/1.1
  > Host: pet-service.echoserver.com
  > User-Agent: curl/7.77.0
  > Accept: */*
  >
  * Mark bundle as not supporting multiuse
  < HTTP/1.1 200 OK
  < Content-Type: application/json; charset=utf-8
  < Content-Length: 2295
  < ETag: W/"8f7-UgZoA6qielFagpCDfeAPz7+E9fE"
  < Date: Wed, 08 Jun 2022 13:46:26 GMT
  < Connection: keep-alive
  < Keep-Alive: timeout=5
  <
  * Connection #0 to host pet-service.echoserver.com left intact
  {
    "host": {
      "hostname": "pet-service.echoserver.com",
      "ip": "::ffff:10.0.0.12",
      "ips": []
    },
    "http": {
      "method": "GET",
      "baseUrl": "",
      "originalUrl": "/",
      "protocol": "http"
    },
    "request": {
      "params": {
        "0": "/"
      },
      "query": {},
      "cookies": {},
      "body": {},
      "headers": {
        "host": "pet-service.echoserver.com",
        "user-agent": "curl/7.77.0",
        "accept": "*/*"
      }
    },
    "environment": {
      "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
      "HOSTNAME": "echoserver-6944fb9c86-zh4h8",
      "NODE_VERSION": "16.15.0",
      "YARN_VERSION": "1.22.18",
      "PORT": "80",
      "PET_SERVICE_PORT_7030_TCP": "tcp://10.3.253.209:7030",
      "PET_SERVICE_PORT_7030_TCP_PORT": "7030",
      "USER_SERVICE_PORT_7040_TCP_PROTO": "tcp",
      "USER_SERVICE_PORT_7040_TCP_ADDR": "10.3.250.168",
      "CPX_SERVICE_SERVICE_PORT_HTTPS": "443",
      "CPX_SERVICE_SERVICE_PORT_HTTP": "80",
      "PET_SERVICE_SERVICE_HOST": "10.3.253.209",
      "PET_SERVICE_SERVICE_PORT": "7030",
      "PET_SERVICE_PORT_7030_TCP_PROTO": "tcp",
      "USER_SERVICE_SERVICE_HOST": "10.3.250.168",
      "USER_SERVICE_SERVICE_PORT": "7040",
      "PLAY_SERVICE_PORT_7050_TCP_PROTO": "tcp",
      "KUBERNETES_PORT_443_TCP_PROTO": "tcp",
      "PLAY_SERVICE_PORT_7050_TCP_ADDR": "10.3.252.192",
      "CPX_SERVICE_SERVICE_HOST": "10.3.251.190",
      "CPX_SERVICE_SERVICE_PORT": "80",
      "CPX_SERVICE_PORT_80_TCP_PORT": "80",
      "CPX_SERVICE_PORT_80_TCP_ADDR": "10.3.251.190",
      "CPX_SERVICE_PORT_443_TCP": "tcp://10.3.251.190:443",
      "CPX_SERVICE_PORT_443_TCP_PORT": "443",
      "PET_SERVICE_PORT": "tcp://10.3.253.209:7030",
      "KUBERNETES_PORT_443_TCP": "tcp://10.3.240.1:443",
      "PLAY_SERVICE_PORT_7050_TCP": "tcp://10.3.252.192:7050",
      "CPX_SERVICE_PORT_80_TCP": "tcp://10.3.251.190:80",
      "CPX_SERVICE_PORT_80_TCP_PROTO": "tcp",
      "PET_SERVICE_PORT_7030_TCP_ADDR": "10.3.253.209",
      "USER_SERVICE_PORT": "tcp://10.3.250.168:7040",
      "CPX_SERVICE_PORT": "tcp://10.3.251.190:80",
      "CPX_SERVICE_PORT_443_TCP_PROTO": "tcp",
      "PLAY_SERVICE_SERVICE_HOST": "10.3.252.192",
      "PLAY_SERVICE_SERVICE_PORT": "7050",
      "PLAY_SERVICE_PORT": "tcp://10.3.252.192:7050",
      "KUBERNETES_PORT_443_TCP_PORT": "443",
      "KUBERNETES_SERVICE_PORT_HTTPS": "443",
      "USER_SERVICE_PORT_7040_TCP_PORT": "7040",
      "KUBERNETES_SERVICE_HOST": "10.3.240.1",
      "KUBERNETES_PORT": "tcp://10.3.240.1:443",
      "KUBERNETES_PORT_443_TCP_ADDR": "10.3.240.1",
      "KUBERNETES_SERVICE_PORT": "443",
      "USER_SERVICE_PORT_7040_TCP": "tcp://10.3.250.168:7040",
      "PLAY_SERVICE_PORT_7050_TCP_PORT": "7050",
      "CPX_SERVICE_PORT_443_TCP_ADDR": "10.3.251.190",
      "HOME": "/root"
    }
  }
  ```
## Deploy WAF Policy and block a Malicious Request

- Enable a WAF policy to block SQL Injection attacks on VPX.
  ```shell
  $ cat apigw_policies/wafbasic.yaml
  apiVersion: citrix.com/v1
  kind: waf
  metadata:
      name: wafbasic
  spec:
      servicenames:
          - cpx-service
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
  $ kubectl apply -f apigw_policies/wafbasic.yaml -n demoapp
  $ waf.citrix.com/wafbasic created
  ```
- Send first a typical GET request and then a malicious one and see if it gets blocked.
  ```shell
  $ noglob curl -v pet-service.echoserver.com?id=12358
  *   Trying 34.95.21.135:80...
  * Connected to pet-service.echoserver.com (34.95.21.135) port 80 (#0)
  > GET /?id=12358 HTTP/1.1
  > Host: pet-service.echoserver.com
  > User-Agent: curl/7.77.0
  > Accept: */*
  >
  * Mark bundle as not supporting multiuse
  < HTTP/1.1 200 OK
  < Content-Type: application/json; charset=utf-8
  < Content-Length: 2316
  < ETag: W/"90c-c5PIHNGh4Es7VSKQAOzGx3fMTkc"
  < Date: Wed, 08 Jun 2022 13:45:29 GMT
  < Connection: keep-alive
  < Keep-Alive: timeout=5
  <
  * Connection #0 to host pet-service.echoserver.com left intact
  {
    "host": {
      "hostname": "pet-service.echoserver.com",
      "ip": "::ffff:10.0.0.12",
      "ips": []
    },
    "http": {
      "method": "GET",
      "baseUrl": "",
      "originalUrl": "/?id=12358",
      "protocol": "http"
    },
    "request": {
      "params": {
        "0": "/"
      },
      "query": {
        "id": "12358"
      },
      ...
    }
  }
  $ noglob curl -v pet-service.echoserver.com?id=12358%3B%20DROP%20TABLE%20users (id=12358; DROP TABLE users)
  *   Trying 34.95.21.135:80...
  * Connected to pet-service.echoserver.com (34.95.21.135) port 80 (#0)
  > GET /?id=12358%3B%20DROP%20TABLE%20users HTTP/1.1
  > Host: pet-service.echoserver.com
  > User-Agent: curl/7.77.0
  > Accept: */*
  >
  * Mark bundle as not supporting multiuse
  * HTTP 1.0, assume close after body
  < HTTP/1.0 302 Object Moved
  < Pragma: no-cache
  < Location: /
  < Connection: close
  <
  * Closing connection 0
  ```

## Enable Rate limiting on ADC CPX API Gateway
- We will now focus on applying some policies on our namespaced API Gateway. These policies will be applied only for our pet-service. We will first apply a simple rate limiting policy only to the /pet path and test it.
```shell
  $ cat apigw_policies/ratelimit.yaml
  apiVersion: citrix.com/v1beta1
  kind: ratelimit
  metadata:
    name: ratelimit
  spec:
    servicenames:
    - pet-service
    selector_keys:
    basic:
      path:
      - /ratelimit
      per_client_ip: true
    req_threshold: 7
    timeslice: 79000
    throttle_action: "RESPOND"

  $ kubectl apply -f apigw_policies/ratelimit.yaml -n demoapp
  $ ratelimit.citrix.com/ratelimit created
  ```
- Send some request to /ratelimit path and check how it blocks the request after the threshold has been reached.
  ```shell
  $ noglob curl -v pet-service.echoserver.com/ratelimit.aspx?id=12345
  *   Trying 34.95.21.135:80...
  * Connected to pet-service.echoserver.com (34.95.21.135) port 80 (#0)
  > GET /ratelimit.aspx?id=12345 HTTP/1.1
  > Host: pet-service.echoserver.com
  > User-Agent: curl/7.77.0
  > Accept: */*
  >
  * Mark bundle as not supporting multiuse
  < HTTP/1.1 429 Too Many Requests
  < Retry-After: 79.0
  * no chunk, no close, no size. Assume close to signal end
  <
  * Closing connection 0
  ```
- Send a request to /pet path and validate that it's not getting blocked
  ```shell
  $ noglob curl -v pet-service.echoserver.com/pet.aspx?id=12345
  *   Trying 34.95.21.135:80...
  * Connected to pet-service.echoserver.com (34.95.21.135) port 80 (#0)
  > GET /pet.aspx?id=12345 HTTP/1.1
  > Host: pet-service.echoserver.com
  > User-Agent: curl/7.77.0
  > Accept: */*
  >
  * Mark bundle as not supporting multiuse
  < HTTP/1.1 200 OK
  < Content-Type: application/json; charset=utf-8
  < Content-Length: 2334
  < ETag: W/"91e-R0a87D5ZxjCXKzn2PLuyvkmJykk"
  < Date: Wed, 08 Jun 2022 13:54:48 GMT
  < Connection: keep-alive
  < Keep-Alive: timeout=5
  <
  * Connection #0 to host pet-service.echoserver.com left intact
  ```
## Add X-Forwarded-For header by applying a rewrite policy on ADC CPX API Gateway
- Apply the policy and then send a request to see the header that has been added
  ```shell
  $ cat apigw_policies/rewrite-headers.yaml
    apiVersion: citrix.com/v1
    kind: rewritepolicy
    metadata:
      name: httpxforwardedforaddition
    spec:
      rewrite-policies:
        - servicenames:
            - pet-service
          rewrite-policy:
            operation: insert_http_header
            target: X-Forwarded-For
            modify-expression: client.ip.src
            comment: 'HTTP Initial X-Forwarded-For header add'
            direction: REQUEST
            rewrite-criteria: 'HTTP.REQ.HEADER("X-Forwarded-For").EXISTS.NOT'

        - servicenames:
            - pet-service
          rewrite-policy:
            operation: replace
            target: HTTP.REQ.HEADER("X-Forwarded-For")
            modify-expression: 'HTTP.REQ.HEADER("X-Forwarded-For").APPEND(",").APPEND(CLIENT.IP.SRC)'
            comment: 'HTTP Append X-Forwarded-For IPs'
            direction: REQUEST
            rewrite-criteria: 'HTTP.REQ.HEADER("X-Forwarded-For").EXISTS'

    $ kubectl apply -f apigw_policies/rewrite-headers.yaml -n demoapp
    $ rewritepolicy.citrix.com/httpxforwardedforaddition created

    $ noglob curl -v pet-service.echoserver.com/pet.aspx?id=12345 | jq | grep headers -A 10
    * Connected to pet-service.echoserver.com (34.95.21.135) port 80 (#0)
    > GET /pet.aspx?id=12345 HTTP/1.1
    > Host: pet-service.echoserver.com
    > User-Agent: curl/7.77.0
    > Accept: */*
    >
    * Mark bundle as not supporting multiuse
    < HTTP/1.1 200 OK
    < Content-Type: application/json; charset=utf-8
    < Content-Length: 2364
    < ETag: W/"93c-QcKxNKKWo+hzUG+fFX+cu4G8mzA"
    < Date: Wed, 08 Jun 2022 15:08:40 GMT
    < Connection: keep-alive
    < Keep-Alive: timeout=5
    <
    { [2364 bytes data]
    100  2364  100  2364    0     0   4926      0 --:--:-- --:--:-- --:--:--  5040
    * Connection #0 to host pet-service.echoserver.com left intact
        "headers": {
          "host": "pet-service.echoserver.com",
          "user-agent": "curl/7.77.0",
          "accept": "*/*",
          "x-forwarded-for": "10.162.0.30"
        }
      },
      ...
    ```
- 
---

Network and security teams can view my configuration from the Citrix ADC including:

- Citrix WAF Policies 
  ![](assets/waf_basic_policy.png)
- Citrix WAF Profiles
  ![](assets/waf_profiles.png)
- Citrix WAF Policy Bindings to Virtual Load Balancing Server 
  ![](assets/waf_basic_policy_binding.png)  
- Citrix WAF Policy Binding Details
  ![](assets/waf_basic_policy_binding_details.png)



To see more configuration options, review the [waf crd examples](https://developer-docs.citrix.com/projects/citrix-k8s-ingress-controller/en/latest/crds/waf/) documentation. 



## Summary  

As a developer, my primary concern is to quickly and securely release my cloud-native application with the pace of my development team and without delays from external teams. Using the Citrix Ingress Controller  and WAF CRDs in a Google Anthos platform allows my team to achieve this goal. 
- Network, Security, and Platform teams can configure sensible defaults and constraints automatically without needing my involvement
- Configurable items specific to my application, **including WAF security**, are delegated to my team in a self-service manner
- Visibility of my workloads are present in the northbound network infrastructure to provide better monitoring and alerting across teams
- I can collaborate in network and security troubleshooting with my network engineers with a shared context and understanding of my workloads

