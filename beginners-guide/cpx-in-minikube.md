# Load balance Ingress traffic with Citrix ADC CPX in Minikube

In this example, the Citrix ADC CPX (a containerized form-factor) is used to route the Ingress traffic to Guestbook microservice application.
Kubernetes Ingress kind is a way to send Internet traffic to a microservice application deployed in Minikube cluster.

**Prerequisite**: Minikube cluster (Below example is tested in Minikube v0.33.1).

1. Lets deploy Citrix ADC CPX as Ingress proxy in Minikube
```
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/cpx.yaml
kubectl get pods -l app=cpx-ingress
```

2. Lets deploy Guestbook application in Minikube
```
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/guestbook-app.yaml
kubectl get pods -l 'app in (guestbook, redis)'
```

3. Lets deploy an Ingress rule that sends traffic to http://www.guestbook.com
```
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/guestbook-ingress.yaml
kubectl get ingress
kubectl get svc cpx-service
```

4. Lets send the traffic to Guestbook microservice application
```
curl -s -H "Host: www.guestbook.com" http://<MiniKube IP:<NodePort> | grep Guestbook
```

![guestbook-minikube-output](images/guestbook-minikube-output.PNG)

5. Clean Up
```
kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/cpx.yaml
kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/guestbook-app.yaml
kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/guestbook-ingress.yaml
```


To know more about Citrix ingress controller,[refer here](https://github.com/citrix/citrix-k8s-ingress-controller)

For next tutorial, visit [beginners-guides](https://github.com/citrix/cloud-native-getting-started/tree/master/beginners-guide)
