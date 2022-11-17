  
# Citrix Cloud Native Networking (CNN) hands-on guides
**Citrix cloud-native solutions** leverage the advanced traffic management, observability, and comprehensive security features of Citrix ADCs to ensure enterprise grade reliability and security. Lets get started with CNN GitHub!

###### You’ll learn how to:
* Deploy [Citrix Ingress Controller](https://github.com/citrix/citrix-k8s-ingress-controller) for Citrix Cloud Native stack
* Deploy Citrix ADC containerized proxy - CPX
* Deploy Citrix Cloud native stack in different K8s platforms (On-prem, OpenShift, Rancher, EKS, AKS, GKE, PKS)
* Deploy Citrix Cloud native stack for 
  * Unified Ingress topology
  * Two tier topology
  * Service Mesh lite topology
  * ISTIO: Service Mesh topology

## Getting Started
Here are very cool hands-on guides for you to understand Citrix Cloud Native portfolio
* Citrix Cloud Native Beginners Guides
  * [Deploy a Citrix ADC CPX proxy in docker](/beginners-guide/cpx-in-docker.md)
  * [Citrix Ingress Controller (CIC) deployment modes in K8s cluster](/beginners-guide/cic-in-k8s.md)
  * [Deploy Citrix ADC CPX in Minikube](/beginners-guide/cpx-in-minikube.md)
  * [Deploy Ingress proxy - CPX on NodePort](/beginners-guide/North-South-cpx-ingress-proxy.md)
  * [Deploy Citrix ADC CPX as East-West proxy without sideacar proxy](/beginners-guide/East-West-cpx-ingress-proxy.md)
  * [Deployment modes for Citrix ADC CPX](/beginners-guide/CPX-deployment-modes.md)
  * [Update Citrix Ingress Controller logging using ConfigMap](/beginners-guide/configmap-for-loglevels.md)
  * [Deploy Citrix Observability exporter in K8s for sending metrics to Prometheus](/beginners-guide/tier1-prometheus-coe.md)

* Citrix Cloud Native Advanced Guides
  * Azure
    * [Citrix ADC VPX & Ingress Controller as External LoadBalancer/Ingress for Azure Kubernetes Service](/azure/unified-ingress/README.md)
    * [Citrix ADC CPX & Ingress Controller for Azure Kubernetes Service](/azure/marketplace-cpx/README.md)
  * GCP (Google Cloud Platform)
    * [Two-Tier deployment with Citrix ADC VPX, Citrix Ingress Controller, Citrix ADC CPX and Application Delivery Management(ADM) on Google Cloud](/gcp/two-tier-vpc-cpx-adm/README.md)
    * [Citrix ADC with Google Anthos: Autoscaling Lab](/gcp/anthos/scaleup/README.md)
    * [Citrix ADC with Google Anthos: WAF with Policy Controller Lab](/gcp/anthos/waf/README.md)
    * [Citrix ADC with Google Anthos: Dual-tier API Gateway with ACM Lab](/gcp/anthos/apigw/README.md)
    * [Citrix ADC with GKE: ADC CPX for Service Mesh Lite](/gcp/sml/README.md)
  * On-Prem (using VMs on Xenserver)
    * [Unified Ingress topology: Tier 1 ADC - MPX/BLX/VPX to load balance microservice applications (North-South traffic)](/on-prem/Unified-Ingress/README.md)
    * [2-Tier Ingress topology: Tier 1 ADC - MPX/BLX/VPX & Tier 2 ADC - CPX to load balance microservice applications (North-South traffic)](/on-prem/2-Tier-deployment/README.md)
    * [Service mesh Lite topology: Tier 1 ADC - MPX/BLX/VPX & Tier 2 ADC - CPX to load balance microservice applications (North-South as well as East-West traffic)](/on-prem/README.md)
    * [Citrix Observability Exporter to troubleshoot microservices using Grafana, Kibana monitoring tools](/on-prem/ServiceMeshLite/coe/README.md)
    * [API gateway use cases: Tier 1 ADC - MPX/BLX/VPX or Tier 2 ADC - CPX to provide Rate limit, Basic Auth, Content routing, IP filtering use cases](/on-prem/ServiceMeshLite/API-gateway/README.md)
    * [Configure WAF policies on Tier 1 ADC VPX in Unified Ingress deployment](/on-prem/Unified-Ingress/README.md#section-e-configure-waf-policies-on-vpx-using-waf-crds)

  * OpenShift (Red Hat Enterprise Linux VMs on xenserver)
    * [Service mesh lite using Ingress rules](/openshift/README.md)
    * [Unified Ingress using OpenShift routes and route sharding](/openshift/openshift-routes/README.md)

* Cloud Native stack for Sock Shop application
    * [Deploy Socks Shop microservice application using Citrix ADC](/on-prem/ServiceMeshLite/sock-shop/README.md)

## Contact Us

Looking to get started or take the next step in your app modernization? Our team is now offering free consultations! Send an email to appmodernization@citrix.com to schedule your session, and a specialist will promptly reply with options to connect.

![CN-emailID.png](/VPX/images/CN-emailID.png)

