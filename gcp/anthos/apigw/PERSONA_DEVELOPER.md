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
In this demonstration, the kubectl binary and local files are used to deploy the application and configure all API Gateway policies. In production scenarios, other deployment methods would likely be in place, such as a GitOps approach as provided from Google Anthos Configuration Management. In that case all these configurations would be stored in Git and automatically synced in GKE. 

For the purpose of this demonstration zsh has been used. Please skip commands (noglob, etc.) not relevant to your bash. Also jq has been used for properly format of responses. Please skip also this or install on your system.

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
  $ kubectl exec -it cpx-ingress-65fb478bb5-4v6wn -n demoapp bash
  root@cpx-ingress-65fb478bb5-4v6wn:/# cli_script.sh "sh lb vserver" | grep k8s
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
  $ noglob curl -v -X GET pet-service.echoserver.com/pet.aspx?id=12345 | jq
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

- Enable a WAF policy and see how it blocks an SQL Injection attacks on VPX.
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
  $ noglob curl -v pet-service.echoserver.com/pet.aspx?id=12345
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
  $ noglob curl -v pet-service.echoserver.com/pet.aspx?id=12358%3B%20DROP%20TABLE%20users (id=12358; DROP TABLE users)
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
- We will now focus on applying some policies on our namespaced API Gateway. These policies will be applied only for our pet-service. We will first apply a simple rate limiting policy only to the /ratelimit.aspx path and test it.
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
      - /ratelimit.aspx
      per_client_ip: true
    req_threshold: 7
    timeslice: 79000
    throttle_action: "RESPOND"

  $ kubectl apply -f apigw_policies/ratelimit.yaml -n demoapp
  $ ratelimit.citrix.com/ratelimit created
  ```
- Send more than 7 requests to /ratelimit.aspx and check how it blocks the request after the threshold has been reached.
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
- Send a request to /pet.aspx path and validate that it's not getting blocked
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
- Apply the policy and then send a request to see the X-Forwarded-For header added
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
## Add Authentication and Authorization to our API by applying an Authentication Policy on ADC CPX API Gateway

On this last scenario we will leverage Keycloak as our OpenIDConnect Provider and OAuth 2.0 server. We created a realm: myrealm and a client: myclient and we have assigned 3 client optional scopes to myclient: resource:view, resource:create and resource:update. After following all the steps described in this lab acm should have deployed keycloak in keycloak namespace. Visit Keycloak admin console and create a new real *myrealm* and import *realm-export-myrealm.json* that can be found under *demoapp/keycloak/realm-export-myrealm.json*. All the authN / authZ presented from now on will be in place for you. 

For simplicity we will follow the client_credential OAuth 2.0 flow. As the names of scopes indicate, we will use these scopes to allow access to our client to sent GET, POST and PUT requests to the /pet.aspx resource. 

Our API Gateway CPX is responsible to check whether the Bearer access token presented in the Authorization Header contains the required scope to allow access to resource or return an HTTP Error 401 Unauthorized Access. We also configured our policy to skip both authentication an authorization for a specific resource: /pet-unauth.aspx.

- Let's first see and apply our policy.
```shell
$ cat apigw_policies/oauth_jwt_auth.yaml
apiVersion: citrix.com/v1beta1
kind: authpolicy
metadata:
  name: authexample
spec:
    servicenames:
    - pet-service

    authentication_providers:
      - name: "jwt-auth-provider"
        oauth:
          issuer: "http://34.95.5.194:8080/realms/myrealm"
          jwks_uri: "http://34.95.5.194:8080/realms/myrealm/protocol/openid-connect/certs"
          claims_to_save : ["scope"]

    authentication_policies:
        - resource:
            path:
              - '/pet.aspx'
            method: [GET, POST]
          provider: ["jwt-auth-provider"]

        # skip authentication for this
        - resource:
            path:
              - '/pet-unauth.aspx'
              - '/ratelimit.aspx'
            method: [GET]
          provider: []

    authorization_policies:
        # skip authorization, no claims required
        - resource:
            path:
              - '/pet-unauth.aspx'
              - '/ratelimit.aspx'
            method: [GET]
            claims: []
        - resource:
            path:
              - '/pet.aspx'
            method: [GET]
            claims:
            - name: "scope"
              values: ["resource:view"]
        - resource:
            path:
              - '/pet.aspx'
            method: [POST]
            claims:
            - name: "scope"
              values: ["resource:create"]
$ kubectl apply -f apigw_policies/oauth_jwt_auth.yaml -n demoapp
$ authpolicy.citrix.com/authexample created
```
- Let's send a request first to the resource that is not protected.
```shell
$ noglob curl -v pet-service.echoserver.com/pet-unauth.aspx?id=12345 | jq
* Connected to pet-service.echoserver.com (34.95.21.135) port 80 (#0)
> GET /pet-unauth.aspx?id=12345 HTTP/1.1
> Host: pet-service.echoserver.com
> User-Agent: curl/7.77.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Content-Type: application/json; charset=utf-8
< Content-Length: 2378
< ETag: W/"94a-55BELHOXAdMKE1XNoGYd7D22708"
< Date: Sat, 11 Jun 2022 20:56:27 GMT
< Connection: keep-alive
< Keep-Alive: timeout=5
<
{ [2378 bytes data]
100  2378  100  2378    0     0   5942      0 --:--:-- --:--:-- --:--:--  6113
* Connection #0 to host pet-service.echoserver.com left intact
{
  ...
$ 
```
- Let's now send a GET request to our protected resource /pet.aspx
```shell
$ noglob curl -v pet-service.echoserver.com/pet.aspx?id=12345
* Connected to pet-service.echoserver.com (34.95.21.135) port 80 (#0)
> GET /pet.aspx?id=12345 HTTP/1.1
> Host: pet-service.echoserver.com
> User-Agent: curl/7.77.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 401 Unauthorized
< WWW-Authenticate: Bearer
< Content-Length: 13
< Content-Type: text/html; charset=utf-8
< Cache-Control: no-cache,no-store,must-revalidate
< X-Frame-Options: SAMEORIGIN
< X-Content-Type-Options: nosniff
< X-XSS-Protection: 1
< Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; connect-src 'self'; img-src 'self' data: http:; style-src 'self' 'unsafe-inline'; font-src 'self'; frame-src 'self' vmware-view:; child-src 'self'
< Pragma: no-cache
<
* Connection #0 to host pet-service.echoserver.com left intact
Unauthorized.
```
- As we saw in the last request we get a 401 Unauthorized Error. Let's now request an access token from keycloak using our client credentials and send a request again also passing the access token. Note that we are also specifically asking for a token that will also include the resource:view and resource:update scopes.
```shell
$ curl --location --request POST 'http://34.95.5.194:8080/realms/myrealm/protocol/openid-connect/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--header 'Authorization: Basic bXljbGllbnQ6MU5NUGl2U09YUm5ETVl5WmNzdmNxSEhKb0NSNFRYR3Y=' \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode 'scope=resource:view resource:update'
{"access_token":"eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJaV0FHYlEydnotVHNSdjRLSUMtUm1Kd0hIZ3VBeExnU2pSR05QN0pNR0dJIn0.eyJleHAiOjE2NjMyMjYwOTYsImlhdCI6MTY2MzIyNTc5NiwianRpIjoiNjAwMmJjM2QtMTVjYy00ZGE0LTk3NzQtMjk2MDFjMjRhMjBlIiwiaXNzIjoiaHR0cDovLzM0Ljk1LjUuMTk0OjgwODAvcmVhbG1zL215cmVhbG0iLCJhdWQiOiJhY2NvdW50Iiwic3ViIjoiZjRmZjQ0YmEtZTZiZi00NGM3LThlZDgtYjc5NjQ2YzMxZTA1IiwidHlwIjoiQmVhcmVyIiwiYXpwIjoibXljbGllbnQiLCJhY3IiOiIxIiwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbImRlZmF1bHQtcm9sZXMtbXlyZWFsbSIsIm9mZmxpbmVfYWNjZXNzIiwidW1hX2F1dGhvcml6YXRpb24iXX0sInJlc291cmNlX2FjY2VzcyI6eyJteWNsaWVudCI6eyJyb2xlcyI6WyJ1bWFfcHJvdGVjdGlvbiJdfSwiYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2UtYWNjb3VudCIsIm1hbmFnZS1hY2NvdW50LWxpbmtzIiwidmlldy1wcm9maWxlIl19fSwic2NvcGUiOiJyZXNvdXJjZTp1cGRhdGUgcHJvZmlsZSBlbWFpbCByZXNvdXJjZTp2aWV3IiwiY2xpZW50SG9zdCI6IjEwLjE2Mi4xNS4yMTYiLCJjbGllbnRJZCI6Im15Y2xpZW50IiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJzZXJ2aWNlLWFjY291bnQtbXljbGllbnQiLCJjbGllbnRBZGRyZXNzIjoiMTAuMTYyLjE1LjIxNiJ9.eOoQnYEtYpcc-9f-ReQUO69x2qVHcmtYLIBk0OACVhjJH0tW_p6m3pBv-HF_vbeQTPb3Jofoqyel60L4B_vr8pyiN50du7HlriC1bMgCF9GpAmdratX-U5yVMUl-Pfps6qR4EcLb9MGE9O6Xc9_Aeoxikwqe20J84-95_j7zctcpZhryaSan87vrn_EheQ5Ss6uPpIJFzvH8_PEUGFRVeDIjr9mz42PGHw90T8sYcqKDdNQw17RR3r5a0nB1iLaiODGfmYCGX1ZJS8RE3ootSiyHw6GSLHfFXiAzU97VyfaP0cKdarWwvx0tsAAXfU7tNwDDGdR6HBcCgQWD040Jdw","expires_in":300,"refresh_expires_in":0,"token_type":"Bearer","not-before-policy":0,"scope":"resource:update profile email resource:view"}


$ noglob curl -v -X GET pet-service.echoserver.com/pet.aspx?id=12345 -H 'Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJaV0FHYlEydnotVHNSdjRLSUMtUm1Kd0hIZ3VBeExnU2pSR05QN0pNR0dJIn0.eyJleHAiOjE2NjMyMjYwOTYsImlhdCI6MTY2MzIyNTc5NiwianRpIjoiNjAwMmJjM2QtMTVjYy00ZGE0LTk3NzQtMjk2MDFjMjRhMjBlIiwiaXNzIjoiaHR0cDovLzM0Ljk1LjUuMTk0OjgwODAvcmVhbG1zL215cmVhbG0iLCJhdWQiOiJhY2NvdW50Iiwic3ViIjoiZjRmZjQ0YmEtZTZiZi00NGM3LThlZDgtYjc5NjQ2YzMxZTA1IiwidHlwIjoiQmVhcmVyIiwiYXpwIjoibXljbGllbnQiLCJhY3IiOiIxIiwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbImRlZmF1bHQtcm9sZXMtbXlyZWFsbSIsIm9mZmxpbmVfYWNjZXNzIiwidW1hX2F1dGhvcml6YXRpb24iXX0sInJlc291cmNlX2FjY2VzcyI6eyJteWNsaWVudCI6eyJyb2xlcyI6WyJ1bWFfcHJvdGVjdGlvbiJdfSwiYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2UtYWNjb3VudCIsIm1hbmFnZS1hY2NvdW50LWxpbmtzIiwidmlldy1wcm9maWxlIl19fSwic2NvcGUiOiJyZXNvdXJjZTp1cGRhdGUgcHJvZmlsZSBlbWFpbCByZXNvdXJjZTp2aWV3IiwiY2xpZW50SG9zdCI6IjEwLjE2Mi4xNS4yMTYiLCJjbGllbnRJZCI6Im15Y2xpZW50IiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJzZXJ2aWNlLWFjY291bnQtbXljbGllbnQiLCJjbGllbnRBZGRyZXNzIjoiMTAuMTYyLjE1LjIxNiJ9.eOoQnYEtYpcc-9f-ReQUO69x2qVHcmtYLIBk0OACVhjJH0tW_p6m3pBv-HF_vbeQTPb3Jofoqyel60L4B_vr8pyiN50du7HlriC1bMgCF9GpAmdratX-U5yVMUl-Pfps6qR4EcLb9MGE9O6Xc9_Aeoxikwqe20J84-95_j7zctcpZhryaSan87vrn_EheQ5Ss6uPpIJFzvH8_PEUGFRVeDIjr9mz42PGHw90T8sYcqKDdNQw17RR3r5a0nB1iLaiODGfmYCGX1ZJS8RE3ootSiyHw6GSLHfFXiAzU97VyfaP0cKdarWwvx0tsAAXfU7tNwDDGdR6HBcCgQWD040Jdw' | jq

* Connected to pet-service.echoserver.com (34.95.21.135) port 80 (#0)
> GET /pet.aspx?id=12345 HTTP/1.1
> Host: pet-service.echoserver.com
> User-Agent: curl/7.77.0
> Accept: */*
> Authorization: Bearer eeyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJaV0FHYlEydnotVHNSdjRLSUMtUm1Kd0hIZ3VBeExnU2pSR05QN0pNR0dJIn0.eyJleHAiOjE2NjMyMjYwOTYsImlhdCI6MTY2MzIyNTc5NiwianRpIjoiNjAwMmJjM2QtMTVjYy00ZGE0LTk3NzQtMjk2MDFjMjRhMjBlIiwiaXNzIjoiaHR0cDovLzM0Ljk1LjUuMTk0OjgwODAvcmVhbG1zL215cmVhbG0iLCJhdWQiOiJhY2NvdW50Iiwic3ViIjoiZjRmZjQ0YmEtZTZiZi00NGM3LThlZDgtYjc5NjQ2YzMxZTA1IiwidHlwIjoiQmVhcmVyIiwiYXpwIjoibXljbGllbnQiLCJhY3IiOiIxIiwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbImRlZmF1bHQtcm9sZXMtbXlyZWFsbSIsIm9mZmxpbmVfYWNjZXNzIiwidW1hX2F1dGhvcml6YXRpb24iXX0sInJlc291cmNlX2FjY2VzcyI6eyJteWNsaWVudCI6eyJyb2xlcyI6WyJ1bWFfcHJvdGVjdGlvbiJdfSwiYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2UtYWNjb3VudCIsIm1hbmFnZS1hY2NvdW50LWxpbmtzIiwidmlldy1wcm9maWxlIl19fSwic2NvcGUiOiJyZXNvdXJjZTp1cGRhdGUgcHJvZmlsZSBlbWFpbCByZXNvdXJjZTp2aWV3IiwiY2xpZW50SG9zdCI6IjEwLjE2Mi4xNS4yMTYiLCJjbGllbnRJZCI6Im15Y2xpZW50IiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJzZXJ2aWNlLWFjY291bnQtbXljbGllbnQiLCJjbGllbnRBZGRyZXNzIjoiMTAuMTYyLjE1LjIxNiJ9.eOoQnYEtYpcc-9f-ReQUO69x2qVHcmtYLIBk0OACVhjJH0tW_p6m3pBv-HF_vbeQTPb3Jofoqyel60L4B_vr8pyiN50du7HlriC1bMgCF9GpAmdratX-U5yVMUl-Pfps6qR4EcLb9MGE9O6Xc9_Aeoxikwqe20J84-95_j7zctcpZhryaSan87vrn_EheQ5Ss6uPpIJFzvH8_PEUGFRVeDIjr9mz42PGHw90T8sYcqKDdNQw17RR3r5a0nB1iLaiODGfmYCGX1ZJS8RE3ootSiyHw6GSLHfFXiAzU97VyfaP0cKdarWwvx0tsAAXfU7tNwDDGdR6HBcCgQWD040Jdw
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Content-Type: application/json; charset=utf-8
< Content-Length: 2364
< ETag: W/"93c-QcKxNKKWo+hzUG+fFX+cu4G8mzA"
< Date: Sat, 11 Jun 2022 21:12:44 GMT
< Connection: keep-alive
< Keep-Alive: timeout=5
< Set-Cookie: NSC_TMAA=2c24a6c0dc4ead50001867860608278f;HttpOnly;Path=/;
< Set-Cookie: NSC_TMAP=xyz;Path=/;expires=Wednesday, 09-Nov-1999 23:12:40 GMT;
< Set-Cookie: NSC_TMAV=xyz;Path=/;expires=Wednesday, 09-Nov-1999 23:12:40 GMT;
<
{ [2364 bytes data]
100  2364  100  2364    0     0   5020      0 --:--:-- --:--:-- --:--:--  5150
* Connection #0 to host pet-service.echoserver.com left intact
{
  ...
$
```
- Let's use again the same token and sent a POST request to the same resource
```shell
$ noglob curl -v -X POST pet-service.echoserver.com/pet.aspx?id=12345 -H 'Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJaV0FHYlEydnotVHNSdjRLSUMtUm1Kd0hIZ3VBeExnU2pSR05QN0pNR0dJIn0.eyJleHAiOjE2NjMyMjYwOTYsImlhdCI6MTY2MzIyNTc5NiwianRpIjoiNjAwMmJjM2QtMTVjYy00ZGE0LTk3NzQtMjk2MDFjMjRhMjBlIiwiaXNzIjoiaHR0cDovLzM0Ljk1LjUuMTk0OjgwODAvcmVhbG1zL215cmVhbG0iLCJhdWQiOiJhY2NvdW50Iiwic3ViIjoiZjRmZjQ0YmEtZTZiZi00NGM3LThlZDgtYjc5NjQ2YzMxZTA1IiwidHlwIjoiQmVhcmVyIiwiYXpwIjoibXljbGllbnQiLCJhY3IiOiIxIiwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbImRlZmF1bHQtcm9sZXMtbXlyZWFsbSIsIm9mZmxpbmVfYWNjZXNzIiwidW1hX2F1dGhvcml6YXRpb24iXX0sInJlc291cmNlX2FjY2VzcyI6eyJteWNsaWVudCI6eyJyb2xlcyI6WyJ1bWFfcHJvdGVjdGlvbiJdfSwiYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2UtYWNjb3VudCIsIm1hbmFnZS1hY2NvdW50LWxpbmtzIiwidmlldy1wcm9maWxlIl19fSwic2NvcGUiOiJyZXNvdXJjZTp1cGRhdGUgcHJvZmlsZSBlbWFpbCByZXNvdXJjZTp2aWV3IiwiY2xpZW50SG9zdCI6IjEwLjE2Mi4xNS4yMTYiLCJjbGllbnRJZCI6Im15Y2xpZW50IiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJzZXJ2aWNlLWFjY291bnQtbXljbGllbnQiLCJjbGllbnRBZGRyZXNzIjoiMTAuMTYyLjE1LjIxNiJ9.eOoQnYEtYpcc-9f-ReQUO69x2qVHcmtYLIBk0OACVhjJH0tW_p6m3pBv-HF_vbeQTPb3Jofoqyel60L4B_vr8pyiN50du7HlriC1bMgCF9GpAmdratX-U5yVMUl-Pfps6qR4EcLb9MGE9O6Xc9_Aeoxikwqe20J84-95_j7zctcpZhryaSan87vrn_EheQ5Ss6uPpIJFzvH8_PEUGFRVeDIjr9mz42PGHw90T8sYcqKDdNQw17RR3r5a0nB1iLaiODGfmYCGX1ZJS8RE3ootSiyHw6GSLHfFXiAzU97VyfaP0cKdarWwvx0tsAAXfU7tNwDDGdR6HBcCgQWD040Jdw'

* Connected to pet-service.echoserver.com (34.95.21.135) port 80 (#0)
> POST /pet.aspx?id=12345 HTTP/1.1
> Host: pet-service.echoserver.com
> User-Agent: curl/7.77.0
> Accept: */*
> Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJaV0FHYlEydnotVHNSdjRLSUMtUm1Kd0hIZ3VBeExnU2pSR05QN0pNR0dJIn0.eyJleHAiOjE2NjMyMjYwOTYsImlhdCI6MTY2MzIyNTc5NiwianRpIjoiNjAwMmJjM2QtMTVjYy00ZGE0LTk3NzQtMjk2MDFjMjRhMjBlIiwiaXNzIjoiaHR0cDovLzM0Ljk1LjUuMTk0OjgwODAvcmVhbG1zL215cmVhbG0iLCJhdWQiOiJhY2NvdW50Iiwic3ViIjoiZjRmZjQ0YmEtZTZiZi00NGM3LThlZDgtYjc5NjQ2YzMxZTA1IiwidHlwIjoiQmVhcmVyIiwiYXpwIjoibXljbGllbnQiLCJhY3IiOiIxIiwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbImRlZmF1bHQtcm9sZXMtbXlyZWFsbSIsIm9mZmxpbmVfYWNjZXNzIiwidW1hX2F1dGhvcml6YXRpb24iXX0sInJlc291cmNlX2FjY2VzcyI6eyJteWNsaWVudCI6eyJyb2xlcyI6WyJ1bWFfcHJvdGVjdGlvbiJdfSwiYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2UtYWNjb3VudCIsIm1hbmFnZS1hY2NvdW50LWxpbmtzIiwidmlldy1wcm9maWxlIl19fSwic2NvcGUiOiJyZXNvdXJjZTp1cGRhdGUgcHJvZmlsZSBlbWFpbCByZXNvdXJjZTp2aWV3IiwiY2xpZW50SG9zdCI6IjEwLjE2Mi4xNS4yMTYiLCJjbGllbnRJZCI6Im15Y2xpZW50IiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJzZXJ2aWNlLWFjY291bnQtbXljbGllbnQiLCJjbGllbnRBZGRyZXNzIjoiMTAuMTYyLjE1LjIxNiJ9.eOoQnYEtYpcc-9f-ReQUO69x2qVHcmtYLIBk0OACVhjJH0tW_p6m3pBv-HF_vbeQTPb3Jofoqyel60L4B_vr8pyiN50du7HlriC1bMgCF9GpAmdratX-U5yVMUl-Pfps6qR4EcLb9MGE9O6Xc9_Aeoxikwqe20J84-95_j7zctcpZhryaSan87vrn_EheQ5Ss6uPpIJFzvH8_PEUGFRVeDIjr9mz42PGHw90T8sYcqKDdNQw17RR3r5a0nB1iLaiODGfmYCGX1ZJS8RE3ootSiyHw6GSLHfFXiAzU97VyfaP0cKdarWwvx0tsAAXfU7tNwDDGdR6HBcCgQWD040Jdw
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 403 Access Forbidden
< Connection: close
< Content-Length: 29
< Content-Type: text/html
< Cache-Control: no-cache,no-store
< Pragma: no-cache
< Set-Cookie: NSC_TMAA=727ad324687e1614b366a4e0eccf258f;Path=/;
< Set-Cookie: NSC_TMAS=a7358754ef136d0b3fc7677e0bea30c8;Secure;Path=/;
<
* Closing connection 0
Error: Not a privileged User.
```

Notice that now we got a different error 403 Access Forbidden - Not a privileged User. If we check above, we requested for an access token with resource:view and resource:update scopes while POST requires resource:create scope based on our authorization policy. This is where our authorization policy kicked in and denied access.

---

## Network and security teams can view my configuration from the Citrix ADC VPX including:

- Citrix WAF Policies 
  ![](assets/waf_basic_policy.png)
- Citrix WAF Profiles
  ![](assets/waf_profiles.png)
- Citrix WAF Policy Bindings to Virtual Load Balancing Server 
  ![](assets/waf_basic_policy_binding.png)  
- Citrix WAF Policy Binding Details
  ![](assets/waf_basic_policy_binding_details.png)

## Also they can access all policies defined on CPX using CLI

```shell
$ kubectl -it exec cpx-ingress-65fb478bb5-4v6wn -n demoapp bash
$ root@cpx-ingress-65fb478bb5-4v6wn:/# cli_script.sh "sh lb vserver k8s-pet-service_7030_lbv_cfzb2mubztudgxlsbsvhnoqrfl3vccul"

exec: sh lb vserver k8s-pet-service_7030_lbv_cfzb2mubztudgxlsbsvhnoqrfl3vccul
	k8s-pet-service_7030_lbv_cfzb2mubztudgxlsbsvhnoqrfl3vccul (0.0.0.0:0) - HTTP	Type: ADDRESS
	State: UP
	Last state change was at Wed Jun  8 09:36:03 2022
	Time since last state change: 3 days, 12:44:58.580
	Effective State: UP  ARP:DISABLED
	Client Idle Timeout: 180 sec
	Down state flush: ENABLED
	Disable Primary Vserver On Down : DISABLED
	Comment: "rv:571579,ing:cpx-ingress,ingport:80,ns:demoapp,svc:pet-service,svcport:7030"
	Appflow logging: ENABLED
	Port Rewrite : DISABLED
	No. of Bound Services :  1 (Total) 	 1 (Active)
	Configured Method: LEASTCONNECTION	BackupMethod: ROUNDROBIN
	Mode: IP
	Persistence: NONE
	Vserver IP and Port insertion: OFF
	401 Based Authentication: ON	Authn Vserver: k8s-pet-service_7030_lbv_cfzb2mubztudgxlsbsvhnoqrfl3vccul_authvsrvr
	Push: DISABLED	Push VServer:
	Push Multi Clients: NO
	Push Label Rule: none
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
Bound Service Groups:
1)	Group Name: k8s-pet-service_7030_sgp_cfzb2mubztudgxlsbsvhnoqrfl3vccul
		1) k8s-pet-service_7030_sgp_cfzb2mubztudgxlsbsvhnoqrfl3vccul (10.0.0.14: 80) - HTTP State: UP	Weight: 1
4)	Authorization Policy Name: k8s_crd_authpolicy_authexample_authzpolicy_1_demoapp	Type: Advanced	Priority: 100001250
	GotoPriority Expression: END

5)	Authorization Policy Name: k8s_crd_authpolicy_authexample_authzpolicy_2_demoapp	Type: Advanced	Priority: 100001260
	GotoPriority Expression: END

6)	Authorization Policy Name: k8s_crd_authpolicy_authexample_authzpolicy_3_demoapp	Type: Advanced	Priority: 100001270
	GotoPriority Expression: END

7)	Rewrite Policy Name: k8s_crd_rewritepolicy_rwpolicy_httpxforwardedforaddition_0_demoapp	Priority: 100300012
	GotoPriority Expression: END
	Flowtype: REQUEST
8)	Rewrite Policy Name: k8s_crd_rewritepolicy_rwpolicy_httpxforwardedforaddition_1_demoapp	Priority: 100300016
	GotoPriority Expression: END
	Flowtype: REQUEST
9)	Responder Policy Name: k8s_crd_ratelimit_demoapp_ratelimit	Priority: 100200030
	GotoPriority Expression: END
	Flowtype: REQUEST
Done
  ```



To see more configuration options, review the Citrix [Auth](https://docs.citrix.com/en-us/citrix-k8s-ingress-controller/crds/auth.html), [Rate limit](https://docs.citrix.com/en-us/citrix-k8s-ingress-controller/crds/rate-limit.html), [Rewrite and Responder](https://docs.citrix.com/en-us/citrix-k8s-ingress-controller/crds/rewrite-responder.html), [WAF](https://docs.citrix.com/en-us/citrix-k8s-ingress-controller/crds/waf.html) and [Bot](https://docs.citrix.com/en-us/citrix-k8s-ingress-controller/crds/bot.html) CRDs documentation. 



## Summary  

As a developer, my primary concern is to quickly and securely release my cloud-native application with the pace of my development team and without delays from external teams. Using the Citrix Ingress Controller, WAF CRDs, ADC CPX and API Gateway policies, in a Google Anthos platform allows my team to achieve this goal. 
- Network, Security, and Platform teams can configure sensible defaults and constraints automatically without needing my involvement
- Configurable items specific to my application, **including WAF security, Authentication, Authorization, API Hardening, Rate limiting and more**, are delegated to my team in a self-service manner
- Visibility of my workloads are present in the northbound network infrastructure to provide better monitoring and alerting across teams
- I can collaborate in network and security troubleshooting with my network engineers with a shared context and understanding of my workloads

