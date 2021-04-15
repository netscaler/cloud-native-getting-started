# Citrix ADM Service Graph Distributed Tracing
The aim of this example is to help visualising the request flow between different microservices using Citrix ADM
# Table of Contents

A. [Deploy and register Citrix ADM Agent](#deploy-register-citrix-adm-agent)

B. [Add Cluster in Citrix ADM](#register-adm-agent)

C. [Deploy Netflix application on Kubernetes Cluster ](#deploy-application)

D. [Citrix Cloud Native Dual Tier Topology ](#deploy-citrix-cloud-native-stack)

E. [Send Traffic](#send-traffic) 

F. [Visualize Servicegraph in Citrix ADM](#servicegraph)

G. [Tracing](#trace)

# Prerequisites.
- An ADM Agent
-  The [Kubernetes](https://kubernetes.io/) version 1.6 or later
- Registration of Citrix ADC CPX in ADM: You may want to register your CPX in ADM for licensing or to obtain [servicegraph](https://docs.citrix.com/en-us/citrix-application-delivery-management-service/application-analytics-and-management/service-graph.html). For this you will have to create a Kubernetes secret using ADM credentials and provide it while install the chart. Create a Kubernetes secret for the user name and password using the following command:

  ```
  kubectl create secret generic admlogin --from-literal=username=<adm-username> --from-literal=password=<adm-password> 
  ```
-   The user name and password of the Citrix ADC VPX or MPX appliance used as the ingress device for Tier-1. The Citrix ADC appliance needs to have system user account (non-default) with certain privileges so that Citrix ingress controller can configure the Citrix ADC VPX or MPX appliance. For instructions to create the system user account on Citrix ADC, see [Create System User Account for CIC in Citrix ADC](#create-system-user-account-for-cic-in-citrix-adc).
    You can pass user name and password using Kubernetes secrets. Create a Kubernetes secret for the user name and password using the following command:
    ```
       kubectl create secret generic nslogin --from-literal=username='cic' --from-literal=password='mypassword'
    ```

### Create system User account for Citrix ingress controller in Citrix ADC

Citrix ingress controller configures the Citrix ADC using a system user account of the Citrix ADC. The system user account should have certain privileges so that the CIC has permission configure the following on the Citrix ADC:
-  Add, Delete, or View Content Switching (CS) virtual server
-  Configure CS policies and actions
-  Configure Load Balancing (LB) virtual server
-  Configure Service groups
-  Cofigure SSl certkeys
-  Configure routes
-  Configure user monitors
-  Add system file (for uploading SSL certkeys from Kubernetes)
-  Configure Virtual IP address (VIP)
-  Check the status of the Citrix ADC appliance

**Note:**
> The system user account would have privileges based on the command policy that you define.
To create the system user account, do the following:
1.  Log on to the Citrix ADC appliance. Perform the following:
    1.  Use an SSH client, such as PuTTy, to open an SSH connection to the Citrix ADC appliance.
    2.  Log on to the appliance by using the administrator credentials.
2.  Create the system user account using the following command:
    ```
       add system user <username> <password>
    ```
    For example:
    ```
       add system user cic mypassword
    ```
3.  Create a policy to provide required permissions to the system user account. Use the following command:
    ```
       add cmdpolicy cic-policy ALLOW "(^\S+\s+cs\s+\S+)|(^\S+\s+lb\s+\S+)|(^\S+\s+service\s+\S+)|(^\S+\s+servicegroup\s+\S+)|(^stat\s+system)|(^show\s+ha)|(^\S+\s+ssl\s+certKey)|(^\S+\s+ssl)|(^\S+\s+route)|(^\S+\s+monitor)|(^show\s+ns\s+ip)|(^\S+\s+system\s+file)"
    ```
4.  Bind the policy to the system user account using the following command:
    ```
       bind system user cic cic-policy 0
    ```    
## <a name="deploy-register-citrix-adm-agent">A) Deploy and register Citrix ADM Agent</a>
Follow [this](https://docs.citrix.com/en-us/citrix-application-delivery-management-service/getting-started.html) link to deploy Citrix ADM agent.

## <a name="register-adm-agent"> B) Add Cluster in Citrix ADM</a>
 Refer [this]( https://docs.citrix.com/en-us/citrix-application-delivery-management-service/application-analytics-and-management/sg-unified-single-ingress-topology.html#add-kubernetes-cluster-in-citrix-adm) for adding cluster in Citrix ADM.

## <a name="deploy-application"> C) Deploy Netflix application on Kubernetes Cluster </a> 
Run following to deploy Netflix application on your Kubernetes Cluster 
```
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/servicegraph/manifest/netflix.yaml
```
## <a name="deploy-citrix-cloud-native-stack"> D) Citrix Cloud Native Dual Tier Topology </a>
Let's understand the Netflix application topology having Citrix ADC to deliver best user experience in North-South and East-West Load balancing.
![](images/topology.png)

In this topology, we have deployed 2 types of Citrix ADCs. One is VPX/MPX (non container proxy) for routing the North-South traffic for microservices. In this deployment, we have deployed VPX as Tier 1 ADC
Second is Citrix ADC CPX (container proxy) for routing North-South Tier 1 traffic and East-West microservice traffic.
This deployment has its own advantages over service mesh deployment such as;
* Citrix ADC Service Mesh lite topology eliminates need of CPX as sidecar proxy for each microservices
* One Citrix ADC CPX proxy can frontend more than one microservice application as shown in above topology diagram.
Lets deploy the Netflix application in Service mesh lite deployment where
* Tier 1 ADC - VPX to ingress Secure North-South traffic. You can have MPX/BLX as TIer 1 ADC also.
* Tier 2 ADC - CPX to route North-South traffic from Tier 1 ADC to frontend Netflix microservice application
* Tier 2 ADC - CPX to route East-West traffic from Netflix application.


**Tier 1 ADC** - VPX to ingress Secure North-South traffic. You can have MPX/BLX as Tier 1 ADC also.

```
wget https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/servicegraph/manifest/citrix-cloud-native.yaml
```

Update `NS_IP` in `citrix-cloud-native.yaml` yaml file with Citrix ADC Management IP in 

```
    - name: "NS_IP"
      value: "A.B.C.D"  
```
**Tier-2 ADC** - CPX to route North-South traffic from Tier 1 ADC to frontend Netflix microservice applicatio and route East-West traffic from Netflix microservices

Update below Environment variables in `citrix-cloud-native.yaml` file for service graph generation
i. NS_MGMT_SERVER -> With Citrix ADM agent IP 
ii. "NS_MGMT_FINGER_PRINT" -> Citrix ADM agent fingerprint 
iii. "LOGSTREAM_COLLECTOR_IP" -> With Citrix ADM agent IP 
iv. "NS_LOGPROXY" -> With Citrix ADM agent IP 

Update `endpoint.server` with the Citrix ADM Agent IP in `adc-netflix-cic-configmap` and `adc-netflix-cpx-cic-configmap` in `citrix-cloud-native.yaml` file under `NS_ANALYTICS_CONFIG`. 

After updating above environment variables, deploy tier-2 CPX using 
```
    kubectl apply -f citrix-cloud-native.yaml
```
**Create Ingress and Services for Netflix Application**

```
    wget https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/servicegraph/manifest/vpx_ingress.yaml
``` 
**NOTE** Update `ingress.citrix.com/frontend-ip` in `vpx_ingress.yaml` with Virtual IP with which you want to expose Netflix Application.

```
    kubectl apply -f vpx_ingress.yaml

    wget https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/servicegraph/manifest/cpx_ingress.yaml

    kubectl create -f cpx_ingress.yaml

    wget https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/servicegraph/manifest/smlite_services.yaml

    kubectl create -f smlite_services.yaml
```

Now enable  [Auto-select Virtual Servers](https://docs.citrix.com/en-us/citrix-application-delivery-management-service/application-analytics-and-management/sg-service-mesh-dual-tier-topology.html#enable-auto-select-virtual-servers-for-licensing)  to license the CPX virtual servers.
 
Finally enable the  [Web transaction and TCP transaction settings](https://docs.citrix.com/en-us/citrix-application-delivery-management-service/application-analytics-and-management/sg-service-mesh-dual-tier-topology.html#enable-web-transaction-and-tcp-transaction-settings)  to  **All**  for Citrix ADM agent to get HTTP and TCP transactions.

## <a name="send-traffic"> E) Send Traffic </a>
Send traffic using helper script
```
	wget https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/servicegraph/manifest/traffic.sh
```
Update VIP with Virtual IP use to expose the Netflix app in `traffic.sh` and start traffic.
```
    nohup sh traffic.sh > log &
```
## <a name="servicegraph"> F) Visualize Service Graph in Citrix ADM</a>
In ADM goto >Application > Service Graph > MicroServices
![](images/servicegraph.png)


![](images/servicegraph-detail.png)

We can view transation logs as well in the servicegraph.

![](images/transactionlog.png)

## <a name="trace">G) Tracing </a>

A user can select "See Trace Details" to visualize the entire trace in the form of a chart of all transactions which are part of the trace.

![](images/tracing.png)

