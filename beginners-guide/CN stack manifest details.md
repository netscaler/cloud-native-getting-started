## Understanding of Citrix Modern App deployment components and its usage

### CIC Sample Yaml Template (CIC deployed as standalone pod to configure Citrix ADCs outside K8s clusters)

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cic-k8s-ingress-controller
spec:
  selector:
    matchLabels:
      app: cic-k8s-ingress-controller
  replicas: 1
  template:
    metadata:
      name: cic-k8s-ingress-controller
      labels:
        app: cic-k8s-ingress-controller
      annotations:
    spec: 
      serviceAccountName: cic-k8s-role
      containers:
      - name: cic-k8s-ingress-controller
        image: "quay.io/citrix/citrix-k8s-ingress-controller:1.17.13"
        env:
         # Set NetScaler NSIP/SNIP, SNIP in case of HA (mgmt has to be enabled) 
         - name: "NS_IP"
           value: "x.x.x.x"
         # Set username for Nitro
         - name: "NS_USER"
           valueFrom:
            secretKeyRef:
             name: nslogin
             key: username
         - name: "LOGLEVEL"
           value: "INFO"
         # Set user password for Nitro
         - name: "NS_PASSWORD"
           valueFrom:
            secretKeyRef:
             name: nslogin
             key: password
         # Set log level
         - name: "EULA"
           value: "yes"
        args:
          - --ingress-classes
            citrix
          - --feature-node-watch
            false
        imagePullPolicy: Always
```

Keep track of updated CIC from GitHub CIC documentation.

Let’s understand CIC yaml configuration and its use case;
•	CIC is deployed as “Deployment” kind to leverage K8s self-healing property (CIC pod will be restarted automatically if deleted).
•	CIC will always run in Replica Set (replicas)– 1
•	CIC needs RBAC permission to talk to K8 API server and configure ADCs accordingly. Hence CIC has “serviceAccountName” defined to specify RBAC permissions.
•	CIC configuring Citrix ADC (outside K8s clusters) VPX/MPX/SDX/BLX deployed as standalone pod hence CIC has only one container definition present as mentioned above by name: cic-k8s-ingress-controller
•	CIC container images are hosted in quay.io container repository as mentioned in image: "quay.io/citrix/citrix-k8s-ingress-controller:1.17.13"
•	There are environmental variables (env) defined in CIC definition categorized in two parts – Mandatory arguments and Optional arguments. Let’s discuss all arguments below.
o	Mandatory arguments:
	name: "NS_IP" -> Mention Citrix ADC NSIP that will be configured by CIC (Ingress Proxy/Tier 1 ADC).  Use NSIP for standalone ADC, use SNIP for HA pair of ADC and use CLIP for ADC clusters.
	name: "NS_USER" & name: "NS_PASSWORD" -> Citrix Tier 1 ADC login credentials required by CIC to configure it automatically. You can use K8s secret for ADC credentials.
	name: "EULA" -> This variable is for the end user license agreement (EULA) which has to be set as YES for the Citrix ingress controller to up and run.
o	Optional arguments:
	name: “kubernetes_url” -> Set the K8s API server IP to register for K8s events, default value is K8s internal API server IP.
	name: "LOGLEVEL” -> Set the CIC log levels from CRITICAL/ERROR/WARNING/INFO/DEBUG. Default loglevel is set to DEBUG
	name: "NS_PROTOCOL and NS_PORT” -> Set the SSL vs HTTP communication mode for Citrix ADC management login. By default NS_PROTOCOL is HTTP and NS_PORT is 80. Other option is to use HTTPs and port 443.
	name: "Ingress Class” -> Set the Ingress class in args field where Ingress class will be used when multiple Ingress load balancers are used to load balance different ingress resources. 
	name: "NS_VIP” -> Set the Content switching vserver IP (Ingress ADC frontend IP on which client traffic will land). This variable is useful in the case where all Ingresses run in the Virtual IP address. This variable takes precedence over the frontend-ip annotation.
	name: "NS_APPS_NAME_PREFIX” -> Useful when CICs from different K8s clusters configure same Tier 1 ADC, allows you to segregate K8s cluster configuration from each other. Default value is “k8s”
	name: "NS_MGMT_USER” & name: "NS_MGMT_PASS” -> This is Citrix ADC CPX specific argument required when CPX wants to register with ADM for observability use cases. This environment variable is supported from Citrix ADC CPX 13.0 and later releases
	name: "NS_MGMT_SERVER” -> Specifies the Citrix ADM server or the agent IP address that manages the Citrix ADC CPX
	name: "NS_MGMT_FINGER_PRINT” -> Specifies the fingerprint of the Citrix ADM server or the agent IP address that manages Citrix ADC CPX. 
	name: "NS_HTTP_PORT” -> Specifies the port on which the HTTP service is available in Citrix ADC CPX. It is used by Citrix ADM to trigger NITRO calls to Citrix ADC CPX.
	name: "NS_HTTPS_PORT” -> Set the port on which HTTPS service is available in Citrix ADC CPX. It is used by Citrix ADM to trigger NITRO calls to Citrix ADC CPX.
	name: "LOGSTREAM_COLLECTOR_IP” -> Set the Citrix ADM IP address for collecting analytics.
	name: "NS_CONFIG_DNS_REC” -> Enables the DNS server configuration on Citrix ADC. This variable is configured at the boot time and cannot be changed at runtime. Possible values are true or false. The default value is `false`.
	name: "NAMESPACE” -> While running a Citrix ingress controller with Role based RBAC, you must provide the namespace which you want to listen or get events. This namespace must be same as the one used for creating the service account.
	name: "POD_IPS_FOR_SERVICEGROUP_MEMBERS” -> If this variable is set as True, pod IP address and port are added instead of NodeIP and NodePort as service group members for LoadBalancer or NodePort type services.
	name: "IGNORE_NODE_EXTERNAL_IP” -> When you want to prefer an internal IP address over an external IP address for NodeIP, you can set this variable to True.


 
###Ingress YAML template: (Ingress rules defined for Citrix ADC outside K8s cluster)

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress-vpx
  annotations:
   kubernetes.io/ingress.class: "vpx"
   ingress.citrix.com/insecure-termination: "redirect"
   ingress.citrix.com/frontend-ip: "x.x.x.x"
   ingress.citrix.com/secure_backend: '{"lb-service-hotdrinks": "True","lb-service-colddrinks": "True"}'
spec:
  tls:
  - secretName: hotdrink-secret
  rules:
  - host:  hotdrink.beverages.com
    http:
      paths:
      - path: 
        backend:
          serviceName: lb-service-hotdrinks
          servicePort: 443
  - host:  guestbook.beverages.com
    http:
      paths:
      - path: 
        backend:
          serviceName: lb-service-guestbook
          servicePort: 80
  - host:  colddrink.beverages.com
    http:
      paths:
      - path: 
        backend:
          serviceName: lb-service-colddrinks
          servicePort: 443
```

Let’s understand Ingress resources and supported configurable parameters.
•	“Annotations” -> It is useful to configure Ingress options depending on Citrix Ingress Controller.
o	kubernetes.io/ingress.class -> It maps with Ingress class in CIC args and configures Ingress proxy mentioned in CIC.
o	Rest all supported Ingress annotations and smart annotations are listed in developer docs. 
•	tls in specs -> It created frontend of Ingress proxy secured (i.e., Client will access frontend-IP over SSL)
o	secretName -> It is K8s secret used as SSL server certificate pushed by CIC on Tier 1 ADC to allow SSL traffic on frontend IP.
•	Server Name Indication (SNI) option allows you to bind multiple certificates to a single virtual server.
e.g.

``
tls:
- hosts: 
   - a.x.y.com
secretName: a-secret
- hosts: 
   - b.x.y.com
secretName: b-secret 
``

In this case, CIC will configure above 2 certs on same Content switching virtual server with host details.
•	rules in the specs -> Rules defined here creates CS policies, CS actions and its associated LB vserver, Service Group and service group members.
o	E.g., host:  hotdrink.beverages.com will create CS policy to routes hotdrink.beverages.com traffic to lb-service-hotdrinks services.
o	Know more about how to configure hostname based routing, URL path based routing, wildcard host based routing, default backend routing from ingress use case guide.

