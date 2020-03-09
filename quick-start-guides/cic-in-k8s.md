# Deploy a Citrix Ingress Controller (CIC) in K8s cluster
An Ingress Controller is a controller monitors the Kubernetes API server for updates to the Ingress resource and configures the Ingress load balancer accordingly.

Citrix ingress controller <u>(**CIC**)</u> can configure any form factor of Citrix ADC (MPX/SDX/VPX/BLX/CPX).
CIC can be deployed in two modes, 
* Independent k8s deployment kind for configuring Tier 1 Ingress proxy (MPX/SDX/BLX/VPX)
* A sidecar container for configuring CPX proxy (Tier 2 proxy)

###### Note: This tutorial is for learning different CIC deployment modes and not to be considered as end to end guide. Real world examples will use either one/both CIC modes. 
**Prerequisite**: Kubernetes cluster (Below example is tested in on-prem v1.17.0 K8s cluster)

Lets deploy CIC for configuring Tier 1 Citrix ADC
```
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/quick-start-guides/manifest/tier1-cic.yaml
```
![tier1-cic](images/tier1-cic.png)

```
kubectl get pods | grep tier1-cic
```

Lets check the CIC logs
```
kubectl logs -f tier1-cic-c669b8c4c-9fqxd
```

Lets deploy CIC as a sidecar with CPX proxy
```
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/quick-start-guides/manifest/cpx.yaml
kubectl get pods -n default -l app=cpx-ingress
```
![tier2-cic](images/tier2-cic.png)


There are 2 contains running in same pod highlighted by 2/2 under READY column. One container is for CPX proxy and another container is for CIC.
Lets check the status of both containers.
```
kubectl describe pod cpx-ingress-9f56bcbd6-qjvmd
```
![tier2-cic-pod](images/tier2-cic-pod.png)

 To know more about Citrix ingress controller,[refer here](https://github.com/citrix/citrix-k8s-ingress-controller)

Click on [quick-start-guides](https://github.com/citrix/cloud-native-getting-started/tree/master/quick-start-guides) for next tutorial.