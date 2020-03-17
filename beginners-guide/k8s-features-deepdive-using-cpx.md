# Deep dive on K8s features with Citrix ADC CPX
In this example, the Citrix ADC CPX (a containerized form-factor) is used to route the Ingress traffic to apache microservice application.
Citrix ADC CPX proxy supported various deployment modes shown in below table.

| Section | Description |
| ------- | ----------- |
| [Section A](https://github.com/citrix/cloud-native-getting-started/blob/master/beginners-guide/k8s-features-deepdive-using-cpx.md#section-a-standalone-citrix-adc-cpx-deployment-cpx-per-k8s-cluster) | Standalone Citrix ADC CPX deployment (Citrix ADC CPX per k8s cluster) |
| [Section B](https://github.com/citrix/cloud-native-getting-started/blob/master/beginners-guide/k8s-features-deepdive-using-cpx.md#section-b-citrix-adc-cpx-per-node-deployment) | Citrix ADC CPX per node deployment |
| [Section C](https://github.com/citrix/cloud-native-getting-started/blob/master/beginners-guide/k8s-features-deepdive-using-cpx.md#section-c-citrix-adc-cpx-per-namespace-deployment) | Citrix ADC CPX per namespace deployment |
| [Section D](https://github.com/citrix/cloud-native-getting-started/blob/master/beginners-guide/k8s-features-deepdive-using-cpx.md#section-d-high-availability-citrix-adc-cpx-deployment) | High availability Citrix ADC CPX deployment (Horizontal scaling) |

**Prerequisite**: Kubernetes cluster (Below examples are tested in on-prem v1.17.0 K8s cluster).


#### Section A: Standalone Citrix ADC CPX deployment (Citrix ADC CPX per k8s cluster)
1. Lets  deploy a stand-alone Citrix ADC CPX as an ingress device
```
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/standalone-cpx-mode.yaml
kubectl get pods -l app=cpx-ingress
kubectl get svc cpx-service
```
2. Lets send traffic to apache microservice
```
curl -s -H "Host: www.ingress.com" http://<Master IP:<NodePort>
```
![standalone-cpx](images/standalone-cpx.PNG)


#### Section B: Citrix ADC CPX per node deployment
1. Lets deploy Citrix ADC CPX per node
```
kubectl get nodes
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/cpx-per-node-mode.yaml
kubectl get pods -l app=cpx-ingress
kubectl get svc cpx-service
```
2. Lets send traffic to apache microservice
```
curl -s -H "Host: www.ingress.com" http://<Master IP:<NodePort>
```
(Number of CPX-ingress pods is equal to number of node in K8s cluster deploying pods)
![cpx-per-node](images/cpx-per-node.PNG)

#### Section C: Citrix ADC CPX per namespace deployment
In this example we will deploy Citrix ADC CPX in 3 namespaces.

1. Lets create three namespaces in K8s cluster
```
kubectl create namespace team-A team-B team-C
```
2. Lets deploy Citrix ADC CPX in each namespace
```
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/standalone-cpx-mode.yaml -n team-A
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/standalone-cpx-mode.yaml -n team-B
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/standalone-cpx-mode.yaml -n team-C
```
3. Lets deploy colddrink microservice apps in all namespaces
```
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/colddrink-app.yaml -n team-A
kubectl get pods -l app=frontend-colddrinks -n team-A

kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/colddrink-app.yaml -n team-B
kubectl get pods -l app=frontend-colddrinks -n team-B

kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/colddrink-app.yaml -n team-C
kubectl get pods -l app=frontend-colddrinks -n team-C
```
4. Lets deploy an Ingress rule that sends traffic to http://www.colddrink.com
```
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/colddrink-ingress.yaml -n team-A
kubectl get ingress -n team-A
kubectl get svc cpx-service -n team-A

kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/colddrink-ingress.yaml -n team-B
kubectl get ingress -n team-B
kubectl get svc cpx-service -n team-B

kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/colddrink-ingress.yaml -n team-C
kubectl get ingress -n team-C
kubectl get svc cpx-service -n team-C
```
5. Lets send the traffic for each Citrix ADC CPX deployed in different namespaces
```
kubectl get pods -l app=cpx-ingress -n team-A
kubectl get pods -l app=cpx-ingress -n team-B
kubectl get pods -l app=cpx-ingress -n team-C
```
```
kubectl get svc -n team-A
kubectl get svc -n team-B
kubectl get svc -n team-C
```
Check for Nodeports for all CPXs and create curl request accrodingly,
``` 
curl -s -H "Host: www.ingress.com" http://<Master IP:<NodePort>
```

#### Section D: High availability Citrix ADC CPX deployment
1. Lets deploy Citrix ADC CPX in HA
```
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/standalone-cpx-mode.yaml
kubectl get pods -l app=cpx-ingress
```

2. Lets scale-up the CPX pods to 2 instances
```
kubectl scale deployment cpx-ingress --replicas=2 
kubectl get pods -l app=cpx-ingress
```
Now both CPXs are capable to take distributed Ingress traffic.

3. Lets scale-down the CPX pods to 1 instance
```
kubectl scale deployment cpx-ingress --replicas=1
kubectl get pods app=cpx-ingress
```

**Mini exercise:**

Kubernetes has inbuilt <u>self healing</u> property where if something goes wrong to pod then k8s will spin-up new pod automatically.
```
kubectl get pods -l app=cpx-ingress
kubectl delete pod <cpx-ingress pod name>

kubectl get pods -l app=cpx-ingress
```
You will see that new CPX pod has come up immediately once running pod goes down.
 

To know more about Citrix ingress controller,[refer here](https://github.com/citrix/citrix-k8s-ingress-controller)

For next tutorial, visit [beginners-guides](https://github.com/citrix/cloud-native-getting-started/tree/master/beginners-guide)
