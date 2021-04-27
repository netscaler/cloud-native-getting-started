# Load balance outside Kubernetes traffic using Citrix ADC CPX proxy exposed on NodePort

In this example, the Citrix ADC CPX (a containerized form-factor) exposed as NodePort service is used to route the Ingress traffic to a `beverage` microservice application.
A NodePort service is the most primitive way to get external traffic directly to your service. NodePort, as the name implies, opens a specific port on all the Nodes (the VMs), and any traffic that is sent to this port is forwarded to the service.

**Prerequisite**: Ensure that you have installed and set up a Kubernetes cluster (The following example is tested in on-prem Kubernetes cluster version 1.17.0).


Perform the following:

1. Deploy Citrix ADC CPX exposed as NodePort service in the Kubernetes cluster and verify the installation using the following commands.


       kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/cpx.yaml
        
       kubectl get pods -l app=cpx-ingress

   ![tier2-cpx](images/tier2-cpx.png)

2. Deploy the `colddrink` microservice application in the Kubernetes cluster and verify the installation.


        
       kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/colddrink-app.yaml
        
       kubectl get pods -l app=frontend-colddrinks
       

3. Deploy an Ingress rule for colddrink app to access http://www.colddrink.com.

    
       kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/colddrink-ingress.yaml

       kubectl get ingress

       kubectl get svc cpx-service


4. Send some traffic to the `colddrink` microservice application.

    curl -s -H "Host: www.colddrink.com" http:// MasterNode IP : NodePort | grep colddrink

    ![colddrink-app](images/colddrink-app.PNG)

	Add the DNS entries in your local machine host files for accessing microservices though Internet
    Path for host file:[Windows] ``C:\Windows\System32\drivers\etc\hosts`` [Macbook] ``/etc/hosts``
    
    Add below entries in hosts file and save the file
    ```
    <MasterNode IP> www.colddrink.com
    ```
    Lets access microservice app from local machine browser

    ```
    http://www.colddrink.com
    ```

5. (Optional) Clean up the deployments using the following commands.

       kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/cpx.yaml

       kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/colddrink-app.yaml
       
       kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/colddrink-ingress.yaml


For more information on the Citrix ingress controller, see the [Citrix ingress controller](https://github.com/citrix/citrix-k8s-ingress-controller) documentation. For more tutorials, see [beginners-guides](https://github.com/citrix/cloud-native-getting-started/tree/master/beginners-guide).
