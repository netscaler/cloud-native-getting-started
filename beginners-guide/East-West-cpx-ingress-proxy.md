# Load balance East-West microservice traffic using Citrix ADC CPX

In this example, Citrix ADC CPX (a containerized form-factor) is used to route the East-West traffic between microservices (`tea-bevarage` and `coffee-bevarage`) of a sample application (`hotdrink-app`). An Ingress rule is deployed to send requests for the microservice to a `frontend-hotdrink` microservice.

This type of deployment is called as a [Service Mesh lite topology](https://developer-docs.citrix.com/projects/citrix-k8s-ingress-controller/en/latest/deploy/service-mesh-lite/), where Citrix ADC CPX load balances the East-West microservice traffic. In this example, Citrix ADC CPX is deployed as an independent pod and not as a sidecar container proxy.

**Prerequisite**

Ensure that you have installed and set up a Kubernetes cluster (The following example is tested in on-prem Kubernetes cluster v1.22.1).

Perform the following:

1. Deploy Citrix ADC CPX to load balance the East-West traffic in the Kubernetes cluster and verify the installation using the following commands.
   
        kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/cpx.yaml

        kubectl get pods -l app=cpx-ingress

   ![tier2-cpx](images/tier2-cpx.png)

2. Deploy the `hotdrink` application (front-end hotdrink, tea, and coffee microservices) in the Kubernetes cluster and verify the installation.


        kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/hotdrink-app.yaml

        kubectl get pods -l app=tea-beverage

        kubectl get pods -l app=coffee-beverage

        kubectl get pods -l app=frontend-hotdrinks

    ![hotdrink-app](images/hotdrink-app.PNG)

3. Deploy an Ingress rule that sends traffic for 'http://hotdrink.beverages.com' to `frontend-hotdrink` microservice (based on whether the user request is for `tea-beverage` or `coffee-beverage` microservice, the`frontend-hotdrink` microservice routes the request to `tea-beverage` or `coffee-beverage`).


       kubectl create -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/hotdrink-ingress.yaml

       kubectl get ingress

       kubectl get svc cpx-service

4. Send some traffic to the `frontend-hotdrink` microservice.

        curl -s -H "Host: hotdrink.beverages.com " http://<MasterNode IP:<NodePort> | grep hotdrink


     ![hotdrink-ingress](images/hotdrink-ingress.PNG)

5. Validate the East-West traffic communication flow by performing the following steps.

    1. Edit the host file on your local machine and add DNS entries for accessing microservices though Internet and save the file.

              <K8s cluster MasterNode IP> hotdrink.beverages.com

       **Note**: Following are the path to host files depending on your operating system:
       - For Windows: ``C:\Windows\System32\drivers\etc\hosts`` 
       - For Mac:  ``/etc/hosts``

    

    2. In a local machine, access the following URL from your browser.

            http://hotdrink.beverages.com:<NodePort>

       ![hotdrink-GUI](images/hotdrink-GUI.png)

       **Note**: If you are unable to view the front-end hotdrink microservice app (due to any firewall settings), access the URL from the Kubernetes cluster host machine.

    3. Click **TEA image** and you can see that you are redirected to the tea microservice. The front-end `hotdrink` microservice has called the `tea` microservice).

    4. Check the hit count for front-end `hotdrink`, and `tea` microservices.


            kubectl get pods -l app=cpx-ingress

            kubectl exec -it cpx-ingress-9f56bcbd6-9mx2z bash

            cli_script.sh "sh cs vserver"

            cli_script.sh "sh cs vserver k8s-10.244.1.120_80_http"

          ![hotdrink-apphit-count](images/hotdrink-apphit-count.PNG)

6. (Optional) Clean up the deployments using the following commands.


            kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/cpx.yaml
            
            kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/hotdrink-app.yaml
            
            kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/beginners-guide/manifest/hotdrink-ingress.yaml

For more information on the Citrix ingress controller, see the [Citrix ingress controller](https://github.com/citrix/citrix-k8s-ingress-controller) documentation. 

For more tutorials, see [beginners-guides](https://github.com/citrix/cloud-native-getting-started/tree/master/beginners-guide).