# Load balance East-West microservice traffic using Citrix CPX proxy
In this example, the Citrix ADC CPX (a containerized form-factor) is used to route the East West traffic between tea and coffee hotdrink microservice applications.
This type of deployment is called as Service mesh lite deployment where CPX will load balance the E-W microservice traffic. Here CPX is deployed as a deployment kind and not as a sidecar proxy.

**Prerequisite**: Kubernetes cluster (Below example is tested in on-prem v1.17.0 K8s cluster)

Lets deploy Citrix ADC CPX to load balance East-West traffic in K8s cluster
```
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/quick-start-guides/manifest/cpx.yaml
kubectl get pods app=cpx-ingress
```
![tier2-cic](images/tier2-cic.png)

Lets deploy hotdrink application in K8s cluster
```
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/quick-start-guides/manifest/hotdrink-app.yaml
kubectl get pods
```

Lets deploy an Ingress rule that sends traffic to 'hotdrink.beverages.com' front-end microservice. Based on user request for tea or coffee app, front-end hotdrink app will do E-W call to tea/coffee app.
```
kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/quick-start-guides/manifest/hotdrink-ingress.yaml
kubectl get ingress
kubectl get svc cpx-service
```

Lets send the traffic to hotdrink frontend microservice
```
curl -s -H "Host: hotdrink.beverages.com " http://<MasterNode IP:<NodePort> | grep hotdrink
```

Lets verify the E-W traffic flow:

Add the DNS entries in your local machine host files for accessing microservices though Internet.
Path for host file: ``C:\Windows\System32\drivers\etc\hosts``
Add below entries in hosts file and save the file

```
<K8s cluster MasterNode IP> hotdrink.beverages.com
```
In local browser access below URL
```
http://hotdrink.beverages.com:<NodePort>
```
**Note**: If you are not able to see the front-end hotdrink microservice app (due to FW issue), access the URL from K8s cluster host machine browser.

Click on Tea image and you will render to tea page. Internally front-end hotdrink microservice has called tea microservice

Lets check the hit count for front-end hotdrink and tea microservice.

```
kubectl exec -it cpx-ingress-9f56bcbd6-9g42r bash
cli_script.sh "sh csvserver k8s-10.244.1.47_80_http
```

To know more about Citrix ingress controller,[refer here](https://github.com/citrix/citrix-k8s-ingress-controller)

Click on [quick-start-guides](https://github.com/citrix/cloud-native-getting-started/tree/master/quick-start-guides) for next tutorial.
