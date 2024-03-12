
# NetScaler for OpenShift microservice application delivery (NetScaler RedHat certified Ingress BLX, CPX for OpenShift applications)

In this guide you will learn:
* Why NetScaler for RedHat OpenShift deployments?
* What are the NetScaler recommended Cloud Native deployments for OpenShift applications (Unified Ingress, Two tier Ingress topology)
* How do you load balance microservice application lifted and shifted from monolithic environment (HTTP application with SSL offload)
* How do you secure your microservice application end to end with NetScaler (SSL application)
* How do you protect your OpenShift application from security attacks with NetScaler security use cases


## Why NetScaler for RedHat OpenShift deployments?

OpenShift, a robust and secure hybrid cloud Kubernetes platform backed by Red Hat. Applications hosted within the OpenShift environment require a secure method for external access, facilitated by an enterprise-grade ingress proxy solution. NetScaler, a widely recognized and battle-tested enterprise proxy, works seamlessly with OpenShift for optimizing, securing, and directing ingress traffic to single or multiple OpenShift clusters. Learn more about [NetScaler ISV partnership with and RedHat](https://www.netscaler.com/platform/integrations/red-hat-netscaler).


## What are the NetScaler recommended Cloud Native deployments for OpenShift applications (Unified Ingress, Two tier Ingress topology)

Customer moving to microservices need Ingress proxy for load balancing OpenShift applications with existing NetScalers. NetScaler form factors MPX, SDX, BLX or VPX can be used with or without CPX for securing OpenShift deployments. NetScaler recommends few topologies for Cloud Native deployments however NetScaler offers flexibility for choosing customer preferred topology. Know more about[NetScaler deployment topologies](https://docs.netscaler.com/en-us/netscaler-k8s-ingress-controller/deployment-topologies)


## Getting started (How to guide)

In this section you will learn how to secure OpenShift applications with scalable NetScaler ingress proxy. In this section you will deploy below use cases.

* [How do you load balance microservice application with NetScaler RHEL BLX lifted and shifted from monolithic environment (Unified Ingress topology: HTTP application with SSL offload, secured client access using basic authentication)]()
* [How do you secure your microservice application end to end with NetScaler RHEL BLX and RedHat Operator certified CPX (Two tier Ingress topology: SSL application secured with BLX, CPX end to end TLS, protect blacklisted clients access using NetScaler responder policy)]()

Lets understand the demo use cases from the belowdeployment topology.

![demo topology](/images/demo-topology.png)

NetScaler BLX is RHEL certified proxy deployed infront of OpenShift clusters acting as Ingress proxy. The is a HTTP application (lifted-shifted-app) migrated to OpenShift from monolithic deployment. Since this application is insecure, BLX provides SSL offload and protect it from internet security attacks.
There is another DevOps team building the SSL based microservice application from scratch (NS-CN app) who need a proxy inside OpenShift (NetScaler CPX) for better control. However NetScaler BLX still be required infront of NetScaler BLX for unified internet access.


### Pre-requisite
* OpenShift cluster running on AWS (e.g. Mumbai ap-south-1 region).
* NetScaler RHEL BLX running on AWS (e.g. BLX on EC2 instance m5.2large hosted in Mumbai ap-south-1 region). 
* Create Kubernetes secret inside OpenShift clusters for BLX login. e.g. ``kubectl create secret generic nslogin --from-literal=username=<username> --from-literal=password=<password>``
* Ensure connectivity/routing is enabled between BLX and OpenShift nodes. You need VPX peering if BLX and OpenShift are deployed in different VPC. In this demo BLX and OpenShift clusters are running in same VPC.
* AWS CLI, OpenShift CLI in case you prefer ssh access.

### Use case 1: How do you load balance microservice application with NetScaler RHEL BLX lifted and shifted from monolithic environment (Unified Ingress topology: HTTP application with SSL offload, secured client access using basic authentication)

1.  Create a new project 'demonamespace'from OpenShift console

    Refer to [OpenShift document](https://docs.openshift.com/container-platform/4.8/applications/projects/working-with-projects.html) for creating/selecting new project - demonamespace.
    ```
    oc project demonamespace
    ```

2.  Deploy HTTP application into OpenShift cluster

    Using OpenShift console:
    You can goto OpenShift console, Navitage to Workloads -> Deployments and click on Create Deployment buttom. Copy the Deployment object from [lifted-shifted-app.yaml](https://raw.githubusercontent.com/netscaler/cloud-native-getting-started/master/openshift/Ingress-deployment/manifest/lifted-shifted-app.yaml) and click on create buttom to deploy Deployment.

    Navitage to Networking -> Services and click on Create Service buttom. Copy the Service object from [lifted-shifted-app.yaml](https://raw.githubusercontent.com/netscaler/cloud-native-getting-started/master/openshift/Ingress-deployment/manifest/lifted-shifted-app.yaml) and click on create buttom to deploy Service.

    Using SSH/ OC CLI:
    ```
    kubectl create -f https://raw.githubusercontent.com/netscaler/cloud-native-getting-started/master/openshift/Ingress-deployment/manifest/lifted-shifted-app.yaml
    ```

3.  Deploy NetScaler Ingress controller using OpenShift operator

    Follow to below steps from OpenShift console to deploy NetScaler Ingress controller.
    * Login to OpenShift console - https://console-openshift-console.apps.x.x.x/dashboards
    * Navigate to Operators -> OperatorHub, Select demonamespace project from left top corner and search for ``NetScaler Operator`` in the searchbar and click on NetScaler certified Operator
    ![operatorHub](/images/operatorHub.png)
    * Follow the steps from the screen and NetScaler Operator will be installed. Refer [NetScaler operator how to](https://github.com/netscaler/netscaler-k8s-ingress-controller/blob/master/docs/deploy/deploy-ns-operator.md#installing-netscaler-operator) for detailed steps.
    * Navigate to Operators -> Installed Operators to locate NetScaler Operator. Click on NetScaler Operator and goto NetScaler Ingress controller tab and click on Create NetScalerIngressController button. Update YAML file with BLX nsIP (BLX private IP assigned to elasticIP of NSIP), license.accept to Yes and adcCredentialSecret -> nslogin (mentioned in Pre-requisite) and click on Create buttom. Refer [How to deploy NSIC using NetScaler Operator](https://github.com/netscaler/netscaler-k8s-ingress-controller/blob/master/docs/deploy/deploy-ns-operator.md#installing-netscaler-operator) guide.
    ![nsic](/images/nsic.png)

    You can view NetScaler Ingress controller pod deployment status from OC CLI also.
    ```
    oc get pods 
    ```
    ![nsic-pod](/images/nsic-pod.png)

4.  Configure SSL certificate on BLX

    For this demo we will create a new SSL certificate using Kubernetes secrete in OpenShift cluster and refer it in Ingress object. Know more about [TLS certificate management](https://docs.netscaler.com/en-us/netscaler-k8s-ingress-controller/certificate-management/tls-certificates) for OpenShift applications. You may use existing SSL certificate from NetScaler.

    ```
    openssl genrsa -out cloudnative_key.pem 2048

    openssl req -new -key cloudnative_key.pem -out cloudnative_csr.pem -subj "/CN=*.cloupst.net/O=Citrix Systems Inc/C=IN"

    openssl x509 -req -in cloudnative_csr.pem -sha256 -days 365 -extensions v3_ca -signkey cloudnative_key.pem -CAcreateserial -out cloudnative_cert.pem

    kubectl create secret tls wildcard-vpx-cert --key cloudnative_key.pem --cert cloudnative_cert.pem
    ```

5.  Deploy Ingress obejct to route HTTP applicaton from the internet

    Using OpenShift console:
    You can goto OpenShift console, Navitage to Networking -> Ingresses and click on Create Ingress buttom. Copy the Ingress object from [lifted-shifted-app-ingress.yaml](https://raw.githubusercontent.com/netscaler/cloud-native-getting-started/master/openshift/Ingress-deployment/manifest/lifted-shifted-app-ingress.yaml) and change the ingress.citrix.com/frontend-ip with BLX VIP and click on create buttom to deploy Ingress.

    Using SSH/ OC CLI:

    ```
    wget https://raw.githubusercontent.com/netscaler/cloud-native-getting-started/master/openshift/Ingress-deployment/manifest/lifted-shifted-app-ingress.yaml
    ```

    Update "ingress.citrix.com/frontend-ip:" to BLX VIP IP (private IP associated with EIP of VIP) and deploy ingress object.

    ```
    kubectl create -f lifted-shifted-app-ingress.yaml
    ```
    ![unified-app-ingress](/images/unified-app-ingress.png)

6.  Access your HTTP application from internet

    Add the DNS entries in your local machine host files for accessing microservices though Internet.

    Path for host file:[Windows] ``C:\Windows\System32\drivers\etc\hosts`` [Macbook] ``/etc/hosts``
    Add below entries in hosts file and save the file

    ```
    <EIP associated with frontend-IP from lifted-shifted-app-ingress.yaml> lift-and-shift-httpapp.cloudpst.net
    ```
    Access your application from broswer - ``https://lift-and-shift-httpapp.cloudpst.net/``
    ![app-access](/images/app-access.png)

7.  Secured HTTP application access using NetScaler auth

    NetScaler configures authentication policies for OpenShift application using [Auth CRDs](https://github.com/netscaler/netscaler-k8s-ingress-controller/blob/master/crd/auth/README.md). We will use NetScaler BLX as local authentication provider for demonstrating basic auth use case.

    Note: Auth CRD is already installed with NSIC operator. In case Auth CRD is not installed then deploy [Auth CRD instance](https://raw.githubusercontent.com/citrix/citrix-k8s-ingress-controller/master/crd/auth/auth-crd.yaml) using kubectl create command.

    Lets deploy Auth policy
    ```
    kubectl create -f https://raw.githubusercontent.com/netscaler/cloud-native-getting-started/master/openshift/Ingress-deployment/manifest/lifted-shifted-app-basic-auth.yaml
    ```

    Login to BLX and configure below two commands to make BLX as local auth provider.
    ```
    add aaa user blxuser -password blxuser
    set tmsessionparameter -defaultAuthorizationAction Allow
    ```

    Try accessing ``https://lift-and-shift-httpapp.cloudpst.net/``, you will see signin page to provide the BLX user credentials.
    ![auth-singin-popup](/images/auth-singin-popup.png) 



### Use case 2: How do you secure your microservice application end to end with NetScaler RHEL BLX and RedHat Operator certified CPX (Two tier Ingress topology: SSL application secured with BLX, CPX end to end TLS, protect blacklisted clients access using NetScaler responder policy)

In case you have skiped the Use Case 1 and directly starting from use case 2 in that case, follow the Step 1, 3, 4 from Use Case 1 first later continue here.

1.  Deploy sample SSL application into OpenShift cluster

    Using OpenShift console:
    You can goto OpenShift console, Navitage to Workloads -> Deployments and click on Create Deployment buttom. Copy the Deployment object from [cloudnative-demoapp.yaml](https://raw.githubusercontent.com/netscaler/cloud-native-getting-started/master/openshift/Ingress-deployment/manifest/cloudnative-demoapp.yaml) and click on create buttom to deploy Deployment.

    Navitage to Networking -> Services and click on Create Service buttom. Copy the Service object from [cloudnative-demoapp.yaml](https://raw.githubusercontent.com/netscaler/cloud-native-getting-started/master/openshift/Ingress-deployment/manifest/cloudnative-demoapp.yaml) and click on create buttom to deploy Service.

    Using SSH/ OC CLI:
    ```
     kubectl create -f https://raw.githubusercontent.com/netscaler/cloud-native-getting-started/master/openshift/Ingress-deployment/manifest/cloudnative-demoapp.yaml
    ```

2.  Deploy NetScaler CPX from OpenShift OperatorHub

    Follow to below steps from OpenShift console to deploy NetScaler CPX.
    * Login to OpenShift console - https://console-openshift-console.apps.x.x.x/dashboards
    * Navigate to Operators -> OperatorHub, Select demonamespace project from left top corner and search for ``NetScaler Operator`` in the searchbar and click on NetScaler certified Operator
    ![operatorHub](/images/operatorHub.png)
    * Follow the steps from the screen and NetScaler Operator will be installed. Refer [NetScaler operator how to](https://github.com/netscaler/netscaler-k8s-ingress-controller/blob/master/docs/deploy/deploy-ns-operator.md#installing-netscaler-operator) for detailed steps.
    * Navigate to Operators -> Installed Operators to locate NetScaler Operator. Click on NetScaler Operator and goto NetScaler CPX with Ingress Controller tab and click on Create NetScalerCpxWithIngressController button. Update YAML file with license.accept to Yes and click on Create button. Refer [How to deploy NetScaler CPX using NetScaler Operator](https://github.com/netscaler/netscaler-k8s-ingress-controller/blob/master/docs/deploy/deploy-ns-operator.md#deploy-netscaler-ingress-controller-as-a-sidecar-with-netscaler-cpx-using-netscaler-operator) guide.
    ![cpx-operator](/images/cpx-operator.png)

    You can view NetScaler CPX pod deployment status from OC CLI also.
    ```
    oc get pods 
    ```

3.  Configure SSL certificate on CPX

    For this demo we will create a new SSL certificate using Kubernetes secrete in OpenShift cluster and refer it in Ingress object. Know more about [TLS certificate management](https://docs.netscaler.com/en-us/netscaler-k8s-ingress-controller/certificate-management/tls-certificates) for OpenShift applications.

    ```
    openssl genrsa -out cloudnative_key.pem 2048

    openssl req -new -key cloudnative_key.pem -out cloudnative_csr.pem -subj "/CN=netscaler-cloudnative.cloudpst.net/O=Citrix Systems Inc/C=IN"

    openssl x509 -req -in cloudnative_csr.pem -sha256 -days 365 -extensions v3_ca -signkey cloudnative_key.pem -CAcreateserial -out cloudnative_cert.pem

    kubectl create secret tls cpx-cert --key cloudnative_key.pem --cert cloudnative_cert.pem
    ```


4.  Deploy Ingress Object for CPX

    Using OpenShift console:
    You can goto OpenShift console, Navitage to Networking -> Ingresses and click on Create Ingress buttom. Copy the Ingress object from [cpx-ingress.yaml](https://raw.githubusercontent.com/netscaler/cloud-native-getting-started/master/openshift/Ingress-deployment/manifest/cpx-ingress.yaml) and click on create buttom to deploy CPX Ingress object.

    Using SSH/ OC CLI:

    ```
    kubectl create -f https://raw.githubusercontent.com/netscaler/cloud-native-getting-started/master/openshift/Ingress-deployment/manifest/cpx-ingress.yaml
    ```

4.  Deploy Ingress Object for VPX

    Using OpenShift console:
    You can goto OpenShift console, Navitage to Networking -> Ingresses and click on Create Ingress buttom. Copy the Ingress object from [vpx-ingress.yaml](https://raw.githubusercontent.com/netscaler/cloud-native-getting-started/master/openshift/Ingress-deployment/manifest/vpx-ingress.yaml) and change the ingress.citrix.com/frontend-ip with BLX VIP and click on create buttom to deploy Ingress.

    Using SSH/ OC CLI:

    ```
    wget https://raw.githubusercontent.com/netscaler/cloud-native-getting-started/master/openshift/Ingress-deployment/manifest/vpx-ingress.yaml
    ```

    Update "ingress.citrix.com/frontend-ip:" to BLX VIP IP (private IP associated with EIP of VIP) and deploy ingress object.

    ```
    kubectl create -f vpx-ingress.yaml
    ```

5.  Access your SSL application from internet

    Add the DNS entries in your local machine host files for accessing microservices though Internet.

    Path for host file:[Windows] ``C:\Windows\System32\drivers\etc\hosts`` [Macbook] ``/etc/hosts``
    Add below entries in hosts file and save the file

    ```
    <EIP associated with frontend-IP from vpx-ingress.yaml> netscaler-cloudnative.cloudpst.net
    ```
    Access your application from broswer - ``https://netscaler-cloudnative.cloudpst.net/``
    ![ns-cn-app](/images/ns-cn-app.png)

6.  Protect SSL application access from blaclisted clients.
    
    NetScaler responder policy provides ability to secure application access by allowing whitelisted clients and denying blacklisted clients. NetScaler provides L7 policy enforcement for OpenShift application using [Rewrite Responder CRDs](https://github.com/netscaler/netscaler-k8s-ingress-controller/blob/master/docs/crds/rewrite-responder.md)

    Note: Rewrite Responder policies CRD is already installed with NSIC operator. In case Auth CRD is not installed then deploy [Auth CRD instance](https://github.com/netscaler/netscaler-k8s-ingress-controller/blob/master/crd/rewrite-policy/rewrite-responder-policies-deployment.yaml) using kubectl create command. 

    Lets deploy Responder policy for blacklisting few clients. Update your machine IP in the patset values to test the use case.
    ```
    kubectl create -f https://raw.githubusercontent.com/netscaler/cloud-native-getting-started/master/openshift/Ingress-deployment/manifest/blacklist-client-IP.yaml
    ``` 


## Contact NetScaler team for POC, trails
    
    You can reach out for any questions via our email: **netscaler-appmodernization@cloud.com** or fill [this form](https://podio.com/webforms/22979270/1633242).

   For NetScaler team to better understand your Kubernetes / micro-services application deployment architecture. Please fill [this form](https://docs.google.com/forms/d/e/1FAIpQLSd9ueKkfgk-oy8TR1G5cp5HexFwU03kkwx_CvDyOFVFweuXOw/viewform) to enable us serve you better by offering latest NetScaler capabilities.

