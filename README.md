
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
  * [Deploy a Citrix ADC CPX proxy in docker](https://github.com/citrix/cloud-native-getting-started/blob/master/beginners-guide/cpx-in-docker.md)
  * [Citrix Ingress Controller (CIC) deployment modes in K8s cluster](https://github.com/citrix/cloud-native-getting-started/blob/master/beginners-guide/cic-in-k8s.md)
  * [Deploy Citrix ADC CPX in Minikube](https://github.com/citrix/cloud-native-getting-started/blob/master/beginners-guide/cpx-in-minikube.md)
  * [Deploy Ingress proxy - CPX on NodePort](https://github.com/citrix/cloud-native-getting-started/blob/master/beginners-guide/North-South-cpx-ingress-proxy.md)
  * [Deploy Citrix ADC CPX as East-West proxy without sideacar proxy](https://github.com/citrix/cloud-native-getting-started/blob/master/beginners-guide/East-West-cpx-ingress-proxy.md)
  * [Deployment modes for Citrix ADC CPX](https://github.com/citrix/cloud-native-getting-started/blob/master/beginners-guide/k8s-features-deepdive-using-cpx.md)
  * [Update Citrix Ingress Controller logging using ConfigMap](https://github.com/citrix/cloud-native-getting-started/blob/master/beginners-guide/configmap-for-loglevels.md)

* Citrix Cloud Native Advanced Guides
  * Azure
    * [Citrix ADC VPX & Ingress Controller as External LoadBalancer/Ingress for Azure Kubernetes Service](/azure/unified-ingress)
    * [Citrix ADC CPX & Ingress Controller for Azure Kubernetes Service](/azure/marketplace-cpx)
  * [GCP (Google Cloud Platform)](https://github.com/citrix/example-cpx-vpx-for-kubernetes-2-tier-microservices/edit/master/gcp)
  * On-Prem (using VMs on Xenserver)
    * [Unified Ingress topology: Tier 1 ADC - MPX/BLX/VPX to load balance microservice applications (North-South traffic)](https://github.com/citrix/cloud-native-getting-started/tree/master/on-prem/Unified-Ingress)
    * [2-Tier Ingress topology: Tier 1 ADC - MPX/BLX/VPX & Tier 2 ADC - CPX to load balance microservice applications (North-South traffic)](https://github.com/citrix/cloud-native-getting-started/tree/master/on-prem/2-Tier-deployment)
    * [Service mesh Lite topology: Tier 1 ADC - MPX/BLX/VPX & Tier 2 ADC - CPX to load balance microservice applications (North-South as well as East-West traffic)](https://github.com/citrix/example-cpx-vpx-for-kubernetes-2-tier-microservices/edit/master/on-prem)
    * [Citrix Observability Exporter to troubleshoot microservices using Grafana, Kibana monitoring tools](https://github.com/citrix/cloud-native-getting-started/blob/master/on-prem/ServiceMeshLite/coe/README.md)
    * [API gateway use cases: Tier 1 ADC - MPX/BLX/VPX or Tier 2 ADC - CPX to provide Rate limit, Basic Auth, Content routing, IP filtering use cases](https://github.com/citrix/cloud-native-getting-started/tree/master/on-prem/ServiceMeshLite/API-gateway)
    * [Configure WAF policies on Tier 1 ADC VPX in Unified Ingress deployment](https://github.com/citrix/cloud-native-getting-started/tree/master/on-prem/Unified-Ingress#section-e-configure-waf-policies-on-vpx-using-waf-crds)

  * OpenShift (Red Hat Enterprise Linux VMs on xenserver)
    * [Service mesh lite using Ingress rules](https://github.com/citrix/example-cpx-vpx-for-kubernetes-2-tier-microservices/tree/master/openshift)
    * [Unified Ingress using OpenShift routes and route sharding](https://github.com/citrix/example-cpx-vpx-for-kubernetes-2-tier-microservices/tree/master/openshift/openshift-routes)

* Cloud Native stack for Sock Shop application
    * [Deploy Socks Shop microservice application using Citrix ADC](https://github.com/citrix/cloud-native-getting-started/tree/master/on-prem/ServiceMeshLite/sock-shop)

## Contact Us

Looking to get started or take the next step in your app modernization? Our team is now offering free consultations! Send an email to appmodernization@citrix.com to schedule your session, and a specialist will promptly reply with options to connect.

![CN-emailID.png](/VPX/images/CN-emailID.png)

