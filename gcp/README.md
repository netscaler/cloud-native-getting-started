# Citrix ADC CPX, Citrix Ingress Controller, and Application Delivery Management on Google Cloud

## Citrix product overview for GCP K8's architecture and components

## The five major Citrix components of GCP

1. **Citrix ADC VPX as tier 1 ADC for ingress-based internet client traffic.**

    A VPX instance in GCP enables you to take advantage of GCP computing capabilities and use Citrix load balancing and traffic management features for your business needs. You can deploy VPX instances in GCP as standalone instances. Both single and multiple network interface card (NIC) configurations are supported.

2. **The Kubernetes cluster using Google Kubernetes Engine (GKE) to form the container platform.**

    Kubernetes Engine is a managed, production-ready environment for deploying containerized applications. It enables rapid application development and iteration by making it simple to deploy, update, and manage your applications and services.

3. **Deploy a sample Citrix web application using the YAML file library.**

    Citrix has provided a sample microservice web application to test the two-tier application topology on GCP. We have also included the following components in the sample files for the proof of concept:

    - Sample Hotdrink Web Service in Kubernetes YAML file
    - Sample Colddrink Web Service in Kubernetes YAML file
    - Sample Guestbook Web Service in Kubernetes YAML file
    - Sample Grafana Charting Service in Kubernetes YAML file
    - Sample Prometheus Logging Service in Kubernetes YAML file

    ![GCP](./media/cpx-ingress-image11.png)

4. **Deploy the Citrix ingress controller for tier 1 Citrix ADC automation into the GKE cluster.**

    The Citrix ingress controller built around Kubernetes automatically configures one or more Citrix ADC based on ingress resource configuration. An ingress controller is a controller that watches the Kubernetes API server for updates to the ingress resource and reconfigures the ingress load balancer accordingly. The Citrix ingress controller can be deployed either by directly using YAML files or by Helm Charts.

    ![GCP](./media/cpx-ingress-image17a.png)


    Citrix has provided sample YAML files for the Citrix ingress controller automation of the tier 1 VPX instance. The files automate several configurations on the tier 1 VPX including:

    - Rewrite Polices and Actions
    - Responder Polices and Actions
    - Contents Switching URL rules
    - Adding/Removing CPX Load Balancing Services

## Two-tier ingress deployment on GCP

In a dual-tier ingress deployment, deploy Citrix ADC VPX/MPX outside the Kubernetes cluster (Tier 1) and Citrix ADC CPXs inside the Kubernetes cluster (Tier 2).

The tier 1 VPX/MPX would load balance the tier 2 CPX inside the Kubernetes cluster. This is a generic deployment model followed widely irrespective of the platform, whether it's Google Cloud, Amazon Web Services, Azure, or an on-premises deployment.

## Automation of the tier 1 VPX/MPX

The tier 1 VPX/MPX automatically load balances the tier 2 CPXs. Citrix ingress controller completes the automation configurations by running as a pod inside the Kubernetes cluster. It configures a separate ingress class for the tier 1 VPX/MPX so that the configuration does not overlap with other ingress resources.

![GCP](./media/cpx-ingress-image1-1.png)

---

## Citrix deployment overview

## Install and configure the tier 1 Citrix ADC on GCP

One can deploy Citrix ADC by using anyone of the two ways

1. Google Cloud Platform GUI: For information on configuring the tier 1 Citrix ADC on Google Cloud Platform through GUI, see [Deploy a Citrix ADC VPX instance](https://docs.citrix.com/en-us/netscaler/12-1/deploying-vpx/deploy-vpx-google-cloud.html).

2. Google Deployment Manager: For information on configuring the tier 1 Citrix ADC on Google Cloud Platform through GDM templates, see [Deploy a Citrix ADC VPX instance using GDM templates](https://github.com/citrix/citrix-adc-gdm-templates).
   
Now we are going to deploy Citrix VPX (tier-1-adc) using 3-NIC GDM template.

**Prerequisites(Mandatory)**

1. Create GCP account using your Citrix mail id only http://console.cloud.google.com
2. Create **cnn-selab-atl** as project name on GCP console as shown below : 

![GCP](./media/cpx-ingress-image1-2.png)
3. Install the “gcloud” utility on your device. You can find the utility at this link: https://cloud.google.com/sdk/install

4. Run the following command on the gcloud utility to create an image.

    ```
    gcloud compute images create netscaler12-1 --source-uri=gs://tme-cpx-storage/NSVPX-GCP-12.1-50.28_nc.tar.gz --guest-os-features=MULTI_IP_SUBNET
    ```
    It might take a moment for the image to be created. After the image is created, it appears under Compute > Compute Engine in the GCP console.

5. Download or Clone the files which consists of tier-1-adc automated files and application yaml files from below URL
   https://github.com/citrix/example-cpx-vpx-for-kubernetes-2-tier-microservices/tree/master/gcp/config-files 

## Deploy a Citrix VPX (tier-1-adc) on GCP

1. **GCP VPC Instances** :
   To address the separation of the External, Internal, and DMZ networks for security purposes. We must create three NICs as shown in the following table:

    |Network|Comments|
    |:---|:---|
    |192.168.10.0/24|Management Network (vpx-snet-mgmt)|
    |172.16.10.0/24|Client Network (vpx-snet-vip)|
    |192.168.10.0/24|Server Network (vpx-snet-snip)|
    > Note:
    >
    > Build the three-arm network VPCs before you deploy any VM instances.


    From the Google console, select **Networking > VPC network > Create VPC network** and enter the required fields, as shown below , and click **Create**.

    ![GCP](./media/cpx-ingress-image1a.png)

   Similarly, create VPC networks for client and server-side NICs to create three subnets as shown below.

   **Note:** All three VPC networks should be in the same region, which is us-east1 in this scenario.

   ![GCP](./media/cpx-ingress-image1.png)

2. once you create three network and three subnets within the networks under VPC Network. Deploy the Citrix ADC VPX instance using GDM template but make sure both **configuration.yml** and
**template.py** are in same folder or directory

    Use the following command from Google SDK to deploy the instance.

     ```
     gcloud deployment-manager deployments create tier1-vpx --config configuration.yml
     ```
3. After successful deployment go to GCP Compute Engine to check the citrix-adc-tier1-vpx and validate the internal ips as shown below 

   ![GCP](./media/cpx-ingress-image2a.png)


1. The Citrix ingress controller can automate the static route configuration in the tier 1 VPX. Configure the subnet IP (SNIP) address that should be of the same subnet/virtual private cloud of the Kubernetes cluster.

    > Note:
    >
    > The tier 1 VPX/MPX deployed is going to load balance the CPXs inside the Kubernetes cluster. Configure the SNIP in the tier 1 VPX.

    Open a PuTTY session by using tier 1 VPX external traffic ip and complete the following commands to add SNIP and enable management access to it :

    ```
    add ns IP 10.10.10.20 255.255.255.0 -type SNIP
    set ns IP 10.10.10.20 mgmt enabled
    enable ns mode mbf
    ```

---

## Deploy a Kubernetes cluster using GKE 

One can deploy Kubernetes cluster either by ***Google Cloud SDK or through Google Cloud Platform GUI console***.

### GcloudSDK Command to create k8s cluster

```
gcloud beta container --project "cnn-selab-atl" clusters create "k8s-cluster-with-cpx" --zone "us-east1-b" --username "admin" --cluster-version "1.11.7-gke.12" --machine-type "n1-standard-1" --image-type "COS" --disk-type "pd-standard" --disk-size "100" --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "3" --enable-cloud-logging --enable-cloud-monitoring --no-enable-ip-alias --network "projects/cnn-selab-atl/global/networks/vpx-snet-snip" --subnetwork "projects/cnn-selab-atl/regions/us-east1/subnetworks/vpx-snet-snip" --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair
```

### Google Cloud Platform GUI Steps

1. Search for a Kubernetes Engine on GCP Console and click **Create Cluster**.

    ![GCP](./media/cpx-ingress-image6.png)

1. Create a cluster in the same subnet where your VPX SNIP is (vpx-snet-snip). This cluster automates a configuration push into the tier 1 ADC from Citrix ingress controller in the K8s cluster.

    ![GCP](./media/cpx-ingress-image7.png)

    ![GCP](./media/cpx-ingress-image8.png)

1. Click **Advanced options** to change the subnet to `vpx-snet-snip` and select the following fields.

    ![GCP](./media/cpx-ingress-image9.png)

1. To access this cluster from the cloud SDK, click the Kubernetes **Connect to the cluster** button and paste the command in the cloud SDK.

    ![GCP](./media/cpx-ingress-image10.png)

1. Validate the GKE Cluster deplyment by running the below command to see the nodes as shown below 
    ```
    kubectl get nodes
    ```
    ![GCP](./media/cpx-ingress-image13.png)
---

## Deploy a sample application using the sample YAML file library

Citrix ADC offers the two-tier architecture deployment solution to load balance the enterprise grade applications deployed in microservices and accessed through the Internet. Tier 1 has heavy load balancers such as VPX/SDX/MPX to load balance North-South traffic. Tier 2 has CPX deployment for managing microservices and load balances East-West traffic.

1. If you are running your cluster in GKE, then ensure that you have used cluster role binding to configure a cluster-admin. You can do that using the following command.

    ```
    kubectl create clusterrolebinding citrix-cluster-admin --clusterrole=cluster-admin --user=<email-id of your google account>.
    ```

1.  Access the current directory where you have the deployment YAML files,use the following command to get the node status.

    ```
    kubectl get nodes
    ```

    ![GCP](./media/cpx-ingress-image13.png)

1. Create the namespaces 

   ```
   kubectl create -f namespace.yaml  
    ```

    Verify the namespaces by below command:

    ```
    kubectl get namespaces
    ```

    ![GCP](./media/cpx-ingress-image14.png)

1. Deploy the rbac.yaml in default namespace.

   ```
   kubectl create -f rbac.yaml
   ```

1. Deploy a CPX for hotdrink, colddrink, and guestbook microservices using the following commands.

    ```
    kubectl create -f cpx.yaml -n tier-2-adc
    kubectl create -f hotdrink-secret.yaml -n tier-2-adc
    ```

1. Deploy hotdrink beverage microservices, a SSL type microservice with hair-pin architecture

    ```
    kubectl create -f team_hotdrink.yaml -n team-hotdrink
    kubectl create -f hotdrink-secret.yaml -n team-hotdrink
    ```

1. Deploy colddrink beverage microservice, a SSL_TCP type microservice

    ```
    kubectl create -f team_colddrink.yaml -n team-colddrink
    kubectl create -f colddrink-secret.yaml -n team-colddrink
    ```

1. Deploy guestbook, a NoSQL type microservice.

    ```
    kubectl create -f team_guestbook.yaml -n team-guestbook
    ```
1. Validate the CPX deployed for above three applications, first get the cpx pods deployed as tier-2-adc and than CLI access to cpx

   ```
   1. To get CPX pods in tier-2-adc namespace:
   kubectl get pods -n tier-2-adc

   2.To get CLI access(bash) to the cpx pod suppose hotdrinks-cpx pod:
   kubectl exec -it "copy and paste hotdrink cpx pod name from above step" bash -n tier-2-adc
   like
   kubectl exec -it cpx-ingress-hotdrinks-768b674f76-pcnw4 bash -n tier-2-adc  

   3.To check the CS vserver is up or not in hotdrink-cpx , run below command after root access to cpx:
   cli-script"sh csvs"
   like
   root@cpx-ingress-hotdrinks-768b674f76-pcnw4:/# cli_script.sh "sh csvs"
   ```


1. Deploy the VPX ingress and ingress controller to the tier 2 namespace, which configures VPX automatically.

    **Here we are going to deploy Citrix Ingress Controller(CIC) which automates the tier-1-adc(VPX)**

    ```
    kubectl create -f ingress_vpx.yaml -n tier-2-adc
    kubectl create -f cic_vpx.yaml -n tier-2-adc
    ```

1. Deploy Cloud Native Computing Foundation (CNCF) monitoring tools such as Prometheus and Grafana to collect ADC proxy stats.

    ```
    kubectl create -f monitoring.yaml -n monitoring
    kubectl create -f ingress_vpx_monitoring.yaml -n monitoring
    ```

1. Add the DNS entries in your local machine's host files for accessing microservices through the Internet.

    For Windows Clients, go to **C:\Windows\System32\drivers\etc\hosts**

    For macOS Clients, in the Terminal, enter `sudo nano /etc/hosts`.

    Add the following entries in the host's file and save the file.

    ```
    hotdrink.beverages.com     xxx.xxx.xxx.xxx (static-external-traffic-ip-tier1-vpx)
    colddrink.beverages.com    xxx.xxx.xxx.xxx (static-external-traffic-ip-tier1-vpx)
    guestbook.beverages.com    xxx.xxx.xxx.xxx (static-external-traffic-ip-tier1-vpx )
    grafana.beverages.com      xxx.xxx.xxx.xxx (static-external-traffic-ip-tier1-vpx)
    prometheus.beverages.com   xxx.xxx.xxx.xxx (static-external-traffic-ip-tier1-vpx)
    ```

1. Now you can access each application over the Internet. For example,

    `https://hotdrink.beverages.com`

     ![GCP](./media/cpx-ingress-image14a.png)

---
## Enable  Rewrite-Responder for above Sample Application ## 

Now it's time to push rewrite responder policies on VPX through CRD (Custon Resource Definition) 

1. Deploy the CRD to push rewrite responder policies in to tier-1-adc in default namespace
   ```
   kubectl create -f crd_rewrite_responder.yaml
   ```
1. Configure Responder policy on hotdrink.beverages.com to block access to coffee page
   ```
   kubectl create -f responderpolicy_hotdrink.yaml -n tier-2-adc
   ```
   Once you deploy responder policy ,access coffee page on hotdrink.beverages.com than you will get message as shown below

   ![GCP](./media/cpx-ingress-image16a.png)

1. Configure Rewrite policy on colddrink.beverages.com to insert session-id in header
   ```
   kubectl create -f rewritepolicy_colddrink.yaml -n tier-2-adc
   ```
   Once you deploy rewrite policy, access colddrink.beverages.com with developer mode enabled on browser (press F12 in chrome) and preserve the log in network category to see the session id which is inserted by rewrite policy on tier-1-adc(VPX)

   ![GCP](./media/cpx-ingress-image16b.png)
---
## Open Source Tool sets

***Prometheus log aggregator***

1. Log in to `http://grafana.beverages.com` and complete the following one-time setup.

    1. Log in to the portal using administrator credentials.
    1. Click **Add data source** and select the **Prometheus** data source.
    1. Configure the following settings and click the **Save and test** button.

    ![GCP](./media/cpx-ingress-image15.png)

    ***Grafana Visual Dashboard***
1. From the left panel, select the **Import** option and upload the `grafana_config.json` file provided in the `yamlFiles` folder. Now you can see the Grafana dashboard with basic ADC stats listed.

    ![GCP](./media/cpx-ingress-image16.png)

---

## Tear down the deployment 

To tear down the deployed setup please execute below steps

1. To tear down Citrix VPX (tier-1-adc) , go to Google SDK CLI console to delete the instance
    ```
    gcloud deployment-manager deployments delete tier1-vpx
    ```
1. To tear down GKE kubernentes cluster go to GCP console, select kubernetes cluster and click on delete icon to erase the cluster. 
   
    ![GCP](./media/cpx-ingress-image16c.png)

---

