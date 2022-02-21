# Deploy Multi-cluster ingress for Global Server load balancing (GSLB) use case (Deployment topology: Service mesh lite: Tier 1 ADC as Citrix ADC VPX, Tier 2 ADC as Citrix ADC CPX)

In this guide you will learn:
* What is service mesh lite deployment?
* How to deploy microservice applications, Citrix ADC VPX, Citrix ADC CPX
* How to deploy Citrix Ingress Controller to configure Citrix ADC and ingress for routing rules
* How to load balance an application deployed across K8s and OpenShift clusters using Multi-cluster ingress

Citrix ADC works in the two-tier architecture deployment solution to load balance the enterprise grade applications deployed in microservices and access those through internet. Tier 1 can be a traditional load balancers such as VPX/SDX/MPX, or CPX (containerized Citrix ADC) to manage high scale north-south traffic. CPX as Tier 2 for managing microservices and load balances the north-south & east-west traffic.

We will reuse the Service mesh lite deployment from [getting started guide](https://github.com/citrix/cloud-native-getting-started/tree/master/on-prem/ServiceMeshLite#section-b-expose-cpx-as-ingress-type-service) to deploy Cloud Native stack. To deploy an application across multiple Kubernetes distributions, we have used Open source on-prem Kubernetes cluster and on-prem OpenShift cluster to demonstarted GSLB use case.

Toplogy:


## Pre-requisite before you start microservice deployment

1.	Setup Open source On-prem Kubernetes cluster

    Kubernetes is an open-source system for automating deployment, scaling, and management of containerized applications. Please install and configure Kubernetes cluster with one master node and at least two worker node deployment.
    Recommended OS: Ubuntu 16.04 desktop/server OS. 
    Visit: https://kubernetes.io/docs/setup/ for Kubernetes cluster deployment guide.
    Once Kubernetes cluster is up and running, execute the below command on master node to get the node status.
    ``` 
    kubectl get nodes
    ```
    ![nodes](images/nodes.PNG)
 
    (Screenshot above has Kubernetes cluster with one master and one worker node).

2.	<u>[Optional]</u> Set up a Kubernetes dashboard for deploying containerized applications.
    
    Please visit https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/ and follow the steps mentioned to bring the Kubernetes dashboard up as shown below.

    ![k8sdashboard](https://user-images.githubusercontent.com/42699135/50677396-99179180-101f-11e9-95a4-1d9aa1b9051b.png)

3.  Add K8s CIDR routes to Tier 1 ADC to reach K8s network

    Make sure that route configuration is present in Tier 1 ADC so that Ingress NetScaler should be able to reach Kubernetes pod network for seamless connectivity. Please refer to https://github.com/citrix/citrix-k8s-ingress-controller/blob/master/docs/network/staticrouting.md#manually-configure-route-on-the-citrix-adc-instance for Network configuration.
    If you have K8s cluster and Tier 1 Citrix ADC in same subnet then you do not have to do anything, below example will take care of route info.
    You need Citrix Node Controller configuration only when K8s cluster and Tier 1 ADC are in different subnet. Please refer to https://github.com/citrix/citrix-k8s-node-controller for Network configuration.

4.	Setup On-prem OpenShift cluster

	Red Hat OpenShift is an container application platform based on the Kubernetes container orchestrator for enterprise application development and deployment. Please install and configure OpenShift cluster with one master node and at least one worker node deployment.

	Recommended OS: Red Hat Enterprise Linux 7.6 and above 

	Visit: https://docs.openshift.com/container-platform/3.11/install/running_install.html for OpenShift cluster deployment guide.
	Once OpenShift cluster is up and running, execute the below command on master node to get the node status.
	``` 
	oc get nodes
	```
	![oc-nodes](https://user-images.githubusercontent.com/48945413/59844387-61f02f00-9378-11e9-836b-1a8f59e4f3b2.PNG)
	 
	(Screenshot above has OpenShift cluster with one master and two worker node).

5.	Citrix ADC should be licensed properly to support GSLB deployment. Citrix ADC VPX/MPX/SDX express does not support GSLB deployment.

	* Ensure that you have 2 Citrix ADCs deployed, one for each K8s cluster. In this demo I will use 2 VPXs running on 13.0.52.24 version, set with Platinum Edition license.
	* Ensure that management access is enabled on SNIP of both VPXs.
	* Ensur that VPX and K8s clusters are in same subnet to make below demo work, in case you have ADCs and K8s clusters in different network then deploy Citrix Node Controller to establish the connectivity between ADC and cluster.


Lets begin the deployment using below sections. Please follow the deployment order sequentially to avoid conflicts.

| Section | Description |
| ------- | ----------- |
| [Section A]() | Deploy Service Mesh lite topology in K8s cluster |
| [Section B]() | Deploy Service mesh lite topology in OpenShift cluster |
| [Section C]() | Configure GSLB sites in Tier 1 ADC |
| [Section D]() | Deploy Multi-cluster Ingress to achieve GSLB |
| [Section E]() | Clean Up |


## Section A (Deploy Service Mesh lite topology in K8s cluster)

1. Deploy beverage applications

	```
	kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/namespace.yaml
	kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/rbac.yaml
	kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/team_hotdrink.yaml -n team-hotdrink
	kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/team_colddrink.yaml -n team-colddrink
	kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/team_guestbook.yaml -n team-guestbook
	```

2. Create a secret for the login into Tier 1 ADC, Update username and password for your Tier 1 ADC and execute below command
	```
	kubectl create secret generic nsvpxlogin --from-literal=username='userA' --from-literal=password='password' -n tier-2-adc
	```

3. Deploy Kubernetes secret as TLS certificate for ADC to establish SSL communication

	**Note:** Please upload your TLS certificate and TLS key into hotdrink-secret.yaml & colddrink-secret. We have updated our security policies and removed SSL certificate from guides.

	```
	kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/hotdrink-secret.yaml -n tier-2-adc    
	kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/hotdrink-secret.yaml -n team-hotdrink
	kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/colddrink-secret.yaml -n team-colddrink
	```

4. Lets deploy CPX now;
	```
	kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/cpx.yaml -n tier-2-adc
	```

5. Deploy the VPX ingress and Citrix ingress controller to configure tier 1 ADC VPX automatically

	```
	wget https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/ingress_vpx.yaml
	wget https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/cic_vpx.yaml
	```

	Update  ingress_vpx.yaml and cic_vpx.yaml with following configuration

	Go to ``ingress_vpx.yaml`` and change the IP address of ``ingress.citrix.com/frontend-ip: "x.x.x.x"`` annotation to one of the free IP which will act as content switching vserver for accessing microservices.
	e.g. ``ingress.citrix.com/frontend-ip: "10.105.158.160"``

	Go to ``cic_vpx.yaml`` and change the NS_IP value to your VPX NS_IP.         
	    *  ``- name: "NS_IP"
	        value: "x.x.x.x"``
	    *  Update VPX crednetails in cic_vpx.yaml file 

	Now execute the following commands after the above change.
	```
	kubectl create -f ingress_vpx.yaml -n tier-2-adc
	kubectl create -f cic_vpx.yaml -n tier-2-adc
	```


## Section B (Deploy Service mesh lite topology in OpenShift cluster)

1. Deploy beverage applications

	```
	oc create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/namespace.yaml
	oc create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/rbac.yaml
	oc create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/team_hotdrink.yaml -n team-hotdrink
	oc create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/team_colddrink.yaml -n team-colddrink
	oc create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/team_guestbook.yaml -n team-guestbook
	```

2. Create a secret for the login into Tier 1 ADC, Update username and password for your Tier 1 ADC and execute below command
	```
	oc create secret generic nsloginvpx --from-literal=username='userA' --from-literal=password='password' -n tier-2-adc
	```

3. Deploy Kubernetes secret as TLS certificate for ADC to establish SSL communication

	**Note:** Please upload your TLS certificate and TLS key into hotdrink-secret.yaml & colddrink-secret. We have updated our security policies and removed SSL certificate from guides.

	```
	oc create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/hotdrink-secret.yaml -n tier-2-adc    
	oc create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/hotdrink-secret.yaml -n team-hotdrink
	oc create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/colddrink-secret.yaml -n team-colddrink
	```

4. Lets deploy CPX now;
	```
	oc create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/cpx.yaml -n tier-2-adc
	```

5. Deploy the VPX ingress and Citrix ingress controller to configure tier 1 ADC VPX automatically

	```
	wget https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/ingress_vpx.yaml
	wget https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/cic_vpx.yaml
	```

	Update  ingress_vpx.yaml and cic_vpx.yaml with following configuration

	Go to ``ingress_vpx.yaml`` and change the IP address of ``ingress.citrix.com/frontend-ip: "x.x.x.x"`` annotation to one of the free IP which will act as content switching vserver for accessing microservices.
	e.g. ``ingress.citrix.com/frontend-ip: "10.105.158.160"``

	Go to ``cic_vpx.yaml`` and change the NS_IP value to your VPX NS_IP.         
	    *  ``- name: "NS_IP"
	        value: "x.x.x.x"``
	    *  Update VPX crednetails in cic_vpx.yaml file 

	Now execute the following commands after the above change.
	```
	oc create -f ingress_vpx.yaml -n tier-2-adc
	oc create -f cic_vpx.yaml -n tier-2-adc
	```

## Section C (Configure GSLB sites in Tier 1 ADC)

1. Login into one Citrix ADC - VPX used infront of On-prem Kubernetes cluster and set the following command using CLI.
```
add gslb site k8s-gslb-site <SNIP of local VPX> -publicIP <SNIP of local VPX>
add gslb site oc-gslb-site <SNIP of remote VPX> -publicIP <SNIP of remote VPX>

```
**Note:** VPX infront of K8s cluster acts as Local GSLB site & VPX infront of OpenShift cluster acts as Remote GSLB site.


2. Login into one Citrix ADC - VPX used infront of On-prem OpenShift cluster and set the following command using CLI.
```
add gslb site oc-gslb-site <SNIP of local VPX> -publicIP <SNIP of local VPX>
add gslb site k8s-gslb-site <SNIP of remote VPX> -publicIP <SNIP of remote VPX>

```
**Note:** VPX infront of OpenShift cluster acts as Local GSLB site & VPX infront of Kubernetes cluster acts as Remote GSLB site.

3. Make one of the Citrix ADC- VPX as your GSLB primary device using following command. Run this command in VPX which will act as your primary GSLB device.
```
set gslb parameter -AutomaticConfigSync ENABLED
```

## Section D (Deploy Multi-cluster Ingress to achieve GSLB)

1. Create the RBAC permissions required to deploy the GSLB controller

**Note:** Deploy this command in both Kubernetes and OpenShift clusters.
```
kubectl create -f gslb-rbac.yaml
```
We will deploy GSLB controller and GSLB CRDs in default namespace for this demo however there is no restriction on any namspace based deployment.

2. Create the secrets required for the GSLB controller to connect to GSLB devices and push the configuration from the GSLB controller

Each VPX must have 2 secrets one for each VPX login. ``nsk8svpx`` is VPX login secret for VPX infront on On-prem K8s cluster and ``nsocvpx`` is VPX login secret for VPX infront of OpenShift cluster.

**Note:** Deploy this command in both Kubernetes and OpenShift clusters.

```
kubectl create secret generic nsk8svpx --from-literal=username=<username> --from-literal=password=<password>
kubectl create secret generic nsocvpx --from-literal=username=<username> --from-literal=password=<password>
```

3. Deploy GSLB controller to push the GSLB config on ADCs.

**Note:** Deploy this command in both Kubernetes and OpenShift clusters.

```
wget gslb-controller.yaml
```

Update ``gslb-controller.yaml`` manifest with below changes to be deployed in **Kubernetes cluster**

* ``LOCAL_REGION`` and ``LOCAL_CLUSTER`` Specify the region and cluster name where this controller is deployed. Region value is of your choice, LOCAL_CLUSTER is value of GSLB local site name which is ``k8s-gslb-site`` in this demo.
* ``site1_ip`` is the SNIP IP of VPX frontending Kubernetes cluster
* ``site1_region`` keep it same as ``LOCAL_REGION`` value
* ``site1_username`` and ``site1_password`` will be ``nsk8svpx`` secret created above for VPX frontending Kubernetes cluster
* ``site2_ip`` is the SNIP IP of the VPX frontending OpenShift cluster
* ``site2_region`` is the region where OpenShift cluster is deployed.
* ``site2_username`` and ``site2_password`` will be ``nsocvpx`` secret created above for VPX frontending OpenShift cluster

Here is the sample manifest of gslb-controller.yaml deployed in my Kubernetes cluster.
```

```

Now, deploy ``gslb-controller.yaml`` in your Kubernetes cluster

```
kubectl create -f gslb-controller.yaml
```


Update ``gslb-controller.yaml`` manifest with below changes to be deployed in **OpenShift cluster**

* ``LOCAL_REGION`` and ``LOCAL_CLUSTER`` Specify the region and cluster name where this controller is deployed. Region value is of your choice, LOCAL_CLUSTER is value of GSLB local site name which is ``oc-gslb-site`` in this demo.
* ``site1_ip`` is the SNIP IP of VPX frontending OpenShift cluster
* ``site1_region`` keep it same as ``LOCAL_REGION`` value
* ``site1_username`` and ``site1_password`` will be ``nsocvpx`` secret created above for VPX frontending OpenShift cluster
* ``site2_ip`` is the SNIP IP of the VPX frontending Kubernetes cluster
* ``site2_region`` is the region where Kubernetes cluster is deployed.
* ``site2_username`` and ``site2_password`` will be ``nsk8svpx`` secret created above for VPX frontending Kubernetes cluster

Here is the sample manifest of gslb-controller.yaml deployed in my OpenShift cluster.
```

```

Now, deploy ``gslb-controller.yaml`` in your OpenShift cluster

```
kubectl create -f gslb-controller.yaml
```

4. Deploy CRDs required to make GSLB deployment

**Note:** Deploy this command in both Kubernetes and OpenShift clusters.
```
kubectl create -f 
kubectl create -f
```

5. Lets create GSLB load balanicng rules using GTP instance

**Note:** Deploy this command in both Kubernetes and OpenShift clusters.

```
kubectl create -f 
```

In this example, we have created GTP instance for hotdrink beverage application. where Round robin LB method is selected to load balance hotdrink app across K8s and OpenShift clusters. You need one GTP instance per application.