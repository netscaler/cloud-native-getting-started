# Deep dive on K8s features with Citrix ADC CPX
In this example, the Citrix ADC CPX (a containerized form-factor) is used to route the Ingress traffic to guestbook microservice application.
CPX proxy supported various deployment modes,

| Section | Description |
| ------- | ----------- |
| [Section A]() | Standalone Citrix ADC CPX deployment (CPX per k8s cluster) |
| [Section B]() | Citrix ADC CPX per node deployment |
| [Section C]() | Citrix ADC CPX per namespace deployment |
| [Section D]() | High availability Citrix ADC CPX deployment (Horizontal scaling) |


#### Section A (Standalone Citrix ADC CPX deployment (CPX per k8s cluster))
Lets  deploy a stand-alone Citrix ADC CPX as the ingress device.
```
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/quick-start-guides/standalone-cpx-mode.yaml
kubectl get pods -n default -l app=cpx-ingress
kubectl get svc cpx-service
```
Verify that traffic to this URL gets the apache app page:
```
curl -s -H "Host: www.ingress.com" http://<Master IP:<NodePort>
```

#### Section B (Citrix ADC CPX per node deployment)
Lets deploy Citrix ADC CPX per node
```
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/quick-start-guides/cpx-per-node-mode.yaml
kubectl get pods app=cpx-ingress
kubectl get svc cpx-service
```
Verify that traffic to this URL gets the apache app page:
```
curl -s -H "Host: www.ingress.com" http://<Master IP:<NodePort>
```

#### Section C (Citrix ADC CPX per namespace deployment)
Lets deploy Citrix ADC CPX per namespace
Lets create 3 namespaces
```
kubectl create namespace team-A team-B team-C
```
Lets deploy CPX in each namespace
```

```

Verify that traffic for each CPX deployed in different namespaces
```
curl -s -H "Host: www.ingress.com" http://<Master IP:<NodePort>
```

#### Section D (High availability Citrix ADC CPX deployment)
Lets deploy Citrix ADC CPX in HA
```
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/quick-start-guides/standalone-cpx-mode.yaml
kubectl get pods app=cpx-ingress
```

Lets scale-up the CPX pods to 2 instances
```
kubectl scale deployment cpx-ingress --replicas=2 
kubectl get pods app=cpx-ingress
```

Lets scale-down the CPX pods to 1 instance
```
kubectl scale deployment cpx-ingress --replicas=1
kubectl get pods app=cpx-ingress
```

Kubernetes has inbuilt <u>self healing</u> property where if something goes wrong to pod then k8s will spin-up new pod automatically.
```
kubectl get pods app=cpx-ingress
kubectl delete pod <cpx-ingress pod name>

kubectl get pods app=cpx-ingress
```
You will see that new CPX pod has come up immediately once running pod goes down.
 

To know more about Citrix ingress controller,[refer here](https://github.com/citrix/citrix-k8s-ingress-controller)

Click on [quick-start-guides](https://github.com/citrix/cloud-native-getting-started/tree/master/quick-start-guides) for next tutorials.
