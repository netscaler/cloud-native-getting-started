# Learn how to deploy Sock-Shop microservice application in Citrix Cloud Native Stack on Kubernetes on-prem cluster (Tier 1 ADC as Citrix ADC VPX, Tier 2 ADC as Citrix ADC CPX)

In this guide you will learn:
* What is service mesh lite deployment?
* How to deploy sock shop microservice applications without Citrix ADC
* How to insert Citrix ADC (VPX) in sock shop microservice applications for North South Load balancing
* How to insert Citrix ADC (CPX) in sock shop microservice applications for East-West Load balancing
* Expose CPXs using LoadBalancer service for simplified solution 
* Troubleshoot microservices using ADM service Graph
* Send SRE observability time-series metrics to Prometheus end point using Citrix Observability Exporter

## Pre-requisite before you start microservice deployment

1.	Bring your own nodes (BYON)

    Kubernetes is an open-source system for automating deployment, scaling, and management of containerized applications. Please install and configure Kubernetes cluster with one master node and at least two worker node deployment.
    Recommended OS: Ubuntu 16.04 desktop/server OS. 
    Visit: https://kubernetes.io/docs/setup/ for Kubernetes cluster deployment guide.
    Once Kubernetes cluster is up and running, execute the below command on master node to get the node status.
    ``` 
    kubectl get nodes
    ```
    ![nodes](images/nodes.PNG)
 
    (The following example is tested in on-prem Kubernetes cluster version 1.17.0).

2.	<u>[Optional]</u> Set up a Kubernetes dashboard for deploying containerized applications.
    
    Please visit https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/ and follow the steps mentioned to bring the Kubernetes dashboard up as shown below.

    ![k8sdashboard](https://user-images.githubusercontent.com/42699135/50677396-99179180-101f-11e9-95a4-1d9aa1b9051b.png)

3. Add K8s CIDR routes to Tier 1 ADC to reach K8s network

    Make sure that route configuration is present in Tier 1 ADC so that Ingress NetScaler should be able to reach Kubernetes pod network for seamless connectivity. Please refer to https://github.com/citrix/citrix-k8s-ingress-controller/blob/master/docs/network/staticrouting.md#manually-configure-route-on-the-citrix-adc-instance for Network configuration.
    If you have K8s cluster and Tier 1 Citrix ADC in same subnet then you do not have to do anything, below example will take care of route info.
    You need Citrix Node Controller configuration only when K8s cluster and Tier 1 ADC are in different subnet. Please refer to https://github.com/citrix/citrix-k8s-node-controller for Network configuration.


| Section | Description |
| ------- | ----------- |
| [Section A]() | Deploy Sock-shop microservice application without Citrix ADC |
| [Section B]() | Deploy Sock-shop microservice application using Citrix ADC |
| [Section C]() | Troubleshoot Sock-shop microservices using ADM service graph |
| [Section D]() | Troubleshoot Sock-shop microservices using Citrix Observability Exporter |

## Section A (Deploy Sock-shop microservice application without Citrix ADC)

Sock Shop is open source, (Apache License, Version 2.0) and is free to use for deployments. For more information refer to [Sock Shop-A Microservices Demo Application](https://microservices-demo.github.io/)
```
kubectl create namespace sock-shop
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/sock-shop/manifest/sock-shop.yaml -n sock-shop
```

    

## Section B (Deploy Sock-shop microservice application using Citrix ADC)

We will use Service mesh lite deployment to demonstrate Sock shop microservice application.
We have created automation script to generate yamls files for deploying sock shop application in Service Mesh lite topology.
You can refer to [SML generator tool](https://github.com/citrix/citrix-k8s-ingress-controller/blob/master/docs/deploy/service-mesh-lite.md#create-service-mesh-lite-yamls) for generating yamls file.

**Note:** SML yaml generator script insert CPX exposed as Ingress type service. However in this example I will modify yamls generated from tool to expose CPX using LoadBalancer type service.

```
wget  https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/sock-shop/manifest/smlite-all-in-one-with-ADM.yaml
wget  https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/sock-shop/manifest/tier1_vpx_ingress_weavesocks.yaml
wget  https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/sock-shop/manifest/vip.yaml
wget  https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/sock-shop/manifest/ipam_deploy.yaml
wget  https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/sock-shop/manifest/sockshop-secret.yaml
```

Update yamls with required inputs/EVN variables

```
kubectl create -f vip.yaml
kubectl create -f ipam_deploy.yaml
kubectl create -f smlite-all-in-one-with-ADM.yaml
kubectl create -f tier1_vpx_ingress_weavesocks.yaml
kubectl create -f sockshop-secret.yaml
```

You will have sock-shop application running on IP exposed by IPAM.

## Section C (Troubleshoot Sock-shop microservices using ADM service graph)

## Section D (Troubleshoot Sock-shop microservices using Citrix Observability Exporter)