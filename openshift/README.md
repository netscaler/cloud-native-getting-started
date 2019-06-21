
Use Citrix ADC in two tier microservices architecture
=====================================================


Step by step demo
-----------------

Citrix ADC works in the two-tier architecture deployment solution to load balance the enterprise grade applications deployed in microservices and access those through internet. Tier 1 can have traditional load balancers such as VPX/SDX/MPX, or CPX (containerized Citrix ADC) to manage high scale north-south traffic. Tier 2 has CPX deployment for managing microservices and load balances the north-south & east-west traffic.

![OpenShift-2-tier-deployment](https://user-images.githubusercontent.com/48945413/59842745-c6a98a80-9374-11e9-8f1e-d1e0c7413313.PNG)


OpenShift leverages the Kubernetes concepts for microservice deployments where pods are deployed in worker nodes. Below screenshot demonstrates the microservice deployment which contains 3 services marked in blue, red and green colour and 12 pods running across two worker nodes. These deployments are logically categorized by Kubenetes namespace (e.g. team-hotdrink namespace)

![hotdrinknamespacek8s](https://user-images.githubusercontent.com/42699135/50677395-99179180-101f-11e9-93f0-566cf179ce25.png)

Here are the detailed demo steps in cloud native infrastructure which offers the tier 1 and tier 2 seamless integration along with automation of proxy configuration using yaml files. 

1.	Bring your own nodes (BYON)

Red Hat OpenShift is an container application platform based on the Kubernetes container orchestrator for enterprise application development and deployment. Please install and configure OpenShift cluster with one master node and at least one worker node deployment.

Recommended OS: Red Hat Enterprise Linux 7.6 and above 

Visit: https://docs.openshift.com/container-platform/3.11/install/running_install.html for OpenShift cluster deployment guide.
Once OpenShift cluster is up and running, execute the below command on master node to get the node status.
``` 
oc get nodes
```
![oc-nodes](https://user-images.githubusercontent.com/48945413/59844387-61f02f00-9378-11e9-836b-1a8f59e4f3b2.PNG)
 
(Screenshot above has OpenShift cluster with one master and two worker node).


**Pre-Requisites: **
Make sure that route configuration  is present in Tier 1 ADC so that Ingress NetScaler should be able to reach Kubernetes  pod network for seamless connectivity. Please refer to https://github.com/citrix/citrix-k8s-ingress-controller/blob/master/docs/network/staticrouting.md#manually-configure-route-on-the-citrix-adc-instance for Network configuration.
Note: Automatically configure route on the Citrix ADC instance will not work for Kubernetes Ingress deployment on OpenShift cluster.
 
2.	Copy the yaml files from ``/example-cpx-vpx-for-kubernetes-2-tier-microservices/openshift/Ingress-config/`` to master node in ``/root/yamls`` directory

3. By default, OpenShift prevents containers from running as root. Since our applications (beverages application) requires root privileges, we need to over-ride this restriction by running following command as “cluster-admin”

```
oc adm policy add-scc-to-group anyuid system:authenticated
```
CPX runs as a privileged container. Hence you need to add the CPX service accounts to the privileged security context.
```
oc adm policy add-scc-to-user privileged system:serviceaccount:tier-2-adc:cpx
```

4.	Create a namespace using Kubernetes master CLI console.
```
oc create -f /root/yamls/namespace.yaml
```
Once you execute above commands, you should see the output given in below screenshot using command: 
```
oc get namespaces
```
![namespace](https://user-images.githubusercontent.com/48945413/59844907-9dd7c400-9379-11e9-8373-ee32d2d2bbca.PNG)

5.	Now deploy the ``rbac.yaml`` in the default namespace for better security policies
```
oc create -f /root/yamls/rbac.yaml 
```

6.	Deploy the CPX for hotdrink, colddrink and guestbook microservices using following commands,

```
oc create -f /root/yamls/cpx-svcacct.yaml -n tier-2-adc
oc create -f /root/yamls/cpx.yaml -n tier-2-adc
oc create -f /root/yamls/hotdrink-secret.yaml -n tier-2-adc
```

7.	Deploy the three types of hotdrink beverage microservices using following commands
```
oc create -f /root/yamls/team_hotdrink.yaml -n team-hotdrink
oc create -f /root/yamls/hotdrink-secret.yaml -n team-hotdrink
```

8.	Deploy the colddrink beverage microservice using following commands
```
oc create -f /root/yamls/team_colddrink.yaml -n team-colddrink
oc create -f /root/yamls/colddrink-secret.yaml -n team-colddrink
```

9.	Deploy the guestbook no SQL type microservice using following commands
```
oc create -f /root/yamls/team_guestbook.yaml -n team-guestbook
```
10.	Login to Tier 1 ADC (VPX/SDX/MPX appliance) to verify no configuration is pushed from Citrix Ingress Controller before automating the Tier 1 ADC.

11.	Deploy the VPX ingress and ingress controller to push the CPX configuration into the tier 1 ADC automatically.
**Note: -** 
Go to ``ingress_vpx.yaml`` and change the IP address of ``ingress.citrix.com/frontend-ip: "x.x.x.x"`` annotation to one of the free IP which will act as content switching vserver for accessing microservices.
e.g. ``ingress.citrix.com/frontend-ip: "10.105.158.160"``
Go to ``cic_vpx.yaml`` and change the NS_IP value to your VPX NS_IP.         
``- name: "NS_IP"
  value: "x.x.x.x"``
Now execute the following commands after the above change.
```
oc create -f /root/yamls/ingress_vpx.yaml -n tier-2-adc
oc create -f /root/yamls/cic_vpx.yaml -n tier-2-adc
```

  
12.	Add the DNS entries in your local machine host files for accessing microservices though internet.
Path for host file: ``C:\Windows\System32\drivers\etc\hosts``
Add below entries in hosts file and save the file

```
<frontend-ip from ingress_vpx.yaml> hotdrink.beverages.com
<frontend-ip from ingress_vpx.yaml> colddrink.beverages.com
<frontend-ip from ingress_vpx.yaml> guestbook.beverages.com
```
  
13.	Now you can access your microservices over the internet.
e.g. ``https://hotdrink.beverages.com``

![hotbeverage_webpage](https://user-images.githubusercontent.com/42699135/50677394-987efb00-101f-11e9-87d1-6523b7fbe95a.png)
 
14.	Deploy the CNCF monitoring tools such as Prometheus and Grafana to collect ADC proxies’ stats. Monitoring ingress yaml will push the configuration automatically to Tier 1 ADC.
**Note:-**
Go to ``ingress_vpx_monitoring.yaml`` and change the frontend-ip address from ``ingress.citrix.com/frontend-ip: "x.x.x.x"`` annotation to one of the free IP which will act as content switching vserver Prometheus and Grafana portal or you can use the same frontend-IP used in Step 11. 
e.g. ``ingress.citrix.com/frontend-ip: "10.105.158.160"``
```
oc create -f /root/yamls/monitoring.yaml -n monitoring
oc create -f /root/yamls/ingress_vpx_monitoring.yaml -n monitoring
```

15.	Add the DNS entries in your local machine host files for accessing monitoring portals though internet.
Path for host file: ``C:\Windows\System32\drivers\etc\hosts``
Add below entries in hosts file and save the file
```
<frontend-ip from ingress_vpx_monitoring.yaml> grafana.beverages.com
<frontend-ip from ingress_vpx_monitoring.yaml> prometheus.beverages.com
```
16.	Login to ``http://grafana.beverages.com:8080`` and do the following one-time setup
Login to portal using admin/admin credentials.
Click on Add data source and select the Prometheus data source. Do the settings as shown below and click on save & test button.
 
 ![grafana_webpage](https://user-images.githubusercontent.com/42699135/50677392-987efb00-101f-11e9-993a-cb1b65dd96cf.png)
 
From the left panel, select import option and upload the json file provided in folder yamlFiles ``/example-cpx-vpx-for-kubernetes-2-tier-microservices/config/grafana_config.json``
Now you can see the Grafana dashboard with basic ADC stats listed.
 
 ![grafana_stats](https://user-images.githubusercontent.com/42699135/50677391-97e66480-101f-11e9-8d42-87c4a2504a96.png)


## Configure Rewrite and Responder policies in Tier 1 ADC using Kubernetes CRD deployment

Now it's time to push the Rewrite and Responder policies on Tier1 ADC (VPX) using the custom resource definition (CRD).

1. Deploy the CRD to push the Rewrite and Responder policies in to tier-1-adc in default namespace.

   ```
   oc create -f /root/yamls/crd_rewrite_responder.yaml
   ```

1. **UseCase: Blacklist URLs** Configure the Responder policy on `hotdrink.beverages.com` to block access to the coffee beverage microservice.

   ```
   oc create -f /root/yamls/responderpolicy_hotdrink.yaml -n tier-2-adc
   ```

   After you deploy the Responder policy, access the coffee page on `https://hotdrink.beverages.com/coffee.php`. Then you receive the following message.
   
   ![cpx-ingress-image16a](https://user-images.githubusercontent.com/48945413/55129538-7f2cad00-513d-11e9-9191-72a385fad377.png)

1. **UseCase: Header insertion** Configure the Rewrite policy on `https://colddrink.beverages.com` to insert the session ID in the header.

   ```
   oc create -f /root/yamls/rewritepolicy_colddrink.yaml -n tier-2-adc
   ```

   After you deploy the Rewrite policy, access `colddrink.beverages.com` with developer mode enabled on the browser. In Chrome, press F12 and preserve the log in network category to see the session ID, which is inserted by the Rewrite policy on tier-1-adc (VPX).

   ![cpx-ingress-image16b](https://user-images.githubusercontent.com/48945413/55129567-9075b980-513d-11e9-9926-d1207d7d1e16.png)

---

### Packet Flow Diagrams
--------------------

Citrix ADC solution supports the load balancing of various protocol layer traffic such as SSL,  SSL_TCP, HTTP, TCP. Below screenshot has listed different flavours of traffic supported by this demo.
![traffic_flow](https://user-images.githubusercontent.com/42699135/50677397-99179180-101f-11e9-8a40-26ba7d0d54e0.png)

