## WAF Use Case
This use case focuses on deploying a Tier-1 Citrix ADC (VPX) in front of a Google Anthos GKE cluster within GCP. It leverages Google Anthos Configuration Management for consistent deployment of the Citrix components into the Anthos GKE cluster. It leverages Google Anthos Policy Controller to ensure that Citrix WAF configurations exist to protect ingress objects within a cluster. 

ACM (Anthos Configuration Management) is a GitOps centric tool that synchronizes configuration into a Anthos Kubernetes cluster from a Git repository. Policy Controller is a component of ACM that can audit or enforce configurations across the cluster. This lab automation has been written with [GitHub](https://github.com) as the git repository tool of choice. 

**Note** 
The infrastructure code contained herein is intended to function in a way that suits demonstrations or proof of concepts, but is not hardened or designed for production deployment scenarios. 

## Architecture
The following diagram illustrates the infrastructure that is deployed for this use case.  
![](assets/platform.png)
  
**Citrix Netscaler VPX**  
A single Citrix Netscaler VPX instance is deployed with 2 network interfaces:  
- nic0 provides access for management (NSIP), and access to back end servers (SNIP)
- nic1 provides access for deployed applications (VIPs)
- each interface is assigned an internal private IP address and an external Public IP address
- the instance is deployed as a preemptible node to reduce lab costs
- the instance automatically configures the password with Terraform
- the instance is then automatically configured by the Citrix Ingress Controller and Citrix Node Controller deployed in the GKE cluster 

**VPCs and Firewall Rules**  
2 VPC's are utilized in this deployment: 
- the default VPC and subnets are used for instance and GKE cluster deployment
- the `vip-vpc` is used only to host VIP addresses which routes the traffic back to the services in the default VPC
- default firewall rules apply to the default VPC
- ports 80/443 are permitted into the `vip-vpc`

**GKE Cluster with Anthos Configuration Management**  
A single GKE cluster is deployed as a zonal cluster: 
- autoscaling is enabled with a minimum of 1 node and configurable maximum
- Google Anthos Config Management (ACM) operator is deployed into the GKE cluster and configured to sync the cluster configuration from a GitHub repository
- Citrix Ingress Controller and Citrix Node Controller components are automatically installed via ACM into the `ctx-ingress` namespace
- Citrix WAF Custom Resource Definition (CRD) is installed via ACM to enable developers to create WAF configurations
- worker nodes are deployed as preemptible nodes to reduce lab costs
- Policy Controller is installed to demonstrate constraints that enforce the presence of a WAF object in a namespace prior to accepting an Ingress resource

**GitHub Repository**  
A dedicated GitHub repository is created and loaded with a basic cluster configuration: 
- A basic [hierarchical format](https://cloud.google.com/anthos-config-management/docs/concepts/hierarchical-repo) is used for ease of navigation through namespaces and manifests
- Citrix Ingress Controller and Citrix Node Controller deployment manifests are built from templates and added to this repository, along with their required roles/rolebindings/services/etc. 
- This repository is created and destroyed by Terraform

**Online Boutique Demo Application**  
The [online boutique](https://github.com/GoogleCloudPlatform/microservices-demo) demo application provides a μServices based application for our lab. It has been modified slightly for this environment: 
- an ingress resource has been added to receive all traffic through the Citrix VPX (the standard frontend-external LoadBalancer service was removed)
- application components are controlled through Anthos Config Management and the source Git Repo

## Lab Deployment
Please refer to [lab-automation/README.md](lab-automation/README.md) for deployment details. 

## Environment Usage  
When the environment has been deployed, terraform will output two public IP addresses, one for management and one for data services. Log into the NetScaler VPX Management interface and review the configuration: 
- Navigate to **System->Network->IPs** to review the IP addresses that have been dynamically configured on the system  
![](../scaleup/assets/ns-00.png)  

- Navigate to **System->Network->VXLANS** to review the VXLAN IDs that have been dynamically configured on the system - this configuration enables the VPX to tunnel into the cluster and access the POD IP space  
![](../scaleup/assets/ns-01.png)  

- Navigate to **Traffic Management->Load Balancing->Virtual Servers** and explore the dynamically created virtual services that reside in the Google Anthos GKE cluster  
![](../scaleup/assets/ns-02.png)  

With the environment fully deployed, navigate to the [Application Demo Usage section](lab-automation/README.md) to explore the demo application. 

You can also review the Google Anthos components in the Google Cloud Console:  
- Navigate to the **Anthos** section of the Google Cloud Console to see the newly created cluster  
![](assets/anthos-00.png)  

- Select **Clusters** to see more detail about the Anthos GKE cluster that Terraform has created  
![](assets/anthos-01.png)  

- Select **Config management** to see more detail about the ACM deployment on the Anthos GKE cluster  
![](assets/anthos-02.png)  
![](assets/anthos-03.png)  

