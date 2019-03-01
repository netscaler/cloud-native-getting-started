## Learn how to use Citrix ADC in two tier microservices architecture


Citrix ADC offers the two-tier architecture deployment solution to load balance the enterprise grade applications deployed in microservices and access those through internet. Tier 1 can have traditional load balancers such as VPX/SDX/MPX, or CPX (containerized Citrix ADC) to manage high scale north-south traffic. Tier 2 has CPX deployment for managing microservices and load balances the north-south & east-west traffic.

![2tierarchitecture](https://user-images.githubusercontent.com/5059506/52114542-518e2080-2632-11e9-8d17-eb0b5623b74f.png)


In the Kubernetes cluster, pod gets deployed across worker nodes. Below screenshot demonstrates the microservice deployment which contains 3 services marked in blue, red and green colour and 12 pods running across two worker nodes. These deployments are logically categorized by Kubenetes namespace (e.g. team-hotdrink namespace)

![hotdrinknamespacek8s](https://user-images.githubusercontent.com/42699135/50677395-99179180-101f-11e9-93f0-566cf179ce25.png)

Here are the detailed demo steps in cloud native infrastructure which offers the tier 1 and tier 2 seamless integration along with automation of proxy configuration using yaml files. 

1.	Bring your own nodes (BYON)
Kubernetes is an open-source system for automating deployment, scaling, and management of containerized applications. Please install and configure Kubernetes cluster with one master node and at least two worker node deployment.
Recommended OS: Ubuntu 16.04 desktop/server OS. 
Visit: https://kubernetes.io/docs/setup/scratch/ for Kubernetes cluster deployment guide.
Once Kubernetes cluster is up and running, execute the below command on master node to get the node status.
``` 
kubectl get nodes
```
 ![getnodes](https://user-images.githubusercontent.com/42699135/50677393-987efb00-101f-11e9-8580-4d27746bb96a.png)
 (Screenshot above has Kubernetes cluster with one master and two worker node).

2.	Set up a Kubernetes dashboard for deploying containerized applications.
Please visit https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/ and follow the steps mentioned to bring the Kubernetes dashboard up as shown below.

![k8sdashboard](https://user-images.githubusercontent.com/42699135/50677396-99179180-101f-11e9-95a4-1d9aa1b9051b.png)
 
3.	Create a namespaces using Kubernetes master CLI console.
```
kubectl create namespace tier-2-adc
kubectl create namespace team-hotdrink
kubectl create namespace team-colddrink
kubectl create namespace team-guestbook
kubectl create namespace monitoring
```
Once you execute above commands, you should see the output given in below screenshot using command: 
```
kubectl get namespaces
```
![getnamespace](https://user-images.githubusercontent.com/42699135/50677390-97e66480-101f-11e9-9a69-cc132407bd1e.png)

4.	Copy the yaml files from ``/example-cpx-vpx-for-kubernetes-2-tier-microservices/config/`` to master node in ``/root/yamls directory``

5.	Go to Kubenetes dashboard and deploy the ``rbac.yaml`` in the default namespace
```
kubectl create -f /root/yamls/rbac.yaml 
```

6.	Deploy the CPX for hotdrink, colddrink and guestbook microservices using following commands,

**Pre-Requsites:** 
Citrix CPX deployment requires "image pull secrets" to download the CPX image.
For generating new imagePullsecret, please raise a request to Citrix Slack. 

Update the Secret provided by Citrix: 
Update the ".dockerconfigjson" field under secret in CPX.yaml


```
kubectl create -f /root/yamls/cpx-svcacct.yaml -n tier-2-adc
kubectl create -f /root/yamls/cpx.yaml -n tier-2-adc
kubectl create -f /root/yamls/hotdrink-secret.yaml -n tier-2-adc
```

7.	Deploy the three types of hotdrink beverage microservices using following commands
```
kubectl create -f /root/yamls/team_hotdrink.yaml -n team-hotdrink
kubectl create -f /root/yamls/hotdrink-secret.yaml -n team-hotdrink
```

8.	Deploy the colddrink beverage microservice using following commands
```
kubectl create -f /root/yamls/team_colddrink.yaml -n team-colddrink
kubectl create -f /root/yamls/colddrink-secret.yaml -n team-colddrink
```

9.	Deploy the guestbook no sql type microservice using following commands
```
kubectl create -f /root/yamls/team_guestbook.yaml -n team-guestbook
```
10.	Login to Tier 1 ADC (VPX/SDX/MPX appliance) to verify no configuration is present before we automate the Tier 1 ADC.

11.	Deploy the VPX ingress and ingress controller to push the CPX configuration into the tier 1 ADC automatically.
**Note:-** 
Go to ``ingress_vpx.yaml`` and change the IP address of ``ingress.citrix.com/frontend-ip: "x.x.x.x"`` annotation to one of the free IP which will act as content switching vserver for accessing microservices.
e.g. ``ingress.citrix.com/frontend-ip: "10.105.158.160"``
Go to ``cic_vpx.yaml`` and change the NS_IP value to your VPX NS_IP.         
``- name: "NS_IP"
  value: "x.x.x.x"``
Now execute the following commands after the above change.
```
kubectl create -f /root/yamls/ingress_vpx.yaml -n tier-2-adc
kubectl create -f /root/yamls/cic_vpx.yaml -n tier-2-adc
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
e.g. ``ingress.citrix.com/frontend-ip: "10.105.158.161"``
```
kubectl create -f /root/yamls/monitoring.yaml -n monitoring
kubectl create -f /root/yamls/ingress_vpx_monitoring.yaml -n monitoring
```

15.	Add the DNS entries in your local machine host files for accessing monitoring portals though internet.
Path for host file: ``C:\Windows\System32\drivers\etc\hosts``
Add below entries in hosts file and save the file
```
<frontend-ip from ingress_vpx_monitoring.yaml> grafana.beverages.com
<frontend-ip from ingress_vpx_monitoring.yaml> prometheus.beverages.com
```
16.	Login to ``http://grafana.beverages.com`` and do the following one time setup
Login to portal using admin/admin credentials.
Click on Add data source and select the Prometheus data source. Do the settings as shown below and click on save & test button.
 
 ![grafana_webpage](https://user-images.githubusercontent.com/42699135/50677392-987efb00-101f-11e9-993a-cb1b65dd96cf.png)
 
From the left panel, select import option and upload the json file provided in folder yamlFiles ``/example-cpx-vpx-for-kubernetes-2-tier-microservices/config/grafana_config.json``
Now you can see the Grafana dashboard with basic ADC stats listed.
 
 ![grafana_stats](https://user-images.githubusercontent.com/42699135/50677391-97e66480-101f-11e9-8d42-87c4a2504a96.png)

Citrix ADC solution supports the load balancing of various protocol layer traffic such as SSL,  SSL_TCP, HTTP, TCP. Below screenshot has listed different flavours of traffic supported by this demo.
![traffic_flow](https://user-images.githubusercontent.com/42699135/50677397-99179180-101f-11e9-8a40-26ba7d0d54e0.png)

#### How does client traffic reaches to hotdrink-beverage microservices?
Client send the traffic to Tier 1 ADC thorugh Content Switching virtual server and reaches to pods where hotdrink beverage microservices are running. Detailed traffic flow is allocated in following gif picture (please wait for a moment on gif picture to see the packet flow).
![hotdrink-packetflow-gif](https://user-images.githubusercontent.com/42699135/53620442-fd6a6200-3c18-11e9-833c-704375c7b0be.gif)
 
#### How does client traffic reaches to guestbook-beverage microservices?
Client send the traffic to Tier 1 ADC thorugh Content Switching virtual server and reaches to pods where guestbook beverage microservices are running. Detailed traffic flow is allocated in following gif picture (please wait for a moment on gif picture to see the packet flow).
![guestbook-app](https://user-images.githubusercontent.com/42699135/53620445-01967f80-3c19-11e9-838f-1d2c4bbe4d06.gif)
